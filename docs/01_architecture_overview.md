# 아키텍처 개요

[← 메인 문서로 돌아가기](./00_overview.md)

## 시스템 아키텍처

### 전체 구조도

```
┌─────────────────────────────────────────────────────────────┐
│                    클라이언트 계층                            │
│                                                               │
│  ┌──────────────┐          ┌──────────────┐                 │
│  │  Web Client  │          │ Mobile App   │                 │
│  │  (React)     │          │ (Expo)       │                 │
│  └──────┬───────┘          └──────┬───────┘                 │
│         │                          │                         │
└─────────┼──────────────────────────┼─────────────────────────┘
          │                          │
          └──────────┬───────────────┘
                     │ HTTPS/WSS
          ┌──────────▼───────────┐
          │   API Gateway        │
          │   (Kong/Nginx)       │
          └──────────┬───────────┘
                     │
     ┌───────────────┼───────────────┐
     │               │               │
┌────▼────┐    ┌────▼────┐    ┌────▼────┐
│ Auth    │    │ Logic   │    │ Trading │
│ Service │    │ Service │    │ Service │
└────┬────┘    └────┬────┘    └────┬────┘
     │              │              │
     └──────┬───────┴──────┬───────┘
            │              │
    ┌───────▼───────┐  ┌──▼──────────┐
    │  Data Layer   │  │  Message    │
    │               │  │  Queue      │
    │  PostgreSQL   │  │  (Redis)    │
    │  Redis        │  └─────────────┘
    │  S3           │
    └───────────────┘
```

### 마이크로서비스 구성

#### 1. 인증 서비스 (Auth Service)
- **책임**: 사용자 인증 및 권한 관리
- **기술**: Node.js, Passport.js, JWT
- **데이터베이스**: PostgreSQL (사용자 정보), Redis (세션)
- **주요 기능**:
  - 소셜 로그인 (Google, GitHub, Facebook)
  - JWT 토큰 발급 및 갱신
  - 권한 등급 관리 (Free, Premium, Enterprise)
  - API 키 생성 및 관리

#### 2. 로직 서비스 (Logic Service)
- **책임**: 트레이딩 로직 관리 및 실행
- **기술**: Node.js, VM2/isolated-vm
- **데이터베이스**: PostgreSQL (로직 메타데이터), S3 (로직 코드)
- **주요 기능**:
  - 로직 CRUD 작업
  - 샌드박스 환경에서 로직 실행
  - 로직 버전 관리
  - 로직 성능 메트릭 수집

#### 3. 트레이딩 서비스 (Trading Service)
- **책임**: 신호 생성 및 거래 실행
- **기술**: Node.js, Python (백테스팅)
- **데이터베이스**: PostgreSQL (거래 내역), Redis (실시간 상태)
- **주요 기능**:
  - 백테스팅 엔진
  - 실시간 신호 생성
  - 포트폴리오 관리
  - 브로커 연동

#### 4. 데이터 서비스 (Data Service)
- **책임**: 시계열 데이터 수집 및 제공
- **기술**: Python, Rust (고성능 처리)
- **데이터베이스**: TimescaleDB, S3
- **주요 기능**:
  - 다양한 소스로부터 데이터 수집
  - 데이터 정규화 및 품질 검증
  - 실시간 데이터 스트리밍
  - 데이터 압축 및 아카이빙

#### 5. 알림 서비스 (Notification Service)
- **책임**: 사용자 알림 전송
- **기술**: Node.js
- **데이터베이스**: Redis (메시지 큐)
- **주요 기능**:
  - 이메일 알림 (SendGrid, AWS SES)
  - 푸시 알림 (Expo Push, FCM)
  - SMS 알림 (Twilio)
  - Webhook 지원

### 데이터 흐름

#### 백테스트 워크플로우

```
User Request
    │
    ▼
┌─────────────┐
│  Web/Mobile │
└──────┬──────┘
       │ POST /api/v1/backtests
       ▼
┌─────────────┐
│ API Gateway │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ Trading Service │
│                 │
│ 1. 설정 검증    │
│ 2. 데이터 로드  │
│ 3. 로직 실행    │
│ 4. 성능 계산    │
└──────┬──────────┘
       │
       ├──▶ Load Historical Data (S3/TimescaleDB)
       │
       ├──▶ Execute Logic (Logic Service)
       │
       └──▶ Save Results (PostgreSQL/S3)
       
Result
    │
    ▼
User Dashboard
```

#### 실시간 신호 생성 워크플로우

```
Market Data Source
    │
    ▼
┌─────────────────┐
│  Data Service   │
│                 │
│ - Normalize     │
│ - Validate      │
└──────┬──────────┘
       │
       ▼ Publish to Queue
┌─────────────┐
│ Redis Queue │
└──────┬──────┘
       │
       ▼ Subscribe
┌──────────────────┐
│ Trading Service  │
│                  │
│ - Execute Logic  │
│ - Generate Signal│
└──────┬───────────┘
       │
       ├──▶ Store Signal (PostgreSQL)
       │
       ├──▶ Send to Broker (if enabled)
       │
       └──▶ Notify User (Notification Service)
```

### 백엔드-프론트엔드 분리 전략

#### API 설계 원칙

1. **RESTful API**
   - 리소스 중심 설계
   - 표준 HTTP 메서드 사용
   - 명확한 버전 관리 (/api/v1, /api/v2)

2. **GraphQL (선택적)**
   - 복잡한 쿼리를 위한 GraphQL 엔드포인트
   - 실시간 업데이트를 위한 Subscription
   - 효율적인 데이터 페칭

3. **WebSocket**
   - 실시간 시세 데이터 스트리밍
   - 실시간 신호 알림
   - 양방향 통신 (채팅, 알림 등)

#### API Gateway 역할

- **라우팅**: 요청을 적절한 마이크로서비스로 전달
- **인증/인가**: JWT 토큰 검증
- **Rate Limiting**: API 호출 제한
- **로깅**: 모든 API 호출 로깅
- **캐싱**: 자주 요청되는 데이터 캐싱
- **CORS 처리**: 크로스 오리진 요청 관리

### 스케일링 전략

#### 수평적 확장

1. **무상태(Stateless) 서비스**
   - 모든 서비스는 상태를 외부 저장소에 보관
   - 세션 데이터는 Redis에 저장
   - 로드 밸런서를 통한 부하 분산

2. **데이터베이스 샤딩**
   - 사용자별 데이터 샤딩
   - 종목별 시계열 데이터 파티셔닝
   - Read Replica를 통한 읽기 성능 향상

3. **캐싱 전략**
   - Redis를 통한 L1 캐시
   - CDN을 통한 정적 자산 캐싱
   - 쿼리 결과 캐싱

#### 수직적 확장

1. **고성능 컴포넌트**
   - Rust로 작성된 데이터 처리 엔진
   - GPU 활용 백테스팅 (선택적)
   - 메모리 최적화

### 보안 아키텍처

#### 네트워크 보안

```
Internet
    │
    ▼
┌─────────────┐
│   WAF       │ ← DDoS Protection, SQL Injection 방어
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ API Gateway │ ← Rate Limiting, JWT 검증
└──────┬──────┘
       │
       ▼
┌────────────────────────┐
│  Private Network       │
│  (VPC)                 │
│                        │
│  ┌──────┐  ┌────────┐ │
│  │ Logic│  │Trading │ │
│  │Service│ │Service │ │
│  └──────┘  └────────┘ │
└────────────────────────┘
```

#### 데이터 보안

- **전송 중 암호화**: TLS 1.3
- **저장 시 암호화**: AES-256
- **민감 정보**: AWS KMS, HashiCorp Vault
- **로직 코드**: 사용자별 격리 저장, 암호화

### 고가용성 (High Availability)

#### 장애 대응

1. **서비스 이중화**
   - 모든 서비스는 최소 2개 인스턴스
   - 다중 가용 영역 (Multi-AZ) 배포

2. **데이터베이스 복제**
   - PostgreSQL 마스터-슬레이브 복제
   - Redis 센티널 모드

3. **자동 장애 복구**
   - Health Check를 통한 비정상 인스턴스 감지
   - 자동 재시작 및 교체

#### 백업 전략

- **데이터베이스**: 일일 자동 백업, 트랜잭션 로그 아카이빙
- **사용자 로직**: 버전별 S3 백업
- **설정 파일**: Git 기반 버전 관리

### 모니터링 및 관찰성

#### 메트릭 수집

```
Application Metrics
    │
    ▼
┌─────────────┐
│ Prometheus  │ ← Scrape metrics
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Grafana    │ ← Visualization
└─────────────┘
```

#### 주요 메트릭

1. **시스템 메트릭**
   - CPU, 메모리, 디스크 사용률
   - 네트워크 I/O
   - 컨테이너 상태

2. **애플리케이션 메트릭**
   - API 응답 시간
   - 에러율
   - 활성 사용자 수
   - 로직 실행 시간

3. **비즈니스 메트릭**
   - 백테스트 실행 횟수
   - 생성된 신호 수
   - 거래 성공률

#### 로깅

- **중앙 집중식 로깅**: ELK Stack (Elasticsearch, Logstash, Kibana)
- **로그 레벨**: ERROR, WARN, INFO, DEBUG
- **구조화된 로깅**: JSON 포맷
- **추적 ID**: 요청별 고유 ID로 전체 플로우 추적

### 개발 및 배포 파이프라인

```
Developer
    │
    ▼ git push
┌─────────────┐
│  GitHub     │
└──────┬──────┘
       │ Webhook
       ▼
┌─────────────────┐
│ GitHub Actions  │
│                 │
│ 1. Lint         │
│ 2. Test         │
│ 3. Build        │
│ 4. Security Scan│
└──────┬──────────┘
       │
       ▼ Deploy
┌─────────────┐
│ Kubernetes  │
│             │
│ - Staging   │
│ - Production│
└─────────────┘
```

## 기술 선택 근거

### Node.js 선택 이유
- JavaScript 생태계와의 통합성
- 비동기 I/O에 강점 (실시간 처리)
- 풍부한 npm 패키지
- 프론트엔드와 코드 공유 가능

### Python 활용 영역
- 데이터 분석 및 백테스팅
- 머신러닝 모델 (선택적)
- 데이터 수집 스크립트
- 통계 계산

### Rust 활용 영역
- 고성능 데이터 처리
- WebAssembly 컴파일 (브라우저 실행)
- 실시간 시세 파싱
- 암호화 연산

## 관련 문서

- [데이터 파이프라인](./02_data_pipeline.md) - 데이터 수집 및 처리
- [신호 생성 시스템](./03_signal_generation.md) - 로직 실행 상세
- [보안](./07_security.md) - 보안 구현 세부사항
- [배포 및 운영](./08_deployment.md) - 인프라 구성
- [기술 스택](./11_tech_stack.md) - 상세 기술 스택

[← 메인 문서로 돌아가기](./00_overview.md)
