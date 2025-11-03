---
title: "Signal Factory - 상세 기획 문서"
author: "Signal Factory Team"
date: "2025-11-03"
geometry: margin=2cm
fontsize: 11pt
---


\newpage

# Signal Factory - 프로젝트 총람

## 프로젝트 개요

**프로젝트명:** signal-factory

**목적:** 시계열 데이터를 기반으로 매매 신호를 생성하고 가상/실제 거래를 수행하는 유연하고 확장 가능한 트레이딩 프레임워크 구축

**핵심 가치:**
- 유연성: 사용자 정의 로직을 쉽게 추가/교체 가능
- 안전성: 시뮬레이션 검증 후 실거래 연결
- 보안성: 샌드박스 환경에서 격리된 로직 실행
- 재현성: 버전 관리를 통한 백테스트와 포워드 테스트

## 주요 구성 요소

### 1. 데이터 파이프라인
- **데이터 수집기**: 다양한 소스로부터 시계열 데이터 수집
- **시세 발생기**: 원시 데이터를 표준 OHLCV 포맷으로 변환
- **실시간 변환기**: 실시간 스트림을 내부 표준 포맷으로 변환

상세 문서: [02_data_pipeline.md](./02_data_pipeline.md)

### 2. 신호 생성 시스템
- **로직 관리**: 사용자 정의 JavaScript 로직 CRUD
- **보안 실행**: 샌드박스 환경에서 격리된 실행
- **포트폴리오**: 여러 로직 조합 및 가중치 관리

상세 문서: [03_signal_generation.md](./03_signal_generation.md)

### 3. 실행 엔진
- **백테스팅**: 과거 데이터로 성능 검증
- **실시간 신호**: 라이브 데이터로 신호 생성
- **자동 매매**: 브로커 연동을 통한 실거래

상세 문서: [04_execution_engine.md](./04_execution_engine.md)

### 4. 사용자 인터페이스
- **웹 UI**: React 기반 데스크톱 인터페이스
- **모바일 앱**: Expo를 활용한 크로스 플랫폼 앱

상세 문서: [05_web_ui.md](./05_web_ui.md), [06_mobile_app.md](./06_mobile_app.md)

### 5. 보안 및 운영
- **격리 환경**: 컨테이너 및 샌드박스 기반 격리
- **모니터링**: 로깅, 지표, 알림 시스템
- **배포**: 분산 및 서버리스 아키텍처

상세 문서: [07_security.md](./07_security.md), [08_deployment.md](./08_deployment.md)

## 기술 스택

### 프론트엔드
- **언어**: JavaScript/TypeScript
- **프레임워크**: React
- **모바일**: Expo (React Native)
- **UI 라이브러리**: Material-UI, Tailwind CSS
- **차트**: TradingView Lightweight Charts, D3.js

### 백엔드
- **주 언어**: JavaScript/TypeScript (Node.js)
- **보조 언어**: Python (데이터 처리), Rust (고성능 컴포넌트)
- **API**: RESTful API, GraphQL
- **런타임**: Node.js, Deno (샌드박스)

### 데이터 저장소
- **관계형 DB**: PostgreSQL (메타데이터)
- **객체 스토리지**: S3 (원시 데이터, 백테스트 결과)
- **캐시**: Redis (실시간 상태, 세션)
- **시계열 DB**: TimescaleDB 또는 InfluxDB (선택적)

### 인프라
- **컨테이너**: Docker, Kubernetes
- **CI/CD**: GitHub Actions
- **모니터링**: Prometheus, Grafana
- **로깅**: ELK Stack 또는 Loki

상세 문서: [11_tech_stack.md](./11_tech_stack.md)

## 데이터 모델

### 최적화된 시세 데이터 구조

방대한 시세 데이터를 효율적으로 처리하기 위해 키값 및 메타데이터를 최소화한 구조 설계:

```javascript
// 압축된 시계열 데이터 (배열 기반)
// [timestamp, open, high, low, close, volume]
const tickData = [
  [1704096600000, 150.0, 151.0, 149.5, 150.5, 1000000],
  [1704096660000, 150.5, 151.5, 150.0, 151.0, 1100000],
  // ...
];

// 메타데이터는 별도 분리
const metadata = {
  symbol: "AAPL",
  interval: "1m",
  timezone: "UTC"
};
```

상세 문서: [10_data_models.md](./10_data_models.md)

## 아키텍처 패턴

### 백엔드-프론트엔드 분리

```
┌─────────────────┐     ┌─────────────────┐
│   Web UI        │────▶│   API Gateway   │
│   (React)       │     │                 │
└─────────────────┘     └─────────────────┘
                               │
┌─────────────────┐            │
│   Mobile App    │────────────┤
│   (Expo)        │            │
└─────────────────┘            ▼
                        ┌─────────────────┐
                        │  Backend        │
                        │  Services       │
                        │  (Node.js)      │
                        └─────────────────┘
                               │
                    ┌──────────┼──────────┐
                    ▼          ▼          ▼
              ┌─────────┐ ┌────────┐ ┌────────┐
              │PostgreSQL│ │ Redis  │ │   S3   │
              └─────────┘ └────────┘ └────────┘
```

상세 문서: [01_architecture_overview.md](./01_architecture_overview.md)

## 사용자 워크플로우

### 기본 사용 흐름

1. **회원가입/로그인**: 소셜 계정 (Google, GitHub 등) 연동
2. **로직 작성**: 웹 에디터에서 JavaScript 트레이딩 로직 작성
3. **포트폴리오 구성**: 여러 로직 조합 및 가중치 설정
4. **백테스팅**: 과거 데이터로 성능 검증
5. **실시간 모니터링**: 라이브 데이터로 신호 확인
6. **선택적 자동 매매**: 검증 후 실거래 연결 (별도 등급)

상세 문서: [12_user_workflows.md](./12_user_workflows.md)

## 권한 등급 및 비즈니스 모델

### 무료 티어
- 백테스트 실행 (제한적)
- 5분 단위 타이머 기반 신호 생성
- 이메일 알림 3건/일

### 프리미엄 티어
- 포워드 테스트 무제한
- 실시간 신호 API 접근
- 고급 이평 데이터 공급
- 푸시/SMS 알림

### 엔터프라이즈
- 계좌 위탁 관리 (별도 계약)
- 전용 인프라
- 커스텀 브로커 연동

상세 문서: [13_business_model.md](./13_business_model.md)

## 개발 로드맵

### Phase 1: 기초 인프라 (1-2개월)
- [x] 프로젝트 구조화 및 문서화
- [ ] 데이터 파이프라인 구축
- [ ] 로직 인터페이스 및 샌드박스 프로토타입

### Phase 2: 핵심 기능 (2-3개월)
- [ ] 웹 UI 개발 (로직 에디터, 목록)
- [ ] 포트폴리오 관리 시스템
- [ ] 백테스팅 엔진

### Phase 3: 실시간 기능 (2-3개월)
- [ ] 실시간 데이터 연동
- [ ] 신호 생성 및 모니터링 대시보드
- [ ] 모바일 앱 개발

### Phase 4: 자동 매매 (2-3개월)
- [ ] 브로커 어댑터 개발
- [ ] 리스크 관리 시스템
- [ ] 자동 매매 기능

### Phase 5: 운영 및 확장 (지속)
- [ ] 보안 강화 및 감사
- [ ] 성능 최적화
- [ ] 다중 언어 지원

상세 문서: [14_roadmap.md](./14_roadmap.md)

## 보안 고려사항

### 주요 위협 및 대응

1. **악성 로직 실행**
   - 대응: 샌드박스 격리, 리소스 제한, 네트워크 차단

2. **데이터 유출**
   - 대응: 암호화, 접근 제어, 감사 로깅

3. **API 오남용**
   - 대응: Rate limiting, 인증/인가, API 키 관리

4. **자동 매매 리스크**
   - 대응: 킬 스위치, 손실 한도, 수동 승인 모드

상세 문서: [07_security.md](./07_security.md)

## API 명세

### 주요 엔드포인트

- `POST /api/v1/logics` - 로직 생성
- `GET /api/v1/logics` - 로직 목록 조회
- `PUT /api/v1/logics/:id` - 로직 수정
- `DELETE /api/v1/logics/:id` - 로직 삭제
- `POST /api/v1/portfolios` - 포트폴리오 생성
- `POST /api/v1/backtests` - 백테스트 실행
- `GET /api/v1/signals/realtime` - 실시간 신호 조회

상세 문서: [09_api_specifications.md](./09_api_specifications.md)

## 참조 문서 목록

1. [아키텍처 개요](./01_architecture_overview.md)
2. [데이터 파이프라인](./02_data_pipeline.md)
3. [신호 생성 시스템](./03_signal_generation.md)
4. [실행 엔진](./04_execution_engine.md)
5. [웹 UI](./05_web_ui.md)
6. [모바일 앱](./06_mobile_app.md)
7. [보안](./07_security.md)
8. [배포 및 운영](./08_deployment.md)
9. [API 명세](./09_api_specifications.md)
10. [데이터 모델](./10_data_models.md)
11. [기술 스택](./11_tech_stack.md)
12. [사용자 워크플로우](./12_user_workflows.md)
13. [비즈니스 모델](./13_business_model.md)
14. [개발 로드맵](./14_roadmap.md)

## 문서 생성 정보

- **생성일**: 2025-11-03
- **버전**: 1.0.0
- **작성 근거**: PROJECT_PLAN.md 전체 분석
- **목적**: 계층적 구조의 상세 기획 문서 체계 구축

\newpage

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

\newpage

# 데이터 파이프라인

[← 메인 문서로 돌아가기](./00_overview.md)

## 개요

데이터 파이프라인은 다양한 소스로부터 시계열 데이터를 수집, 정규화, 저장하고 실시간으로 제공하는 시스템입니다. 트레이딩 신호 생성의 기반이 되는 핵심 컴포넌트입니다.

## 주요 구성 요소

### 1. 데이터 수집기 (Data Collector)

#### 지원 데이터 소스

1. **거래소 API**
   - 암호화폐: Binance, Upbit, Coinbase, Kraken
   - 주식: IEX Cloud, Alpha Vantage, Yahoo Finance
   - 선물/옵션: Interactive Brokers API

2. **데이터 제공업체**
   - Bloomberg Terminal API
   - Reuters Datascope
   - Quandl/Nasdaq Data Link

3. **파일 기반**
   - CSV 파일 (로컬/S3)
   - Parquet 파일
   - JSONL 스트림

4. **메시지 큐**
   - Kafka
   - Redis Streams
   - RabbitMQ

#### 수집 스케줄링

```javascript
// 데이터 수집 설정 예시
const collectorConfig = {
  source: "binance",
  symbols: ["BTCUSDT", "ETHUSDT"],
  interval: "1m",
  schedule: "*/1 * * * *", // 1분마다
  retryPolicy: {
    maxAttempts: 3,
    backoffMs: 1000,
    exponential: true
  }
};
```

#### 재시도 메커니즘

```javascript
async function collectWithRetry(collector, config) {
  let attempts = 0;
  while (attempts < config.retryPolicy.maxAttempts) {
    try {
      const data = await collector.fetch();
      return data;
    } catch (error) {
      attempts++;
      const delay = config.retryPolicy.backoffMs * 
        (config.retryPolicy.exponential ? Math.pow(2, attempts - 1) : 1);
      await sleep(delay);
    }
  }
  throw new Error("Max retry attempts exceeded");
}
```

#### 데이터 품질 검증

```javascript
// 품질 검증 규칙
const validationRules = [
  // 타임스탬프 검증
  (tick) => tick.timestamp && !isNaN(new Date(tick.timestamp).getTime()),
  
  // OHLCV 값 검증
  (tick) => tick.open > 0 && tick.high >= tick.open && 
            tick.low <= tick.close && tick.volume >= 0,
  
  // 순서 검증
  (tick, prevTick) => !prevTick || tick.timestamp > prevTick.timestamp,
  
  // 이상치 검증 (급격한 가격 변동)
  (tick, prevTick) => !prevTick || 
    Math.abs(tick.close - prevTick.close) / prevTick.close < 0.5
];
```

### 2. 시세 발생기 (Price Generator)

#### 데이터 정규화

```javascript
// 원시 데이터를 표준 포맷으로 변환
class PriceGenerator {
  normalize(rawData, source) {
    switch(source) {
      case 'binance':
        return this.normalizeBinance(rawData);
      case 'upbit':
        return this.normalizeUpbit(rawData);
      default:
        return this.normalizeGeneric(rawData);
    }
  }
  
  normalizeBinance(data) {
    return {
      timestamp: data[0],
      open: parseFloat(data[1]),
      high: parseFloat(data[2]),
      low: parseFloat(data[3]),
      close: parseFloat(data[4]),
      volume: parseFloat(data[5])
    };
  }
  
  normalizeUpbit(data) {
    return {
      timestamp: new Date(data.candle_date_time_kst).getTime(),
      open: data.opening_price,
      high: data.high_price,
      low: data.low_price,
      close: data.trade_price,
      volume: data.candle_acc_trade_volume
    };
  }
}
```

#### OHLCV 데이터 생성

```javascript
// 틱 데이터로부터 OHLCV 캔들 생성
class CandleGenerator {
  generateCandles(ticks, interval) {
    const candles = [];
    const intervalMs = this.parseInterval(interval);
    
    let currentCandle = null;
    
    for (const tick of ticks) {
      const candleStart = Math.floor(tick.timestamp / intervalMs) * intervalMs;
      
      if (!currentCandle || currentCandle.timestamp !== candleStart) {
        if (currentCandle) {
          candles.push(currentCandle);
        }
        currentCandle = {
          timestamp: candleStart,
          open: tick.price,
          high: tick.price,
          low: tick.price,
          close: tick.price,
          volume: tick.volume
        };
      } else {
        currentCandle.high = Math.max(currentCandle.high, tick.price);
        currentCandle.low = Math.min(currentCandle.low, tick.price);
        currentCandle.close = tick.price;
        currentCandle.volume += tick.volume;
      }
    }
    
    if (currentCandle) {
      candles.push(currentCandle);
    }
    
    return candles;
  }
  
  parseInterval(interval) {
    const units = {
      's': 1000,
      'm': 60000,
      'h': 3600000,
      'd': 86400000
    };
    const match = interval.match(/^(\d+)([smhd])$/);
    return parseInt(match[1]) * units[match[2]];
  }
}
```

#### 시간 단위 지원

- **틱 데이터**: 모든 거래 (실시간)
- **초 단위**: 1s, 5s, 10s, 30s
- **분 단위**: 1m, 3m, 5m, 15m, 30m
- **시간 단위**: 1h, 2h, 4h, 6h, 12h
- **일 단위**: 1d, 3d, 1w

#### 시장별 데이터 보정

```javascript
// 거래소별 특성을 고려한 데이터 보정
class MarketDataCorrector {
  correctForMarket(data, market) {
    const corrections = {
      // 암호화폐: 24/7 거래
      crypto: (d) => d,
      
      // 주식: 장 시간 외 데이터 필터링
      stock: (d) => this.filterTradingHours(d, '09:30', '16:00'),
      
      // 선물: 갭 처리
      futures: (d) => this.handleGaps(d)
    };
    
    return corrections[market](data);
  }
  
  filterTradingHours(data, openTime, closeTime) {
    return data.filter(tick => {
      const hour = new Date(tick.timestamp).getHours();
      const minute = new Date(tick.timestamp).getMinutes();
      const time = hour * 60 + minute;
      const [openH, openM] = openTime.split(':').map(Number);
      const [closeH, closeM] = closeTime.split(':').map(Number);
      const open = openH * 60 + openM;
      const close = closeH * 60 + closeM;
      return time >= open && time <= close;
    });
  }
}
```

### 3. 실시간 시세 변환기 (Real-time Price Converter)

#### WebSocket 연결 관리

```javascript
class RealtimeConverter {
  constructor(config) {
    this.connections = new Map();
    this.reconnectPolicy = {
      maxAttempts: 10,
      delayMs: 1000,
      maxDelayMs: 30000
    };
  }
  
  async connect(source, symbols) {
    const ws = await this.createWebSocket(source, symbols);
    
    ws.on('message', (data) => {
      const normalized = this.normalize(data, source);
      this.publish(normalized);
    });
    
    ws.on('close', () => {
      this.handleDisconnect(source, symbols);
    });
    
    this.connections.set(source, ws);
  }
  
  async handleDisconnect(source, symbols) {
    let attempts = 0;
    while (attempts < this.reconnectPolicy.maxAttempts) {
      const delay = Math.min(
        this.reconnectPolicy.delayMs * Math.pow(2, attempts),
        this.reconnectPolicy.maxDelayMs
      );
      
      await sleep(delay);
      
      try {
        await this.connect(source, symbols);
        console.log(`Reconnected to ${source}`);
        return;
      } catch (error) {
        attempts++;
      }
    }
    
    throw new Error(`Failed to reconnect to ${source}`);
  }
}
```

#### 프로토콜 지원

1. **WebSocket**
   - 양방향 실시간 통신
   - 낮은 지연시간
   - 자동 재연결

2. **REST API (폴링)**
   - 간단한 구현
   - 높은 호환성
   - 제한된 실시간성

3. **Server-Sent Events (SSE)**
   - 서버에서 클라이언트로 단방향 스트림
   - HTTP 기반
   - 자동 재연결 지원

4. **gRPC 스트리밍**
   - 고성능 이진 프로토콜
   - 양방향 스트리밍
   - 타입 안전성

#### 데이터 형식 추상화

```javascript
// 다양한 소스의 데이터를 통합 포맷으로 변환
class DataFormatAdapter {
  adapt(data, sourceType) {
    const adapters = {
      binance_ws: (d) => ({
        symbol: d.s,
        timestamp: d.E,
        open: parseFloat(d.k.o),
        high: parseFloat(d.k.h),
        low: parseFloat(d.k.l),
        close: parseFloat(d.k.c),
        volume: parseFloat(d.k.v)
      }),
      
      upbit_ws: (d) => ({
        symbol: d.code,
        timestamp: d.timestamp,
        open: d.opening_price,
        high: d.high_price,
        low: d.low_price,
        close: d.trade_price,
        volume: d.acc_trade_volume_24h
      }),
      
      generic: (d) => d
    };
    
    return adapters[sourceType](data);
  }
}
```

#### 지연시간 최소화

```javascript
// 지연시간 모니터링 및 최적화
class LatencyOptimizer {
  constructor() {
    this.metrics = {
      receiveTime: 0,
      processTime: 0,
      publishTime: 0
    };
  }
  
  async process(rawData) {
    const start = Date.now();
    
    // 데이터 수신 시간 기록
    this.metrics.receiveTime = start;
    
    // 최소한의 처리만 수행
    const normalized = this.quickNormalize(rawData);
    this.metrics.processTime = Date.now() - start;
    
    // 즉시 발행
    await this.publish(normalized);
    this.metrics.publishTime = Date.now() - start;
    
    // 메트릭 로깅 (비동기)
    setImmediate(() => this.logMetrics());
  }
  
  quickNormalize(data) {
    // 필수 필드만 추출하여 빠르게 처리
    return {
      s: data.s,
      t: data.t,
      p: parseFloat(data.p),
      v: parseFloat(data.v)
    };
  }
}
```

## 데이터 저장 전략

### 핫 데이터 (Hot Data)
- **저장소**: Redis
- **보관 기간**: 최근 24시간
- **용도**: 실시간 신호 생성, 대시보드
- **특징**: 초고속 읽기/쓰기

### 웜 데이터 (Warm Data)
- **저장소**: TimescaleDB (PostgreSQL 확장)
- **보관 기간**: 최근 3개월
- **용도**: 백테스팅, 분석
- **특징**: 시계열 최적화, 효율적인 압축

### 콜드 데이터 (Cold Data)
- **저장소**: S3 (Parquet 포맷)
- **보관 기간**: 영구
- **용도**: 장기 백테스팅, 아카이빙
- **특징**: 낮은 비용, 높은 압축률

### 데이터 라이프사이클

```javascript
// 자동 데이터 아카이빙
class DataLifecycleManager {
  async archiveOldData() {
    // 1. Redis → TimescaleDB (24시간 후)
    const oldRedisData = await this.getOldRedisData('24h');
    await this.insertToTimescale(oldRedisData);
    await this.deleteFromRedis(oldRedisData);
    
    // 2. TimescaleDB → S3 (3개월 후)
    const oldTimescaleData = await this.getOldTimescaleData('3M');
    await this.uploadToS3(oldTimescaleData);
    await this.deleteFromTimescale(oldTimescaleData);
  }
  
  async uploadToS3(data) {
    // Parquet 포맷으로 압축
    const parquet = await this.convertToParquet(data);
    
    // S3 업로드 (파티션별)
    const key = `market-data/${data.symbol}/${data.year}/${data.month}/data.parquet`;
    await s3.upload({ Key: key, Body: parquet });
  }
}
```

## 최적화된 데이터 구조

### 압축된 시계열 포맷

```javascript
// 메타데이터와 데이터 분리
const marketData = {
  metadata: {
    symbol: "BTCUSDT",
    interval: "1m",
    timezone: "UTC",
    fields: ["timestamp", "open", "high", "low", "close", "volume"]
  },
  
  // 배열 기반 데이터 (키 제거로 70% 크기 감소)
  data: [
    [1704096600000, 42000.5, 42100.0, 41900.0, 42050.0, 1234.56],
    [1704096660000, 42050.0, 42200.0, 42000.0, 42150.0, 987.65],
    // ...
  ]
};
```

### 델타 인코딩

```javascript
// 연속된 값의 차이만 저장하여 압축
class DeltaEncoder {
  encode(data) {
    const encoded = [data[0]]; // 첫 값은 그대로
    
    for (let i = 1; i < data.length; i++) {
      const delta = data[i].map((val, idx) => {
        if (idx === 0) return val - data[i-1][0]; // timestamp
        return Math.round((val - data[i-1][idx]) * 100); // price (2 decimal)
      });
      encoded.push(delta);
    }
    
    return encoded;
  }
  
  decode(encoded) {
    const decoded = [encoded[0]];
    
    for (let i = 1; i < encoded.length; i++) {
      const restored = encoded[i].map((delta, idx) => {
        if (idx === 0) return decoded[i-1][0] + delta;
        return decoded[i-1][idx] + delta / 100;
      });
      decoded.push(restored);
    }
    
    return decoded;
  }
}
```

### 이진 포맷 (Protocol Buffers)

```protobuf
// market_data.proto
syntax = "proto3";

message Tick {
  int64 timestamp = 1;
  double open = 2;
  double high = 3;
  double low = 4;
  double close = 5;
  double volume = 6;
}

message MarketData {
  string symbol = 1;
  string interval = 2;
  repeated Tick ticks = 3;
}
```

## 데이터 품질 관리

### 이상치 탐지

```javascript
class AnomalyDetector {
  detectSpikes(data, threshold = 3) {
    const prices = data.map(d => d.close);
    const mean = this.mean(prices);
    const stdDev = this.standardDeviation(prices);
    
    return data.filter((d, i) => {
      const zScore = Math.abs((d.close - mean) / stdDev);
      return zScore > threshold;
    });
  }
  
  detectGaps(data, maxGapMinutes = 5) {
    const gaps = [];
    
    for (let i = 1; i < data.length; i++) {
      const gap = (data[i].timestamp - data[i-1].timestamp) / 60000;
      if (gap > maxGapMinutes) {
        gaps.push({
          start: data[i-1].timestamp,
          end: data[i].timestamp,
          durationMinutes: gap
        });
      }
    }
    
    return gaps;
  }
}
```

### 결측치 처리

```javascript
class MissingDataHandler {
  fillGaps(data, method = 'forward') {
    const filled = [...data];
    
    switch(method) {
      case 'forward':
        return this.forwardFill(filled);
      case 'backward':
        return this.backwardFill(filled);
      case 'interpolate':
        return this.linearInterpolate(filled);
      default:
        return filled;
    }
  }
  
  forwardFill(data) {
    let lastValid = data[0];
    
    return data.map(tick => {
      if (this.isValid(tick)) {
        lastValid = tick;
        return tick;
      }
      return { ...lastValid, timestamp: tick.timestamp };
    });
  }
  
  linearInterpolate(data) {
    // 선형 보간으로 빈 값 채우기
    const result = [];
    
    for (let i = 0; i < data.length; i++) {
      if (this.isValid(data[i])) {
        result.push(data[i]);
      } else {
        // 이전/이후 유효한 값 찾기
        const prev = this.findPreviousValid(data, i);
        const next = this.findNextValid(data, i);
        
        if (prev && next) {
          result.push(this.interpolate(prev, next, data[i].timestamp));
        }
      }
    }
    
    return result;
  }
}
```

## 성능 최적화

### 배치 처리

```javascript
// 대량 데이터 일괄 처리
class BatchProcessor {
  async processBatch(items, batchSize = 1000) {
    const results = [];
    
    for (let i = 0; i < items.length; i += batchSize) {
      const batch = items.slice(i, i + batchSize);
      const processed = await this.processItems(batch);
      results.push(...processed);
      
      // 메모리 압력 완화
      if (i % (batchSize * 10) === 0) {
        await this.flush();
      }
    }
    
    return results;
  }
}
```

### 병렬 처리

```javascript
// Worker Threads를 활용한 병렬 처리
const { Worker } = require('worker_threads');

class ParallelProcessor {
  async processInParallel(data, numWorkers = 4) {
    const chunkSize = Math.ceil(data.length / numWorkers);
    const chunks = [];
    
    for (let i = 0; i < numWorkers; i++) {
      chunks.push(data.slice(i * chunkSize, (i + 1) * chunkSize));
    }
    
    const workers = chunks.map(chunk => 
      this.createWorker('./data-worker.js', chunk)
    );
    
    return Promise.all(workers);
  }
  
  createWorker(script, data) {
    return new Promise((resolve, reject) => {
      const worker = new Worker(script, { workerData: data });
      worker.on('message', resolve);
      worker.on('error', reject);
    });
  }
}
```

## 관련 문서

- [아키텍처 개요](./01_architecture_overview.md) - 전체 시스템 구조
- [데이터 모델](./10_data_models.md) - 데이터 스키마 상세
- [기술 스택](./11_tech_stack.md) - 사용 기술 목록

[← 메인 문서로 돌아가기](./00_overview.md)

\newpage

# 신호 생성 시스템

[← 메인 문서로 돌아가기](./00_overview.md)

## 개요

신호 생성 시스템은 사용자 정의 트레이딩 로직을 안전하게 실행하여 매매 신호(ENTRY/EXIT)를 생성하는 핵심 컴포넌트입니다. 보안성과 유연성을 동시에 제공합니다.

## 로직 관리 (CRUD)

### 로직 데이터 모델

```javascript
// PostgreSQL 스키마
const logicSchema = {
  id: 'UUID PRIMARY KEY',
  name: 'VARCHAR(255) NOT NULL',
  description: 'TEXT',
  code: 'TEXT NOT NULL',
  version: 'INTEGER DEFAULT 1',
  author_id: 'UUID REFERENCES users(id)',
  tags: 'TEXT[]',
  category: 'VARCHAR(100)',
  is_public: 'BOOLEAN DEFAULT FALSE',
  created_at: 'TIMESTAMP DEFAULT NOW()',
  updated_at: 'TIMESTAMP DEFAULT NOW()',
  last_executed_at: 'TIMESTAMP'
};

// 로직 성능 메트릭
const logicMetricsSchema = {
  logic_id: 'UUID REFERENCES logics(id)',
  total_executions: 'BIGINT DEFAULT 0',
  avg_execution_time_ms: 'FLOAT',
  success_rate: 'FLOAT',
  last_backtest_return: 'FLOAT',
  sharpe_ratio: 'FLOAT'
};
```

### 로직 생성 API

```javascript
// POST /api/v1/logics
app.post('/api/v1/logics', async (req, res) => {
  const { name, description, code, tags, category } = req.body;
  const userId = req.user.id;
  
  // 코드 검증
  const validation = await validateLogicCode(code);
  if (!validation.isValid) {
    return res.status(400).json({ error: validation.errors });
  }
  
  // 로직 저장
  const logic = await db.logics.create({
    id: uuid(),
    name,
    description,
    code,
    author_id: userId,
    tags,
    category,
    version: 1
  });
  
  // S3에 코드 백업
  await s3.upload({
    Key: `logics/${logic.id}/v${logic.version}.js`,
    Body: code
  });
  
  res.status(201).json({ logic });
});
```

### 로직 조회 및 검색

```javascript
// GET /api/v1/logics?search=keyword&tags=tag1,tag2&sort=created_at&order=desc
app.get('/api/v1/logics', async (req, res) => {
  const { search, tags, category, sort = 'created_at', order = 'desc', page = 1, limit = 20 } = req.query;
  
  let query = db.logics.find({ author_id: req.user.id });
  
  // 검색 필터
  if (search) {
    query = query.where(or([
      { name: { contains: search } },
      { description: { contains: search } }
    ]));
  }
  
  // 태그 필터
  if (tags) {
    query = query.where({ tags: { contains: tags.split(',') } });
  }
  
  // 카테고리 필터
  if (category) {
    query = query.where({ category });
  }
  
  // 정렬
  query = query.orderBy(sort, order);
  
  // 페이지네이션
  const offset = (page - 1) * limit;
  const logics = await query.skip(offset).take(limit);
  const total = await query.count();
  
  res.json({
    logics,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      pages: Math.ceil(total / limit)
    }
  });
});
```

### 로직 수정 및 버전 관리

```javascript
// PUT /api/v1/logics/:id
app.put('/api/v1/logics/:id', async (req, res) => {
  const { id } = req.params;
  const { name, description, code, tags } = req.body;
  
  // 권한 확인
  const logic = await db.logics.findOne({ id, author_id: req.user.id });
  if (!logic) {
    return res.status(404).json({ error: 'Logic not found' });
  }
  
  // 코드 변경 시 새 버전 생성
  if (code && code !== logic.code) {
    logic.version += 1;
    
    // 이전 버전 아카이브
    await db.logicVersions.create({
      logic_id: id,
      version: logic.version - 1,
      code: logic.code,
      created_at: logic.updated_at
    });
    
    // S3에 새 버전 저장
    await s3.upload({
      Key: `logics/${id}/v${logic.version}.js`,
      Body: code
    });
  }
  
  // 업데이트
  await db.logics.update(id, {
    name: name || logic.name,
    description: description || logic.description,
    code: code || logic.code,
    tags: tags || logic.tags,
    updated_at: new Date()
  });
  
  res.json({ logic });
});
```

### 로직 삭제 (소프트 삭제)

```javascript
// DELETE /api/v1/logics/:id
app.delete('/api/v1/logics/:id', async (req, res) => {
  const { id } = req.params;
  
  // 사용 중인지 확인
  const portfolios = await db.portfolios.find({ logic_ids: { contains: id } });
  if (portfolios.length > 0) {
    return res.status(400).json({ 
      error: 'Cannot delete logic in use',
      portfolios: portfolios.map(p => p.name)
    });
  }
  
  // 소프트 삭제
  await db.logics.update(id, { 
    deleted_at: new Date(),
    is_active: false 
  });
  
  res.status(204).send();
});
```

## 웹 기반 로직 에디터

### Monaco Editor 통합

```javascript
// React 컴포넌트
import * as monaco from 'monaco-editor';
import { useEffect, useRef } from 'react';

function LogicEditor({ initialCode, onChange }) {
  const editorRef = useRef(null);
  const monacoRef = useRef(null);
  
  useEffect(() => {
    if (editorRef.current) {
      monacoRef.current = monaco.editor.create(editorRef.current, {
        value: initialCode,
        language: 'javascript',
        theme: 'vs-dark',
        automaticLayout: true,
        minimap: { enabled: true },
        fontSize: 14,
        tabSize: 2,
        
        // 자동 완성
        suggestOnTriggerCharacters: true,
        quickSuggestions: true,
        
        // 린트
        lint: {
          esversion: 2020
        }
      });
      
      // 코드 변경 이벤트
      monacoRef.current.onDidChangeModelContent(() => {
        const code = monacoRef.current.getValue();
        onChange(code);
      });
      
      // 커스텀 자동완성 제공
      monaco.languages.registerCompletionItemProvider('javascript', {
        provideCompletionItems: (model, position) => {
          return {
            suggestions: [
              {
                label: 'calculateMA',
                kind: monaco.languages.CompletionItemKind.Function,
                insertText: 'calculateMA(data, period)',
                documentation: '이동평균 계산'
              },
              {
                label: 'calculateRSI',
                kind: monaco.languages.CompletionItemKind.Function,
                insertText: 'calculateRSI(data, period)',
                documentation: 'RSI 지표 계산'
              }
            ]
          };
        }
      });
    }
    
    return () => {
      monacoRef.current?.dispose();
    };
  }, []);
  
  return <div ref={editorRef} style={{ height: '600px' }} />;
}
```

### 실시간 문법 검사

```javascript
// ESLint를 활용한 린트
import { Linter } from 'eslint';

const linter = new Linter();

function lintCode(code) {
  const messages = linter.verify(code, {
    parserOptions: {
      ecmaVersion: 2020
    },
    rules: {
      'no-undef': 'error',
      'no-unused-vars': 'warn',
      'semi': 'error',
      'no-console': 'off'
    },
    globals: {
      // 로직에서 사용 가능한 전역 변수
      calculateMA: 'readonly',
      calculateRSI: 'readonly',
      calculateBB: 'readonly'
    }
  });
  
  return messages.map(msg => ({
    line: msg.line,
    column: msg.column,
    severity: msg.severity === 2 ? 'error' : 'warning',
    message: msg.message
  }));
}
```

## 로직 실행 보안 및 격리

### VM2 샌드박스

```javascript
const { VM } = require('vm2');

class SecureLogicExecutor {
  constructor() {
    this.vm = new VM({
      timeout: 5000, // 5초 제한
      sandbox: {
        // 허용된 헬퍼 함수만 제공
        calculateMA: this.calculateMA,
        calculateRSI: this.calculateRSI,
        calculateBB: this.calculateBB,
        Math: Math, // 수학 함수 허용
        Date: Date, // 날짜 함수 허용 (제한적)
        console: {
          log: (...args) => {
            // 로그는 수집만 하고 파일/네트워크 접근 차단
            this.collectLog('info', ...args);
          }
        }
      },
      
      // 차단할 모듈
      require: {
        external: false, // 외부 모듈 로드 차단
        builtin: [], // 내장 모듈 차단
        mock: {}
      }
    });
  }
  
  async execute(code, input) {
    try {
      // 코드 검증
      this.validateCode(code);
      
      // 샌드박스에서 실행
      const result = this.vm.run(`
        (function(input) {
          ${code}
          return generateSignal(input);
        })
      `)(input);
      
      // 결과 검증
      this.validateOutput(result);
      
      return result;
    } catch (error) {
      throw new Error(`Logic execution failed: ${error.message}`);
    }
  }
  
  validateCode(code) {
    // 위험한 패턴 검사
    const dangerousPatterns = [
      /require\s*\(/,
      /import\s+/,
      /eval\s*\(/,
      /Function\s*\(/,
      /process\./,
      /child_process/,
      /fs\./,
      /__dirname/,
      /__filename/
    ];
    
    for (const pattern of dangerousPatterns) {
      if (pattern.test(code)) {
        throw new Error(`Dangerous pattern detected: ${pattern}`);
      }
    }
  }
  
  validateOutput(output) {
    if (!output || typeof output !== 'object') {
      throw new Error('Invalid output format');
    }
    
    if (!output.signals || !Array.isArray(output.signals)) {
      throw new Error('Output must contain signals array');
    }
  }
}
```

### isolated-vm (더 강력한 격리)

```javascript
const ivm = require('isolated-vm');

class IsolatedLogicExecutor {
  async execute(code, input) {
    const isolate = new ivm.Isolate({ memoryLimit: 128 }); // 128MB 제한
    const context = await isolate.createContext();
    
    // 헬퍼 함수 주입
    const jail = context.global;
    await jail.set('global', jail.derefInto());
    
    // 입력 데이터 전달
    await jail.set('input', new ivm.ExternalCopy(input).copyInto());
    
    // 코드 컴파일 및 실행
    const script = await isolate.compileScript(`
      ${code}
      const result = generateSignal(input);
      result;
    `);
    
    const result = await script.run(context, { timeout: 5000 });
    
    // 결과 복사
    return result.copy();
  }
}
```

### 리소스 제한

```javascript
class ResourceMonitor {
  constructor() {
    this.limits = {
      maxExecutionTime: 5000, // 5초
      maxMemory: 128 * 1024 * 1024, // 128MB
      maxCpuPercent: 50
    };
  }
  
  async executeWithLimits(executor, code, input) {
    const startTime = Date.now();
    const startMemory = process.memoryUsage().heapUsed;
    
    const timeoutPromise = new Promise((_, reject) => {
      setTimeout(() => reject(new Error('Execution timeout')), this.limits.maxExecutionTime);
    });
    
    const executionPromise = executor.execute(code, input);
    
    try {
      const result = await Promise.race([executionPromise, timeoutPromise]);
      
      // 메모리 사용량 체크
      const memoryUsed = process.memoryUsage().heapUsed - startMemory;
      if (memoryUsed > this.limits.maxMemory) {
        throw new Error('Memory limit exceeded');
      }
      
      // 실행 시간 기록
      const executionTime = Date.now() - startTime;
      this.recordMetrics({ executionTime, memoryUsed });
      
      return result;
    } catch (error) {
      this.recordError(error);
      throw error;
    }
  }
}
```

## 로직 입출력 스키마

### 입력 데이터 구조

```typescript
// TypeScript 인터페이스
interface LogicInput {
  tickData: {
    symbol: string;
    data: Array<[number, number, number, number, number, number]>; // [ts, o, h, l, c, v]
  }[];
  
  positions: {
    symbol: string;
    entries: Array<{
      entryPrice: number;
      quantity: number;
      entryTime: number;
    }>;
  }[];
  
  portfolio: {
    cash: number;
    equity: number;
    margin: number;
  };
  
  metadata: {
    timestamp: number;
    timezone: string;
  };
}
```

### 출력 데이터 구조

```typescript
interface LogicOutput {
  signals: Array<{
    symbol: string;
    action: 'ENTRY' | 'EXIT' | 'NONE';
    orderType: 'MARKET' | 'LIMIT' | 'STOP' | 'STOP_LIMIT';
    quantity: number;
    price?: number; // LIMIT/STOP 주문의 경우
    stopPrice?: number; // STOP_LIMIT의 경우
    reason: string;
    confidence?: number; // 0-1
    metadata?: Record<string, any>;
  }>;
}
```

### JSON Schema 검증

```javascript
const Ajv = require('ajv');
const ajv = new Ajv();

const outputSchema = {
  type: 'object',
  required: ['signals'],
  properties: {
    signals: {
      type: 'array',
      items: {
        type: 'object',
        required: ['symbol', 'action', 'orderType', 'quantity', 'reason'],
        properties: {
          symbol: { type: 'string' },
          action: { enum: ['ENTRY', 'EXIT', 'NONE'] },
          orderType: { enum: ['MARKET', 'LIMIT', 'STOP', 'STOP_LIMIT'] },
          quantity: { type: 'number', minimum: 0 },
          price: { type: 'number', minimum: 0 },
          stopPrice: { type: 'number', minimum: 0 },
          reason: { type: 'string' },
          confidence: { type: 'number', minimum: 0, maximum: 1 }
        }
      }
    }
  }
};

const validateOutput = ajv.compile(outputSchema);

function checkOutput(output) {
  const valid = validateOutput(output);
  if (!valid) {
    throw new Error(JSON.stringify(validateOutput.errors));
  }
  return output;
}
```

## 로직 포트폴리오

### 포트폴리오 데이터 모델

```javascript
const portfolioSchema = {
  id: 'UUID PRIMARY KEY',
  name: 'VARCHAR(255) NOT NULL',
  description: 'TEXT',
  user_id: 'UUID REFERENCES users(id)',
  
  // 포트폴리오 구성
  logics: 'JSONB NOT NULL', // [{logic_id, weight, allocation}]
  
  // 통합 전략
  strategy: 'VARCHAR(50)', // 'majority', 'weighted', 'priority', 'and', 'or'
  
  // 상태
  status: 'VARCHAR(20) DEFAULT active', // 'active', 'inactive', 'testing'
  
  // 메타데이터
  created_at: 'TIMESTAMP DEFAULT NOW()',
  updated_at: 'TIMESTAMP DEFAULT NOW()',
  last_run_at: 'TIMESTAMP'
};
```

### 신호 통합 알고리즘

```javascript
class SignalAggregator {
  aggregate(signals, strategy) {
    switch(strategy) {
      case 'majority':
        return this.majorityVote(signals);
      case 'weighted':
        return this.weightedAverage(signals);
      case 'priority':
        return this.priority(signals);
      case 'and':
        return this.andCombination(signals);
      case 'or':
        return this.orCombination(signals);
      default:
        return signals[0];
    }
  }
  
  majorityVote(signals) {
    const votes = {};
    
    signals.forEach(signal => {
      const key = `${signal.symbol}_${signal.action}`;
      votes[key] = (votes[key] || 0) + 1;
    });
    
    const majority = Math.floor(signals.length / 2) + 1;
    
    return Object.entries(votes)
      .filter(([_, count]) => count >= majority)
      .map(([key, _]) => {
        const [symbol, action] = key.split('_');
        return signals.find(s => s.symbol === symbol && s.action === action);
      });
  }
  
  weightedAverage(signals) {
    const bySymbol = {};
    
    signals.forEach(signal => {
      if (!bySymbol[signal.symbol]) {
        bySymbol[signal.symbol] = [];
      }
      bySymbol[signal.symbol].push(signal);
    });
    
    return Object.values(bySymbol).map(symbolSignals => {
      const weights = symbolSignals.map(s => s.weight || 1);
      const totalWeight = weights.reduce((a, b) => a + b, 0);
      
      const avgQuantity = symbolSignals.reduce((sum, s, i) => 
        sum + s.quantity * weights[i], 0
      ) / totalWeight;
      
      // 가장 높은 가중치의 액션 선택
      const maxWeightSignal = symbolSignals.reduce((max, s) => 
        (s.weight || 1) > (max.weight || 1) ? s : max
      );
      
      return {
        ...maxWeightSignal,
        quantity: avgQuantity,
        metadata: {
          ...maxWeightSignal.metadata,
          aggregatedFrom: symbolSignals.map(s => s.logic_id)
        }
      };
    });
  }
}
```

## 기술 지표 라이브러리

### 내장 헬퍼 함수

```javascript
// 로직에서 사용 가능한 헬퍼 함수
const technicalIndicators = {
  // 이동평균
  calculateMA(data, period) {
    const closes = data.map(d => d[4]); // close price
    const result = [];
    
    for (let i = period - 1; i < closes.length; i++) {
      const sum = closes.slice(i - period + 1, i + 1).reduce((a, b) => a + b, 0);
      result.push(sum / period);
    }
    
    return result;
  },
  
  // RSI (Relative Strength Index)
  calculateRSI(data, period = 14) {
    const closes = data.map(d => d[4]);
    const changes = [];
    
    for (let i = 1; i < closes.length; i++) {
      changes.push(closes[i] - closes[i-1]);
    }
    
    const rsi = [];
    for (let i = period; i < changes.length; i++) {
      const recentChanges = changes.slice(i - period, i);
      const gains = recentChanges.filter(c => c > 0).reduce((a, b) => a + b, 0) / period;
      const losses = Math.abs(recentChanges.filter(c => c < 0).reduce((a, b) => a + b, 0)) / period;
      
      const rs = gains / (losses || 1);
      rsi.push(100 - (100 / (1 + rs)));
    }
    
    return rsi;
  },
  
  // 볼린저 밴드
  calculateBB(data, period = 20, stdDev = 2) {
    const ma = this.calculateMA(data, period);
    const closes = data.map(d => d[4]);
    
    const bands = [];
    for (let i = 0; i < ma.length; i++) {
      const slice = closes.slice(i, i + period);
      const variance = slice.reduce((sum, val) => 
        sum + Math.pow(val - ma[i], 2), 0
      ) / period;
      const std = Math.sqrt(variance);
      
      bands.push({
        upper: ma[i] + stdDev * std,
        middle: ma[i],
        lower: ma[i] - stdDev * std
      });
    }
    
    return bands;
  },
  
  // MACD
  calculateMACD(data, fastPeriod = 12, slowPeriod = 26, signalPeriod = 9) {
    const closes = data.map(d => d[4]);
    const emaFast = this.calculateEMA(closes, fastPeriod);
    const emaSlow = this.calculateEMA(closes, slowPeriod);
    
    const macdLine = emaFast.map((fast, i) => fast - emaSlow[i]);
    const signalLine = this.calculateEMA(macdLine, signalPeriod);
    const histogram = macdLine.map((macd, i) => macd - signalLine[i]);
    
    return { macdLine, signalLine, histogram };
  },
  
  // EMA (Exponential Moving Average)
  calculateEMA(data, period) {
    const k = 2 / (period + 1);
    const ema = [data[0]];
    
    for (let i = 1; i < data.length; i++) {
      ema.push(data[i] * k + ema[i-1] * (1 - k));
    }
    
    return ema;
  }
};
```

## 로직 예제

### 골든 크로스 전략

```javascript
function generateSignal(input) {
  const { tickData, positions } = input;
  const signals = [];
  
  for (const { symbol, data } of tickData) {
    // 20일/50일 이동평균 계산
    const ma20 = calculateMA(data, 20);
    const ma50 = calculateMA(data, 50);
    
    if (ma20.length < 2 || ma50.length < 2) continue;
    
    const prevMA20 = ma20[ma20.length - 2];
    const currMA20 = ma20[ma20.length - 1];
    const prevMA50 = ma50[ma50.length - 2];
    const currMA50 = ma50[ma50.length - 1];
    
    // 골든 크로스: MA20이 MA50을 상향 돌파
    if (prevMA20 <= prevMA50 && currMA20 > currMA50) {
      const currentPrice = data[data.length - 1][4];
      
      signals.push({
        symbol,
        action: 'ENTRY',
        orderType: 'MARKET',
        quantity: 100,
        price: currentPrice,
        reason: '골든 크로스 발생',
        confidence: 0.8,
        metadata: {
          ma20: currMA20,
          ma50: currMA50
        }
      });
    }
    
    // 데드 크로스: MA20이 MA50을 하향 돌파
    if (prevMA20 >= prevMA50 && currMA20 < currMA50) {
      const position = positions.find(p => p.symbol === symbol);
      if (position && position.entries.length > 0) {
        signals.push({
          symbol,
          action: 'EXIT',
          orderType: 'MARKET',
          quantity: position.entries[0].quantity,
          reason: '데드 크로스 발생',
          metadata: {
            ma20: currMA20,
            ma50: currMA50
          }
        });
      }
    }
  }
  
  return { signals };
}
```

## 관련 문서

- [아키텍처 개요](./01_architecture_overview.md) - 시스템 구조
- [실행 엔진](./04_execution_engine.md) - 신호 실행
- [웹 UI](./05_web_ui.md) - 로직 에디터 UI
- [보안](./07_security.md) - 보안 세부사항

[← 메인 문서로 돌아가기](./00_overview.md)

\newpage

# 실행 엔진

[← 메인 문서로 돌아가기](./00_overview.md)

## 개요

실행 엔진은 로직 포트폴리오를 실행하여 매매 신호를 생성하고, 백테스팅과 실시간 거래를 수행하는 시스템입니다.

## 백테스팅 엔진

### 백테스트 설정

```typescript
interface BacktestConfig {
  portfolioId: string;
  startDate: string; // ISO 8601
  endDate: string;
  initialCash: number;
  symbols: string[];
  
  // 비용 모델
  commission: {
    type: 'percentage' | 'fixed';
    value: number; // 0.001 = 0.1%
  };
  
  slippage: {
    type: 'percentage' | 'fixed';
    value: number;
  };
  
  // 리샘플링
  interval: '1m' | '5m' | '1h' | '1d';
}
```

### 백테스트 실행 엔진

```javascript
class BacktestEngine {
  constructor(config) {
    this.config = config;
    this.portfolio = {
      cash: config.initialCash,
      positions: {},
      history: []
    };
  }
  
  async run() {
    // 1. 과거 데이터 로드
    const data = await this.loadHistoricalData(
      this.config.symbols,
      this.config.startDate,
      this.config.endDate,
      this.config.interval
    );
    
    // 2. 시뮬레이션 실행
    const results = await this.simulate(data);
    
    // 3. 성과 분석
    const metrics = this.calculateMetrics(results);
    
    // 4. 결과 저장
    await this.saveResults(metrics);
    
    return metrics;
  }
  
  async simulate(data) {
    const timestamps = this.getUniqueTimestamps(data);
    const trades = [];
    
    for (const timestamp of timestamps) {
      // 현재 시점의 데이터 추출
      const currentData = this.getDataAtTimestamp(data, timestamp);
      
      // 로직 실행
      const signals = await this.executeLogic(currentData);
      
      // 신호 처리
      for (const signal of signals) {
        const trade = await this.processSignal(signal, timestamp);
        if (trade) {
          trades.push(trade);
        }
      }
      
      // 포트폴리오 가치 기록
      const portfolioValue = this.calculatePortfolioValue(currentData);
      this.portfolio.history.push({
        timestamp,
        cash: this.portfolio.cash,
        equity: portfolioValue,
        total: this.portfolio.cash + portfolioValue
      });
    }
    
    return { trades, history: this.portfolio.history };
  }
  
  async processSignal(signal, timestamp) {
    if (signal.action === 'ENTRY') {
      return this.executeEntry(signal, timestamp);
    } else if (signal.action === 'EXIT') {
      return this.executeExit(signal, timestamp);
    }
    return null;
  }
  
  executeEntry(signal, timestamp) {
    const { symbol, quantity, price: requestedPrice } = signal;
    
    // 슬리피지 적용
    const slippage = this.calculateSlippage(requestedPrice);
    const executionPrice = requestedPrice + slippage;
    
    // 수수료 계산
    const commission = this.calculateCommission(executionPrice * quantity);
    
    // 필요 자금 체크
    const totalCost = executionPrice * quantity + commission;
    if (this.portfolio.cash < totalCost) {
      return { error: 'Insufficient funds' };
    }
    
    // 포지션 생성
    if (!this.portfolio.positions[symbol]) {
      this.portfolio.positions[symbol] = [];
    }
    
    this.portfolio.positions[symbol].push({
      entryPrice: executionPrice,
      quantity,
      entryTime: timestamp,
      commission
    });
    
    this.portfolio.cash -= totalCost;
    
    return {
      type: 'ENTRY',
      symbol,
      timestamp,
      price: executionPrice,
      quantity,
      commission,
      total: totalCost
    };
  }
  
  executeExit(signal, timestamp) {
    const { symbol, quantity, price: requestedPrice } = signal;
    
    const position = this.portfolio.positions[symbol]?.[0];
    if (!position) {
      return { error: 'No position to exit' };
    }
    
    // 슬리피지 적용
    const slippage = this.calculateSlippage(requestedPrice);
    const executionPrice = requestedPrice - slippage;
    
    // 수수료 계산
    const commission = this.calculateCommission(executionPrice * quantity);
    
    // 수익 계산
    const proceeds = executionPrice * quantity - commission;
    const profit = (executionPrice - position.entryPrice) * quantity - 
                   commission - position.commission;
    const returnPct = profit / (position.entryPrice * quantity);
    
    // 포지션 정리
    this.portfolio.positions[symbol].shift();
    this.portfolio.cash += proceeds;
    
    return {
      type: 'EXIT',
      symbol,
      timestamp,
      price: executionPrice,
      quantity,
      commission,
      proceeds,
      profit,
      returnPct,
      holdingPeriod: timestamp - position.entryTime
    };
  }
  
  calculateMetrics(results) {
    const { trades, history } = results;
    
    // 기본 통계
    const totalTrades = trades.filter(t => t.type === 'EXIT').length;
    const winningTrades = trades.filter(t => t.type === 'EXIT' && t.profit > 0);
    const losingTrades = trades.filter(t => t.type === 'EXIT' && t.profit < 0);
    
    // 수익률
    const initialValue = this.config.initialCash;
    const finalValue = history[history.length - 1].total;
    const totalReturn = (finalValue - initialValue) / initialValue;
    
    // 연환산 수익률
    const days = (new Date(this.config.endDate) - new Date(this.config.startDate)) / (1000 * 60 * 60 * 24);
    const annualizedReturn = Math.pow(1 + totalReturn, 365 / days) - 1;
    
    // 최대 낙폭 (MDD)
    const mdd = this.calculateMaxDrawdown(history);
    
    // 샤프 비율
    const sharpeRatio = this.calculateSharpeRatio(history);
    
    return {
      summary: {
        totalReturn,
        annualizedReturn,
        maxDrawdown: mdd,
        sharpeRatio
      },
      trades: {
        total: totalTrades,
        winning: winningTrades.length,
        losing: losingTrades.length,
        winRate: winningTrades.length / totalTrades,
        avgWin: winningTrades.reduce((sum, t) => sum + t.profit, 0) / winningTrades.length,
        avgLoss: losingTrades.reduce((sum, t) => sum + t.profit, 0) / losingTrades.length
      },
      timeline: history
    };
  }
  
  calculateMaxDrawdown(history) {
    let peak = history[0].total;
    let maxDD = 0;
    
    for (const point of history) {
      if (point.total > peak) {
        peak = point.total;
      }
      const drawdown = (peak - point.total) / peak;
      maxDD = Math.max(maxDD, drawdown);
    }
    
    return maxDD;
  }
  
  calculateSharpeRatio(history, riskFreeRate = 0.02) {
    // 일일 수익률 계산
    const returns = [];
    for (let i = 1; i < history.length; i++) {
      const ret = (history[i].total - history[i-1].total) / history[i-1].total;
      returns.push(ret);
    }
    
    // 평균 및 표준편차
    const avgReturn = returns.reduce((a, b) => a + b, 0) / returns.length;
    const variance = returns.reduce((sum, r) => sum + Math.pow(r - avgReturn, 2), 0) / returns.length;
    const stdDev = Math.sqrt(variance);
    
    // 연환산
    const annualizedAvg = avgReturn * 252; // 거래일 기준
    const annualizedStd = stdDev * Math.sqrt(252);
    
    return (annualizedAvg - riskFreeRate) / annualizedStd;
  }
}
```

## 실시간 신호 생성

### 실시간 데이터 스트림 처리

```javascript
class RealtimeSignalGenerator {
  constructor(portfolioConfig) {
    this.portfolio = portfolioConfig;
    this.subscriptions = new Map();
    this.signalQueue = [];
  }
  
  async start() {
    // 데이터 소스 구독
    for (const symbol of this.portfolio.symbols) {
      await this.subscribe(symbol);
    }
    
    // 신호 처리 루프
    this.startSignalProcessor();
  }
  
  async subscribe(symbol) {
    const stream = await dataService.subscribeRealtime(symbol);
    
    stream.on('data', async (tick) => {
      // 데이터 정규화
      const normalized = this.normalize(tick);
      
      // 버퍼에 추가
      this.addToBuffer(symbol, normalized);
      
      // 로직 트리거 조건 확인
      if (this.shouldTriggerLogic(symbol)) {
        await this.triggerLogic(symbol);
      }
    });
    
    stream.on('error', (error) => {
      console.error(`Stream error for ${symbol}:`, error);
      this.handleStreamError(symbol, error);
    });
    
    this.subscriptions.set(symbol, stream);
  }
  
  async triggerLogic(symbol) {
    // 현재 버퍼의 데이터 가져오기
    const tickData = this.getBufferData(symbol);
    
    // 현재 포지션 정보
    const positions = await this.getCurrentPositions();
    
    // 로직 실행
    const input = {
      tickData: [{ symbol, data: tickData }],
      positions,
      portfolio: await this.getPortfolioState(),
      metadata: {
        timestamp: Date.now(),
        timezone: 'UTC'
      }
    };
    
    try {
      const output = await logicService.execute(this.portfolio.logicId, input);
      
      // 신호 큐에 추가
      for (const signal of output.signals) {
        this.signalQueue.push({
          ...signal,
          timestamp: Date.now(),
          portfolioId: this.portfolio.id
        });
      }
    } catch (error) {
      console.error('Logic execution error:', error);
      await notificationService.sendAlert({
        type: 'LOGIC_ERROR',
        portfolioId: this.portfolio.id,
        error: error.message
      });
    }
  }
  
  startSignalProcessor() {
    setInterval(async () => {
      while (this.signalQueue.length > 0) {
        const signal = this.signalQueue.shift();
        await this.processSignal(signal);
      }
    }, 100); // 100ms마다 처리
  }
  
  async processSignal(signal) {
    // 신호 검증
    if (!this.validateSignal(signal)) {
      return;
    }
    
    // 리스크 체크
    const riskCheck = await this.checkRisk(signal);
    if (!riskCheck.passed) {
      await notificationService.sendAlert({
        type: 'RISK_VIOLATION',
        signal,
        reason: riskCheck.reason
      });
      return;
    }
    
    // 신호 저장
    await db.signals.create(signal);
    
    // 알림 발송
    await this.notifySignal(signal);
    
    // 자동 매매가 활성화된 경우
    if (this.portfolio.autoTradeEnabled) {
      await this.executeAutoTrade(signal);
    }
  }
}
```

## 자동 매매

### 브로커 어댑터 인터페이스

```typescript
interface BrokerAdapter {
  // 인증
  authenticate(credentials: BrokerCredentials): Promise<void>;
  
  // 계좌 정보
  getAccount(): Promise<Account>;
  getPositions(): Promise<Position[]>;
  
  // 주문
  createOrder(order: Order): Promise<OrderResult>;
  cancelOrder(orderId: string): Promise<void>;
  getOrder(orderId: string): Promise<Order>;
  
  // 실시간 데이터
  subscribeMarketData(symbol: string, callback: (data: MarketData) => void): void;
  unsubscribeMarketData(symbol: string): void;
}
```

### Binance 어댑터 구현

```javascript
class BinanceAdapter {
  constructor(apiKey, apiSecret) {
    this.client = new Binance({ apiKey, apiSecret });
  }
  
  async authenticate(credentials) {
    try {
      await this.client.accountInfo();
      return true;
    } catch (error) {
      throw new Error('Authentication failed');
    }
  }
  
  async getAccount() {
    const info = await this.client.accountInfo();
    return {
      balance: parseFloat(info.balances.find(b => b.asset === 'USDT')?.free || 0),
      equity: this.calculateEquity(info.balances)
    };
  }
  
  async getPositions() {
    const info = await this.client.accountInfo();
    return info.balances
      .filter(b => parseFloat(b.free) > 0 || parseFloat(b.locked) > 0)
      .map(b => ({
        symbol: b.asset,
        quantity: parseFloat(b.free) + parseFloat(b.locked),
        averagePrice: 0 // Binance doesn't provide this directly
      }));
  }
  
  async createOrder(order) {
    const binanceOrder = {
      symbol: order.symbol,
      side: order.side,
      type: order.type,
      quantity: order.quantity
    };
    
    if (order.type === 'LIMIT') {
      binanceOrder.price = order.price;
      binanceOrder.timeInForce = 'GTC';
    }
    
    const result = await this.client.order(binanceOrder);
    
    return {
      orderId: result.orderId.toString(),
      status: result.status,
      executedQuantity: parseFloat(result.executedQty),
      averagePrice: parseFloat(result.price)
    };
  }
  
  async cancelOrder(orderId) {
    await this.client.cancelOrder({ orderId });
  }
}
```

### 자동 매매 실행

```javascript
class AutoTrader {
  constructor(broker, config) {
    this.broker = broker;
    this.config = config;
    this.killSwitch = false;
  }
  
  async executeSignal(signal) {
    // 킬 스위치 체크
    if (this.killSwitch) {
      throw new Error('Kill switch activated');
    }
    
    // 리스크 검증
    await this.verifyRisk(signal);
    
    // 주문 생성
    const order = this.createOrderFromSignal(signal);
    
    // 브로커에 주문 전송
    const result = await this.broker.createOrder(order);
    
    // 체결 확인
    await this.confirmExecution(result);
    
    // 거래 로깅
    await this.logTrade(signal, result);
    
    // 알림 전송
    await this.notifyExecution(signal, result);
    
    return result;
  }
  
  async verifyRisk(signal) {
    // 1. 최대 손실 한도 체크
    const currentLoss = await this.getCurrentLoss();
    if (currentLoss > this.config.maxDailyLoss) {
      throw new Error('Daily loss limit exceeded');
    }
    
    // 2. 포지션 크기 제한
    const currentPosition = await this.broker.getPositions();
    const totalExposure = this.calculateExposure(currentPosition, signal);
    if (totalExposure > this.config.maxPositionSize) {
      throw new Error('Position size limit exceeded');
    }
    
    // 3. 일일 거래 횟수 제한
    const todayTrades = await this.getTodayTrades();
    if (todayTrades >= this.config.maxDailyTrades) {
      throw new Error('Daily trade limit exceeded');
    }
  }
  
  activateKillSwitch() {
    this.killSwitch = true;
    
    // 모든 포지션 즉시 청산
    this.closeAllPositions();
    
    // 알림
    notificationService.sendAlert({
      type: 'KILL_SWITCH_ACTIVATED',
      timestamp: Date.now()
    });
  }
  
  async closeAllPositions() {
    const positions = await this.broker.getPositions();
    
    for (const position of positions) {
      await this.broker.createOrder({
        symbol: position.symbol,
        side: 'SELL',
        type: 'MARKET',
        quantity: position.quantity
      });
    }
  }
}
```

## 관련 문서

- [신호 생성 시스템](./03_signal_generation.md) - 로직 실행
- [데이터 파이프라인](./02_data_pipeline.md) - 데이터 소스
- [배포 및 운영](./08_deployment.md) - 인프라

[← 메인 문서로 돌아가기](./00_overview.md)

\newpage

# 웹 UI

[← 메인 문서로 돌아가기](./00_overview.md)

## 개요

웹 UI는 React 기반의 데스크톱 인터페이스로, 로직 관리, 포트폴리오 구성, 백테스팅, 실시간 모니터링을 제공합니다.

## 기술 스택

### 프론트엔드 프레임워크
- **React 18+**: 컴포넌트 기반 UI
- **TypeScript**: 타입 안전성
- **Vite**: 빠른 개발 서버 및 빌드
- **React Router**: 클라이언트 사이드 라우팅

### UI 라이브러리
- **Material-UI (MUI)**: 컴포넌트 라이브러리
- **Tailwind CSS**: 유틸리티 기반 스타일링
- **Emotion**: CSS-in-JS

### 상태 관리
- **Zustand**: 경량 상태 관리
- **React Query**: 서버 상태 관리 및 캐싱

### 차트 라이브러리
- **TradingView Lightweight Charts**: 금융 차트
- **Recharts**: 대시보드 차트
- **D3.js**: 커스텀 시각화

### 코드 에디터
- **Monaco Editor**: VS Code 에디터
- **CodeMirror**: 경량 대안

## 주요 화면

### 1. 대시보드

```typescript
// Dashboard.tsx
import { useQuery } from '@tanstack/react-query';
import { Grid, Card, CardContent, Typography } from '@mui/material';

function Dashboard() {
  const { data: summary } = useQuery({
    queryKey: ['dashboard-summary'],
    queryFn: async () => {
      const res = await fetch('/api/v1/dashboard/summary');
      return res.json();
    }
  });
  
  return (
    <Grid container spacing={3}>
      <Grid item xs={12} md={3}>
        <StatsCard 
          title="총 자산"
          value={formatCurrency(summary?.totalAssets)}
          change={summary?.assetChange}
        />
      </Grid>
      
      <Grid item xs={12} md={3}>
        <StatsCard 
          title="오늘 수익률"
          value={formatPercent(summary?.todayReturn)}
          change={summary?.todayReturn}
        />
      </Grid>
      
      <Grid item xs={12} md={3}>
        <StatsCard 
          title="활성 포트폴리오"
          value={summary?.activePortfolios}
        />
      </Grid>
      
      <Grid item xs={12} md={3}>
        <StatsCard 
          title="실행 중인 로직"
          value={summary?.runningLogics}
        />
      </Grid>
      
      <Grid item xs={12} md={8}>
        <EquityCurveChart />
      </Grid>
      
      <Grid item xs={12} md={4}>
        <RecentSignals />
      </Grid>
    </Grid>
  );
}
```

### 2. 로직 에디터

```typescript
// LogicEditor.tsx
import Editor from '@monaco-editor/react';
import { useState, useEffect } from 'react';

function LogicEditor({ logicId }: { logicId?: string }) {
  const [code, setCode] = useState('');
  const [errors, setErrors] = useState<any[]>([]);
  
  const handleEditorChange = (value: string | undefined) => {
    setCode(value || '');
    
    // 실시간 린트
    lintCode(value || '').then(setErrors);
  };
  
  const handleSave = async () => {
    const payload = {
      name: logicName,
      description: logicDescription,
      code,
      tags: selectedTags
    };
    
    if (logicId) {
      await api.updateLogic(logicId, payload);
    } else {
      await api.createLogic(payload);
    }
  };
  
  const handleTest = async () => {
    const result = await api.testLogic({
      code,
      input: sampleData
    });
    
    setTestResult(result);
  };
  
  return (
    <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
      <EditorToolbar 
        onSave={handleSave}
        onTest={handleTest}
        errors={errors}
      />
      
      <Box sx={{ flex: 1, display: 'flex' }}>
        <Box sx={{ flex: 2 }}>
          <Editor
            height="100%"
            defaultLanguage="javascript"
            value={code}
            onChange={handleEditorChange}
            theme="vs-dark"
            options={{
              minimap: { enabled: true },
              fontSize: 14,
              automaticLayout: true
            }}
          />
        </Box>
        
        <Box sx={{ flex: 1, borderLeft: 1, borderColor: 'divider' }}>
          <Tabs value={sideTab} onChange={(_, v) => setSideTab(v)}>
            <Tab label="테스트" />
            <Tab label="문서" />
            <Tab label="예제" />
          </Tabs>
          
          {sideTab === 0 && <TestPanel result={testResult} />}
          {sideTab === 1 && <DocumentationPanel />}
          {sideTab === 2 && <ExamplesPanel />}
        </Box>
      </Box>
    </Box>
  );
}
```

### 3. 포트폴리오 관리

```typescript
// PortfolioBuilder.tsx
import { DndContext, closestCenter } from '@dnd-kit/core';
import { SortableContext } from '@dnd-kit/sortable';

function PortfolioBuilder() {
  const [selectedLogics, setSelectedLogics] = useState<Logic[]>([]);
  const [weights, setWeights] = useState<Record<string, number>>({});
  
  const handleAddLogic = (logic: Logic) => {
    setSelectedLogics([...selectedLogics, logic]);
    setWeights({ ...weights, [logic.id]: 1.0 });
  };
  
  const handleWeightChange = (logicId: string, weight: number) => {
    setWeights({ ...weights, [logicId]: weight });
  };
  
  return (
    <Grid container spacing={3}>
      <Grid item xs={12} md={4}>
        <LogicLibrary onSelect={handleAddLogic} />
      </Grid>
      
      <Grid item xs={12} md={8}>
        <Card>
          <CardHeader title="포트폴리오 구성" />
          <CardContent>
            <DndContext collisionDetection={closestCenter}>
              <SortableContext items={selectedLogics}>
                {selectedLogics.map(logic => (
                  <LogicCard
                    key={logic.id}
                    logic={logic}
                    weight={weights[logic.id]}
                    onWeightChange={(w) => handleWeightChange(logic.id, w)}
                  />
                ))}
              </SortableContext>
            </DndContext>
            
            <Divider sx={{ my: 2 }} />
            
            <StrategySelector 
              value={strategy}
              onChange={setStrategy}
            />
            
            <Button 
              variant="contained" 
              onClick={handleSavePortfolio}
              sx={{ mt: 2 }}
            >
              포트폴리오 저장
            </Button>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );
}
```

### 4. 백테스트 결과

```typescript
// BacktestResults.tsx
import { LightweightChart } from 'lightweight-charts-react-wrapper';

function BacktestResults({ backtestId }: { backtestId: string }) {
  const { data } = useQuery({
    queryKey: ['backtest', backtestId],
    queryFn: () => api.getBacktestResults(backtestId)
  });
  
  return (
    <Box>
      <Grid container spacing={3}>
        {/* 성과 요약 */}
        <Grid item xs={12}>
          <PerformanceSummary
            totalReturn={data.summary.totalReturn}
            annualizedReturn={data.summary.annualizedReturn}
            sharpeRatio={data.summary.sharpeRatio}
            maxDrawdown={data.summary.maxDrawdown}
          />
        </Grid>
        
        {/* 자산 곡선 */}
        <Grid item xs={12} md={8}>
          <Card>
            <CardHeader title="자산 곡선" />
            <CardContent>
              <EquityCurve data={data.timeline} />
            </CardContent>
          </Card>
        </Grid>
        
        {/* 월별 수익률 */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardHeader title="월별 수익률" />
            <CardContent>
              <MonthlyReturnsHeatmap data={data.monthlyReturns} />
            </CardContent>
          </Card>
        </Grid>
        
        {/* 거래 통계 */}
        <Grid item xs={12} md={6}>
          <TradeStatistics stats={data.trades} />
        </Grid>
        
        {/* 거래 내역 */}
        <Grid item xs={12} md={6}>
          <TradeHistory trades={data.trades.list} />
        </Grid>
      </Grid>
    </Box>
  );
}
```

### 5. 실시간 모니터링

```typescript
// RealtimeMonitoring.tsx
import { useWebSocket } from '@/hooks/useWebSocket';

function RealtimeMonitoring({ portfolioId }: { portfolioId: string }) {
  const { data: signals } = useWebSocket(`/ws/signals/${portfolioId}`);
  const { data: positions } = useQuery(['positions', portfolioId]);
  
  return (
    <Grid container spacing={3}>
      {/* 현재 포지션 */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardHeader title="현재 포지션" />
          <CardContent>
            <PositionsTable positions={positions} />
          </CardContent>
        </Card>
      </Grid>
      
      {/* 실시간 손익 */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardHeader title="실시간 손익" />
          <CardContent>
            <PnLChart portfolioId={portfolioId} />
          </CardContent>
        </Card>
      </Grid>
      
      {/* 최근 신호 */}
      <Grid item xs={12}>
        <Card>
          <CardHeader title="최근 신호" />
          <CardContent>
            <SignalsList signals={signals} />
          </CardContent>
        </Card>
      </Grid>
      
      {/* 실시간 차트 */}
      <Grid item xs={12}>
        <RealtimePriceChart 
          symbols={positions?.map(p => p.symbol)}
          signals={signals}
        />
      </Grid>
    </Grid>
  );
}
```

## 차트 컴포넌트

### TradingView Lightweight Charts

```typescript
// PriceChart.tsx
import { createChart, CrosshairMode } from 'lightweight-charts';
import { useRef, useEffect } from 'react';

function PriceChart({ data, signals }) {
  const chartContainerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<any>(null);
  
  useEffect(() => {
    if (!chartContainerRef.current) return;
    
    // 차트 생성
    chartRef.current = createChart(chartContainerRef.current, {
      width: chartContainerRef.current.clientWidth,
      height: 400,
      layout: {
        backgroundColor: '#ffffff',
        textColor: '#333'
      },
      grid: {
        vertLines: { color: '#e1e1e1' },
        horzLines: { color: '#e1e1e1' }
      },
      crosshair: {
        mode: CrosshairMode.Normal
      }
    });
    
    // 캔들스틱 시리즈
    const candlestickSeries = chartRef.current.addCandlestickSeries({
      upColor: '#26a69a',
      downColor: '#ef5350',
      borderVisible: false,
      wickUpColor: '#26a69a',
      wickDownColor: '#ef5350'
    });
    
    candlestickSeries.setData(data);
    
    // 신호 마커
    const markers = signals.map(signal => ({
      time: signal.timestamp / 1000,
      position: signal.action === 'ENTRY' ? 'belowBar' : 'aboveBar',
      color: signal.action === 'ENTRY' ? '#26a69a' : '#ef5350',
      shape: signal.action === 'ENTRY' ? 'arrowUp' : 'arrowDown',
      text: signal.reason
    }));
    
    candlestickSeries.setMarkers(markers);
    
    // 반응형
    const handleResize = () => {
      chartRef.current?.applyOptions({
        width: chartContainerRef.current?.clientWidth
      });
    };
    
    window.addEventListener('resize', handleResize);
    
    return () => {
      window.removeEventListener('resize', handleResize);
      chartRef.current?.remove();
    };
  }, [data, signals]);
  
  return <div ref={chartContainerRef} />;
}
```

### Canvas 기반 히트맵

```typescript
// MonthlyReturnsHeatmap.tsx
import { useRef, useEffect } from 'react';

function MonthlyReturnsHeatmap({ data }: { data: number[][] }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    
    const cellSize = 40;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    // 배경
    ctx.fillStyle = '#fff';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    // 히트맵 그리기
    data.forEach((yearData, yearIdx) => {
      yearData.forEach((value, monthIdx) => {
        const x = monthIdx * cellSize;
        const y = yearIdx * cellSize;
        
        // 색상 계산 (수익률에 따라)
        const color = getColorForValue(value);
        ctx.fillStyle = color;
        ctx.fillRect(x, y, cellSize - 2, cellSize - 2);
        
        // 텍스트
        ctx.fillStyle = value > 0 ? '#fff' : '#000';
        ctx.font = '12px sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(
          `${value.toFixed(1)}%`,
          x + cellSize / 2,
          y + cellSize / 2
        );
      });
    });
  }, [data]);
  
  return (
    <canvas
      ref={canvasRef}
      width={480}
      height={400}
    />
  );
}

function getColorForValue(value: number): string {
  if (value > 5) return '#2e7d32';
  if (value > 2) return '#66bb6a';
  if (value > 0) return '#a5d6a7';
  if (value > -2) return '#ef9a9a';
  if (value > -5) return '#e57373';
  return '#d32f2f';
}
```

## 반응형 디자인

```typescript
// useResponsive.ts
import { useMediaQuery, useTheme } from '@mui/material';

export function useResponsive() {
  const theme = useTheme();
  
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const isTablet = useMediaQuery(theme.breakpoints.between('sm', 'md'));
  const isDesktop = useMediaQuery(theme.breakpoints.up('md'));
  
  return { isMobile, isTablet, isDesktop };
}

// 사용 예
function ResponsiveLayout() {
  const { isMobile, isDesktop } = useResponsive();
  
  return (
    <Grid container spacing={isMobile ? 1 : 3}>
      {/* Mobile: 전체 너비, Desktop: 절반 */}
      <Grid item xs={12} md={6}>
        <Card />
      </Grid>
    </Grid>
  );
}
```

## WebSocket 연결

```typescript
// useWebSocket.ts
import { useEffect, useState } from 'react';

export function useWebSocket<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<Error | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  
  useEffect(() => {
    const ws = new WebSocket(`wss://api.signal-factory.com${url}`);
    
    ws.onopen = () => {
      setIsConnected(true);
    };
    
    ws.onmessage = (event) => {
      try {
        const parsed = JSON.parse(event.data);
        setData(parsed);
      } catch (err) {
        setError(err as Error);
      }
    };
    
    ws.onerror = (event) => {
      setError(new Error('WebSocket error'));
    };
    
    ws.onclose = () => {
      setIsConnected(false);
    };
    
    return () => {
      ws.close();
    };
  }, [url]);
  
  return { data, error, isConnected };
}
```

## 관련 문서

- [모바일 앱](./06_mobile_app.md) - Expo 기반 모바일
- [API 명세](./09_api_specifications.md) - REST API
- [아키텍처 개요](./01_architecture_overview.md) - 시스템 구조

[← 메인 문서로 돌아가기](./00_overview.md)

\newpage

# 모바일 앱

[← 메인 문서로 돌아가기](./00_overview.md)

## 개요

Expo와 React Native를 활용한 크로스 플랫폼 모바일 앱으로, iOS와 Android에서 동일한 사용자 경험을 제공합니다.

## 기술 스택

### 코어 프레임워크
- **Expo SDK 50+**: React Native 기반 개발 플랫폼
- **React Native 0.73+**: 네이티브 모바일 앱
- **TypeScript**: 타입 안전성

### 네비게이션
- **Expo Router**: 파일 기반 라우팅
- **React Navigation**: 네비게이션 스택

### UI 컴포넌트
- **React Native Paper**: Material Design 컴포넌트
- **React Native Elements**: UI 툴킷
- **NativeBase**: 크로스 플랫폼 컴포넌트

### 상태 관리
- **Zustand**: 경량 상태 관리
- **React Query**: 서버 상태 관리

### 푸시 알림
- **Expo Notifications**: 푸시 알림 API
- **Firebase Cloud Messaging**: 백엔드 알림 서비스

## 프로젝트 구조

```
mobile-app/
├── app/                 # Expo Router 기반 화면
│   ├── (auth)/
│   │   ├── login.tsx
│   │   └── register.tsx
│   ├── (tabs)/
│   │   ├── _layout.tsx
│   │   ├── index.tsx    # 대시보드
│   │   ├── portfolios.tsx
│   │   ├── signals.tsx
│   │   └── settings.tsx
│   └── _layout.tsx
├── components/          # 재사용 가능한 컴포넌트
│   ├── charts/
│   ├── cards/
│   └── forms/
├── hooks/              # 커스텀 훅
├── services/           # API 클라이언트
├── stores/             # 상태 저장소
├── types/              # TypeScript 타입
└── utils/              # 유틸리티 함수
```

## 주요 화면

### 1. 대시보드

```typescript
// app/(tabs)/index.tsx
import { View, ScrollView, RefreshControl } from 'react-native';
import { Card, Text } from 'react-native-paper';
import { useQuery } from '@tanstack/react-query';

export default function DashboardScreen() {
  const { data, isLoading, refetch } = useQuery({
    queryKey: ['dashboard'],
    queryFn: fetchDashboardData
  });
  
  return (
    <ScrollView
      refreshControl={
        <RefreshControl refreshing={isLoading} onRefresh={refetch} />
      }
    >
      <View style={{ padding: 16 }}>
        {/* 자산 요약 */}
        <Card style={{ marginBottom: 16 }}>
          <Card.Content>
            <Text variant="titleMedium">총 자산</Text>
            <Text variant="displaySmall">
              ${data?.totalAssets.toLocaleString()}
            </Text>
            <Text variant="bodySmall" style={{ 
              color: data?.todayChange >= 0 ? '#4caf50' : '#f44336' 
            }}>
              {data?.todayChange >= 0 ? '+' : ''}
              {data?.todayChange.toFixed(2)}%
            </Text>
          </Card.Content>
        </Card>
        
        {/* 활성 포트폴리오 */}
        <Text variant="titleMedium" style={{ marginBottom: 8 }}>
          활성 포트폴리오
        </Text>
        {data?.activePortfolios.map(portfolio => (
          <PortfolioCard key={portfolio.id} portfolio={portfolio} />
        ))}
        
        {/* 최근 신호 */}
        <Text variant="titleMedium" style={{ marginTop: 16, marginBottom: 8 }}>
          최근 신호
        </Text>
        {data?.recentSignals.map(signal => (
          <SignalCard key={signal.id} signal={signal} />
        ))}
      </View>
    </ScrollView>
  );
}
```

### 2. 포트폴리오 목록

```typescript
// app/(tabs)/portfolios.tsx
import { FlatList, TouchableOpacity } from 'react-native';
import { FAB, Card, Chip } from 'react-native-paper';
import { router } from 'expo-router';

export default function PortfoliosScreen() {
  const { data: portfolios } = useQuery({
    queryKey: ['portfolios'],
    queryFn: fetchPortfolios
  });
  
  const renderPortfolio = ({ item }: { item: Portfolio }) => (
    <TouchableOpacity
      onPress={() => router.push(`/portfolios/${item.id}`)}
    >
      <Card style={{ margin: 8 }}>
        <Card.Title
          title={item.name}
          subtitle={item.description}
          right={() => (
            <Chip mode="outlined" style={{ marginRight: 16 }}>
              {item.status}
            </Chip>
          )}
        />
        <Card.Content>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
            <View>
              <Text variant="bodySmall">수익률</Text>
              <Text variant="titleMedium" style={{
                color: item.return >= 0 ? '#4caf50' : '#f44336'
              }}>
                {item.return >= 0 ? '+' : ''}{item.return.toFixed(2)}%
              </Text>
            </View>
            <View>
              <Text variant="bodySmall">로직 수</Text>
              <Text variant="titleMedium">{item.logicCount}</Text>
            </View>
          </View>
        </Card.Content>
      </Card>
    </TouchableOpacity>
  );
  
  return (
    <View style={{ flex: 1 }}>
      <FlatList
        data={portfolios}
        renderItem={renderPortfolio}
        keyExtractor={item => item.id}
      />
      
      <FAB
        icon="plus"
        style={{ position: 'absolute', right: 16, bottom: 16 }}
        onPress={() => router.push('/portfolios/new')}
      />
    </View>
  );
}
```

### 3. 실시간 신호

```typescript
// app/(tabs)/signals.tsx
import { useEffect, useState } from 'react';
import { FlatList, View } from 'react-native';
import { List, Badge, Divider } from 'react-native-paper';
import { useWebSocket } from '@/hooks/useWebSocket';

export default function SignalsScreen() {
  const [signals, setSignals] = useState<Signal[]>([]);
  const { data: newSignal } = useWebSocket('/ws/signals');
  
  useEffect(() => {
    if (newSignal) {
      setSignals(prev => [newSignal, ...prev].slice(0, 50));
    }
  }, [newSignal]);
  
  const renderSignal = ({ item }: { item: Signal }) => (
    <>
      <List.Item
        title={item.symbol}
        description={item.reason}
        left={() => (
          <Badge
            style={{
              backgroundColor: item.action === 'ENTRY' ? '#4caf50' : '#f44336',
              marginTop: 8
            }}
          >
            {item.action}
          </Badge>
        )}
        right={() => (
          <View style={{ justifyContent: 'center', alignItems: 'flex-end' }}>
            <Text variant="bodyMedium">${item.price.toFixed(2)}</Text>
            <Text variant="bodySmall">
              {new Date(item.timestamp).toLocaleTimeString()}
            </Text>
          </View>
        )}
      />
      <Divider />
    </>
  );
  
  return (
    <FlatList
      data={signals}
      renderItem={renderSignal}
      keyExtractor={item => item.id}
    />
  );
}
```

## 차트 컴포넌트

### React Native Charts Kit

```typescript
// components/charts/LineChart.tsx
import { LineChart } from 'react-native-chart-kit';
import { Dimensions } from 'react-native';

interface Props {
  data: number[];
  labels: string[];
}

export function EquityChart({ data, labels }: Props) {
  const screenWidth = Dimensions.get('window').width;
  
  return (
    <LineChart
      data={{
        labels,
        datasets: [{ data }]
      }}
      width={screenWidth - 32}
      height={220}
      chartConfig={{
        backgroundColor: '#ffffff',
        backgroundGradientFrom: '#ffffff',
        backgroundGradientTo: '#ffffff',
        decimalPlaces: 2,
        color: (opacity = 1) => `rgba(33, 150, 243, ${opacity})`,
        style: {
          borderRadius: 16
        }
      }}
      bezier
      style={{
        marginVertical: 8,
        borderRadius: 16
      }}
    />
  );
}
```

### Victory Native (더 강력한 차트)

```typescript
// components/charts/CandlestickChart.tsx
import { VictoryCandlestick, VictoryChart, VictoryAxis } from 'victory-native';
import { Svg } from 'react-native-svg';

interface CandleData {
  x: Date;
  open: number;
  high: number;
  low: number;
  close: number;
}

export function CandlestickChart({ data }: { data: CandleData[] }) {
  return (
    <Svg width={350} height={300}>
      <VictoryChart
        width={350}
        height={300}
        domainPadding={{ x: 25 }}
      >
        <VictoryAxis
          tickFormat={(x) => new Date(x).toLocaleDateString()}
        />
        <VictoryAxis dependentAxis />
        
        <VictoryCandlestick
          data={data}
          candleColors={{ positive: '#26a69a', negative: '#ef5350' }}
        />
      </VictoryChart>
    </Svg>
  );
}
```

## 푸시 알림

### 알림 설정

```typescript
// services/notifications.ts
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true
  })
});

export async function registerForPushNotifications() {
  if (!Device.isDevice) {
    throw new Error('Must use physical device for Push Notifications');
  }
  
  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  let finalStatus = existingStatus;
  
  if (existingStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }
  
  if (finalStatus !== 'granted') {
    throw new Error('Failed to get push token for push notification!');
  }
  
  const token = (await Notifications.getExpoPushTokenAsync()).data;
  
  // 서버에 토큰 등록
  await fetch('/api/v1/notifications/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token })
  });
  
  return token;
}

export function setupNotificationListeners(
  onNotificationReceived: (notification: Notifications.Notification) => void,
  onNotificationTapped: (response: Notifications.NotificationResponse) => void
) {
  const receivedSubscription = Notifications.addNotificationReceivedListener(
    onNotificationReceived
  );
  
  const responseSubscription = Notifications.addNotificationResponseReceivedListener(
    onNotificationTapped
  );
  
  return () => {
    receivedSubscription.remove();
    responseSubscription.remove();
  };
}
```

### 신호 알림 수신

```typescript
// hooks/useSignalNotifications.ts
import { useEffect } from 'react';
import { router } from 'expo-router';

export function useSignalNotifications() {
  useEffect(() => {
    const cleanup = setupNotificationListeners(
      (notification) => {
        // 포그라운드에서 수신
        console.log('Notification received:', notification);
      },
      (response) => {
        // 알림 탭 시
        const data = response.notification.request.content.data;
        if (data.type === 'SIGNAL') {
          router.push(`/signals/${data.signalId}`);
        }
      }
    );
    
    return cleanup;
  }, []);
}
```

## 오프라인 지원

### 데이터 캐싱

```typescript
// services/storage.ts
import AsyncStorage from '@react-native-async-storage/async-storage';

export const storage = {
  async set<T>(key: string, value: T): Promise<void> {
    await AsyncStorage.setItem(key, JSON.stringify(value));
  },
  
  async get<T>(key: string): Promise<T | null> {
    const item = await AsyncStorage.getItem(key);
    return item ? JSON.parse(item) : null;
  },
  
  async remove(key: string): Promise<void> {
    await AsyncStorage.removeItem(key);
  },
  
  async clear(): Promise<void> {
    await AsyncStorage.clear();
  }
};

// React Query와 통합
import { QueryClient } from '@tanstack/react-query';
import { createAsyncStoragePersister } from '@tanstack/query-async-storage-persister';

const persister = createAsyncStoragePersister({
  storage: AsyncStorage
});

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      cacheTime: 1000 * 60 * 60 * 24, // 24시간
    },
  },
});
```

## 생체 인증

```typescript
// services/biometric.ts
import * as LocalAuthentication from 'expo-local-authentication';

export async function isBiometricAvailable(): Promise<boolean> {
  const compatible = await LocalAuthentication.hasHardwareAsync();
  if (!compatible) return false;
  
  const enrolled = await LocalAuthentication.isEnrolledAsync();
  return enrolled;
}

export async function authenticateWithBiometric(): Promise<boolean> {
  const result = await LocalAuthentication.authenticateAsync({
    promptMessage: 'Signal Factory 인증',
    fallbackLabel: '비밀번호 사용'
  });
  
  return result.success;
}

// 사용 예
async function handleLogin() {
  const canUseBiometric = await isBiometricAvailable();
  
  if (canUseBiometric) {
    const authenticated = await authenticateWithBiometric();
    if (authenticated) {
      // 로그인 진행
    }
  } else {
    // 일반 로그인
  }
}
```

## 딥링크

```typescript
// app.json
{
  "expo": {
    "scheme": "signalfactory",
    "ios": {
      "associatedDomains": ["applinks:signal-factory.com"]
    },
    "android": {
      "intentFilters": [
        {
          "action": "VIEW",
          "data": [
            {
              "scheme": "https",
              "host": "signal-factory.com"
            }
          ],
          "category": ["BROWSABLE", "DEFAULT"]
        }
      ]
    }
  }
}

// 딥링크 처리
import { Linking } from 'react-native';

Linking.addEventListener('url', ({ url }) => {
  // signalfactory://portfolio/123
  // https://signal-factory.com/portfolio/123
  
  const route = url.replace(/.*?:\/\//g, '');
  router.push(route);
});
```

## 성능 최적화

### 메모이제이션

```typescript
import { memo, useMemo, useCallback } from 'react';

const PortfolioCard = memo(({ portfolio }: { portfolio: Portfolio }) => {
  const return포맷 = useMemo(() => {
    return formatPercent(portfolio.return);
  }, [portfolio.return]);
  
  const handlePress = useCallback(() => {
    router.push(`/portfolios/${portfolio.id}`);
  }, [portfolio.id]);
  
  return (
    <TouchableOpacity onPress={handlePress}>
      {/* Card content */}
    </TouchableOpacity>
  );
});
```

### FlatList 최적화

```typescript
<FlatList
  data={items}
  renderItem={renderItem}
  keyExtractor={item => item.id}
  
  // 성능 최적화
  removeClippedSubviews={true}
  maxToRenderPerBatch={10}
  updateCellsBatchingPeriod={50}
  initialNumToRender={10}
  windowSize={5}
  
  // 메모리 최적화
  getItemLayout={(data, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  })}
/>
```

## 테스팅

### Jest 단위 테스트

```typescript
// __tests__/components/PortfolioCard.test.tsx
import { render, fireEvent } from '@testing-library/react-native';
import { PortfolioCard } from '@/components/PortfolioCard';

describe('PortfolioCard', () => {
  const mockPortfolio = {
    id: '1',
    name: 'Test Portfolio',
    return: 5.5
  };
  
  it('renders portfolio name', () => {
    const { getByText } = render(<PortfolioCard portfolio={mockPortfolio} />);
    expect(getByText('Test Portfolio')).toBeTruthy();
  });
  
  it('displays return with correct color', () => {
    const { getByText } = render(<PortfolioCard portfolio={mockPortfolio} />);
    const returnText = getByText('+5.50%');
    expect(returnText.props.style.color).toBe('#4caf50');
  });
});
```

## 관련 문서

- [웹 UI](./05_web_ui.md) - 웹 인터페이스
- [API 명세](./09_api_specifications.md) - REST API
- [배포 및 운영](./08_deployment.md) - 앱 배포

[← 메인 문서로 돌아가기](./00_overview.md)

\newpage

# 보안

[← 메인 문서로 돌아가기](./00_overview.md)

## 보안 위협 모델

### 주요 위협

1. **악성 로직 실행**
   - 시스템 리소스 고갈
   - 무한 루프, 메모리 폭탄
   - 네트워크/파일시스템 접근 시도

2. **데이터 유출**
   - 사용자 로직 코드 유출
   - API 키 및 크리덴셜 노출
   - 거래 전략 탈취

3. **API 오남용**
   - Rate limiting 우회
   - DDoS 공격
   - 무단 접근

4. **자동 매매 리스크**
   - 버그로 인한 예상치 못한 거래
   - 시장 조작 시도
   - 자금 손실

## 샌드박스 격리

### VM2 기반 격리 (Node.js)

```javascript
const { VM } = require('vm2');

class SecureVM {
  constructor() {
    this.vm = new VM({
      timeout: 5000,
      sandbox: {
        // 허용된 함수만 제공
        calculateMA: this.calculateMA,
        Math: Math,
        Date: Date
      },
      compiler: 'javascript',
      eval: false,
      wasm: false
    });
  }
  
  run(code, input) {
    // 위험한 패턴 사전 검사
    this.validateCode(code);
    
    return this.vm.run(`
      (function(input) {
        ${code}
        return generateSignal(input);
      })
    `)(input);
  }
  
  validateCode(code) {
    const blacklist = [
      /require\(/,
      /import /,
      /eval\(/,
      /Function\(/,
      /process\./,
      /child_process/,
      /__dirname/,
      /__filename/,
      /global\./
    ];
    
    for (const pattern of blacklist) {
      if (pattern.test(code)) {
        throw new Error(`Forbidden pattern: ${pattern}`);
      }
    }
  }
}
```

### Deno 격리 (더 안전한 대안)

```typescript
// deno-worker.ts
import { serve } from "https://deno.land/std/http/server.ts";

async function executeLogic(code: string, input: any) {
  // Deno는 기본적으로 권한이 차단됨
  const func = new Function('input', `
    ${code}
    return generateSignal(input);
  `);
  
  return func(input);
}

serve(async (req) => {
  const { code, input } = await req.json();
  
  try {
    const result = await executeLogic(code, input);
    return new Response(JSON.stringify(result));
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400
    });
  }
});
```

### 컨테이너 격리 (Docker)

```dockerfile
# Dockerfile.logic-runner
FROM node:18-alpine

# 비특권 사용자 생성
RUN addgroup -S logicrunner && adduser -S logicrunner -G logicrunner

WORKDIR /app

# 필요한 패키지만 설치
COPY package.json package-lock.json ./
RUN npm ci --only=production

COPY src ./src

# 읽기 전용 파일시스템
RUN chmod -R 555 /app

USER logicrunner

# 네트워크 격리
# docker run --network=none

CMD ["node", "src/logic-runner.js"]
```

### gVisor 격리 (더 강력한 격리)

```yaml
# docker-compose.yml
version: '3.8'
services:
  logic-runner:
    image: logic-runner:latest
    runtime: runsc
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp
    networks:
      - isolated
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 128M
```

## 인증 및 인가

### JWT 기반 인증

```javascript
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

class AuthService {
  async login(email, password) {
    const user = await db.users.findByEmail(email);
    if (!user) {
      throw new Error('Invalid credentials');
    }
    
    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      throw new Error('Invalid credentials');
    }
    
    const token = jwt.sign(
      { 
        userId: user.id, 
        role: user.role,
        tier: user.tier
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    return { token, user };
  }
  
  verifyToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      throw new Error('Invalid token');
    }
  }
}

// Express 미들웨어
function authenticate(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  try {
    req.user = authService.verifyToken(token);
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// 권한 체크
function authorize(requiredTier) {
  return (req, res, next) => {
    const tierLevels = { free: 0, premium: 1, enterprise: 2 };
    
    if (tierLevels[req.user.tier] < tierLevels[requiredTier]) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    
    next();
  };
}

// 사용 예
app.get('/api/v1/signals/realtime', 
  authenticate, 
  authorize('premium'),
  (req, res) => {
    // ...
  }
);
```

### API 키 관리

```javascript
class APIKeyService {
  async generateKey(userId, description) {
    const key = crypto.randomBytes(32).toString('hex');
    const hash = await bcrypt.hash(key, 10);
    
    await db.apiKeys.create({
      userId,
      keyHash: hash,
      description,
      createdAt: new Date()
    });
    
    // 키는 한 번만 반환
    return key;
  }
  
  async validateKey(key) {
    const allKeys = await db.apiKeys.findActive();
    
    for (const record of allKeys) {
      const valid = await bcrypt.compare(key, record.keyHash);
      if (valid) {
        await this.recordUsage(record.id);
        return record;
      }
    }
    
    throw new Error('Invalid API key');
  }
  
  async revokeKey(keyId, userId) {
    await db.apiKeys.update(keyId, {
      revokedAt: new Date(),
      revokedBy: userId
    });
  }
}
```

## Rate Limiting

### Redis 기반 Rate Limiter

```javascript
const Redis = require('ioredis');
const redis = new Redis();

class RateLimiter {
  async checkLimit(userId, endpoint, maxRequests, windowMs) {
    const key = `ratelimit:${userId}:${endpoint}`;
    const now = Date.now();
    const windowStart = now - windowMs;
    
    // 오래된 요청 제거
    await redis.zremrangebyscore(key, 0, windowStart);
    
    // 현재 윈도우 내 요청 수
    const count = await redis.zcard(key);
    
    if (count >= maxRequests) {
      const oldestRequest = await redis.zrange(key, 0, 0, 'WITHSCORES');
      const resetTime = parseInt(oldestRequest[1]) + windowMs;
      
      throw new Error(`Rate limit exceeded. Retry after ${new Date(resetTime).toISOString()}`);
    }
    
    // 새 요청 기록
    await redis.zadd(key, now, `${now}-${crypto.randomBytes(8).toString('hex')}`);
    await redis.expire(key, Math.ceil(windowMs / 1000));
    
    return {
      remaining: maxRequests - count - 1,
      reset: now + windowMs
    };
  }
}

// Express 미들웨어
function rateLimit(maxRequests, windowMs) {
  return async (req, res, next) => {
    try {
      const result = await rateLimiter.checkLimit(
        req.user.id,
        req.path,
        maxRequests,
        windowMs
      );
      
      res.set('X-RateLimit-Remaining', result.remaining);
      res.set('X-RateLimit-Reset', result.reset);
      
      next();
    } catch (error) {
      res.status(429).json({ error: error.message });
    }
  };
}

// 사용 예
app.get('/api/v1/backtests',
  authenticate,
  rateLimit(10, 60000), // 10 requests per minute
  async (req, res) => {
    // ...
  }
);
```

## 암호화

### 데이터 암호화

```javascript
const crypto = require('crypto');

class Encryption {
  constructor(key) {
    this.algorithm = 'aes-256-gcm';
    this.key = Buffer.from(key, 'hex');
  }
  
  encrypt(text) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(this.algorithm, this.key, iv);
    
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    const authTag = cipher.getAuthTag();
    
    return {
      encrypted,
      iv: iv.toString('hex'),
      authTag: authTag.toString('hex')
    };
  }
  
  decrypt(encrypted, iv, authTag) {
    const decipher = crypto.createDecipheriv(
      this.algorithm,
      this.key,
      Buffer.from(iv, 'hex')
    );
    
    decipher.setAuthTag(Buffer.from(authTag, 'hex'));
    
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  }
}

// 로직 코드 암호화 저장
async function saveLogicSecurely(userId, code) {
  const encryption = new Encryption(process.env.ENCRYPTION_KEY);
  const { encrypted, iv, authTag } = encryption.encrypt(code);
  
  await db.logics.create({
    userId,
    encryptedCode: encrypted,
    iv,
    authTag
  });
}
```

### TLS/SSL 설정

```nginx
# nginx.conf
server {
    listen 443 ssl http2;
    server_name api.signal-factory.com;
    
    ssl_certificate /etc/ssl/certs/signal-factory.crt;
    ssl_certificate_key /etc/ssl/private/signal-factory.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    location / {
        proxy_pass http://backend:3000;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 감사 로깅

```javascript
class AuditLogger {
  async log(event) {
    await db.auditLogs.create({
      userId: event.userId,
      action: event.action,
      resource: event.resource,
      resourceId: event.resourceId,
      ipAddress: event.ipAddress,
      userAgent: event.userAgent,
      timestamp: new Date(),
      metadata: event.metadata
    });
  }
}

// 미들웨어
function auditLog(action) {
  return async (req, res, next) => {
    res.on('finish', async () => {
      await auditLogger.log({
        userId: req.user?.id,
        action,
        resource: req.baseUrl + req.path,
        resourceId: req.params.id,
        ipAddress: req.ip,
        userAgent: req.get('user-agent'),
        metadata: {
          method: req.method,
          statusCode: res.statusCode
        }
      });
    });
    
    next();
  };
}

// 사용 예
app.delete('/api/v1/logics/:id',
  authenticate,
  auditLog('DELETE_LOGIC'),
  async (req, res) => {
    // ...
  }
);
```

## 관련 문서

- [아키텍처 개요](./01_architecture_overview.md)
- [신호 생성 시스템](./03_signal_generation.md)
- [배포 및 운영](./08_deployment.md)

[← 메인 문서로 돌아가기](./00_overview.md)

\newpage

# 배포 및 운영

[← 메인 문서로 돌아가기](./00_overview.md)

## 인프라 아키텍처

### 클라우드 제공자
- **AWS**: 주요 인프라 (EC2, ECS, RDS, S3, CloudFront)
- **Vercel**: 프론트엔드 배포 (선택적)
- **Railway/Render**: 작은 서비스 배포 (선택적)

### Kubernetes 클러스터

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: trading-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: trading-service
  template:
    metadata:
      labels:
        app: trading-service
    spec:
      containers:
      - name: trading-service
        image: signal-factory/trading-service:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: trading-service
spec:
  selector:
    app: trading-service
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: LoadBalancer
```

## CI/CD 파이프라인

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Lint
      run: npm run lint
    
    - name: Test
      run: npm test
    
    - name: Build
      run: npm run build
  
  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Snyk security scan
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
    
    - name: Run CodeQL analysis
      uses: github/codeql-action/analyze@v2
  
  build:
    needs: [test, security]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ap-northeast-2
    
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1
    
    - name: Build and push Docker image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $ECR_REGISTRY/signal-factory:$IMAGE_TAG .
        docker push $ECR_REGISTRY/signal-factory:$IMAGE_TAG
        docker tag $ECR_REGISTRY/signal-factory:$IMAGE_TAG $ECR_REGISTRY/signal-factory:latest
        docker push $ECR_REGISTRY/signal-factory:latest
  
  deploy:
    needs: build
    runs-on: ubuntu-latest
    
    steps:
    - name: Deploy to ECS
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: task-definition.json
        service: signal-factory-service
        cluster: production-cluster
        wait-for-service-stability: true
```

## 모니터링

### Prometheus + Grafana

```yaml
# prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'trading-service'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - production
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        action: keep
        regex: trading-service
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod
```

### 애플리케이션 메트릭

```javascript
// metrics.js
const prometheus = require('prom-client');

const register = new prometheus.Registry();

// 기본 메트릭
prometheus.collectDefaultMetrics({ register });

// 커스텀 메트릭
const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const logicExecutions = new prometheus.Counter({
  name: 'logic_executions_total',
  help: 'Total number of logic executions',
  labelNames: ['logic_id', 'status']
});

const backtestDuration = new prometheus.Histogram({
  name: 'backtest_duration_seconds',
  help: 'Duration of backtest execution',
  buckets: [1, 5, 10, 30, 60, 120]
});

register.registerMetric(httpRequestDuration);
register.registerMetric(logicExecutions);
register.registerMetric(backtestDuration);

// Express 미들웨어
function metricsMiddleware(req, res, next) {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .observe(duration);
  });
  
  next();
}

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

## 로깅

### Winston Logger

```javascript
const winston = require('winston');
const { ElasticsearchTransport } = require('winston-elasticsearch');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'signal-factory',
    environment: process.env.NODE_ENV
  },
  transports: [
    // Console
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }),
    
    // File
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error'
    }),
    new winston.transports.File({
      filename: 'logs/combined.log'
    }),
    
    // Elasticsearch (Production)
    ...(process.env.NODE_ENV === 'production' ? [
      new ElasticsearchTransport({
        level: 'info',
        clientOpts: {
          node: process.env.ELASTICSEARCH_URL
        },
        index: 'signal-factory-logs'
      })
    ] : [])
  ]
});

module.exports = logger;
```

## 데이터베이스 관리

### 마이그레이션

```javascript
// migrations/001_create_users.js
exports.up = async (knex) => {
  await knex.schema.createTable('users', (table) => {
    table.uuid('id').primary();
    table.string('email').notNullable().unique();
    table.string('name').notNullable();
    table.string('password_hash').notNullable();
    table.enum('tier', ['free', 'premium', 'enterprise']).defaultTo('free');
    table.timestamps(true, true);
  });
};

exports.down = async (knex) => {
  await knex.schema.dropTable('users');
};

// Run migrations
// npx knex migrate:latest
```

### 백업

```bash
#!/bin/bash
# scripts/backup-db.sh

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_${TIMESTAMP}.sql.gz"

# PostgreSQL 백업
pg_dump -h $DB_HOST -U $DB_USER $DB_NAME | gzip > /tmp/$BACKUP_FILE

# S3 업로드
aws s3 cp /tmp/$BACKUP_FILE s3://signal-factory-backups/database/

# 로컬 파일 삭제
rm /tmp/$BACKUP_FILE

# 30일 이상 된 백업 삭제
aws s3 ls s3://signal-factory-backups/database/ | \
  awk '{print $4}' | \
  while read file; do
    age=$(( ($(date +%s) - $(date -d "$(echo $file | cut -d'_' -f2 | cut -d'.' -f1)" +%s)) / 86400 ))
    if [ $age -gt 30 ]; then
      aws s3 rm s3://signal-factory-backups/database/$file
    fi
  done
```

## 스케일링

### 수평적 확장 (Horizontal Scaling)

```yaml
# k8s/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: trading-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: trading-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 15
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

## 환경 변수 관리

### AWS Secrets Manager

```javascript
const AWS = require('aws-sdk');
const secretsManager = new AWS.SecretsManager();

async function getSecrets() {
  const secretName = `signal-factory/${process.env.NODE_ENV}`;
  
  const data = await secretsManager.getSecretValue({
    SecretId: secretName
  }).promise();
  
  const secrets = JSON.parse(data.SecretString);
  
  // 환경 변수로 설정
  Object.entries(secrets).forEach(([key, value]) => {
    process.env[key] = value;
  });
}

// 시작 시 로드
getSecrets().then(() => {
  require('./app');
});
```

## 재해 복구

### 다중 리전 배포

```yaml
# terraform/multi-region.tf
provider "aws" {
  alias  = "primary"
  region = "ap-northeast-2"
}

provider "aws" {
  alias  = "secondary"
  region = "us-west-2"
}

# Primary RDS
resource "aws_db_instance" "primary" {
  provider = aws.primary
  
  identifier = "signal-factory-primary"
  engine     = "postgres"
  instance_class = "db.t3.medium"
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
}

# Read Replica in secondary region
resource "aws_db_instance" "replica" {
  provider = aws.secondary
  
  replicate_source_db = aws_db_instance.primary.arn
  identifier          = "signal-factory-replica"
  instance_class      = "db.t3.medium"
}
```

## 관련 문서

- [아키텍처 개요](./01_architecture_overview.md)
- [보안](./07_security.md)

[← 메인 문서로 돌아가기](./00_overview.md)

\newpage

# API 명세

[← 메인 문서로 돌아가기](./00_overview.md)

## API 버전 관리

- Base URL: `https://api.signal-factory.com/api/v1`
- 인증: Bearer Token (JWT)
- Content-Type: `application/json`

## 인증 API

### POST /auth/register
사용자 등록

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "name": "John Doe"
}
```

**Response (201):**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "tier": "free"
  },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### POST /auth/login
로그인

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response (200):**
```json
{
  "user": { "id": "uuid", "email": "...", "name": "...", "tier": "..." },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

## 로직 API

### POST /logics
로직 생성

**Request:**
```json
{
  "name": "MA Crossover Strategy",
  "description": "20/50 이동평균 크로스오버 전략",
  "code": "function generateSignal(input) { ... }",
  "tags": ["moving-average", "trend-following"],
  "category": "technical"
}
```

**Response (201):**
```json
{
  "logic": {
    "id": "uuid",
    "name": "MA Crossover Strategy",
    "version": 1,
    "createdAt": "2025-01-01T00:00:00Z"
  }
}
```

### GET /logics
로직 목록 조회

**Query Parameters:**
- `search`: 검색어
- `tags`: 태그 필터 (콤마 구분)
- `category`: 카테고리 필터
- `page`: 페이지 번호 (default: 1)
- `limit`: 페이지 크기 (default: 20)
- `sort`: 정렬 기준 (created_at, updated_at, name)
- `order`: 정렬 순서 (asc, desc)

**Response (200):**
```json
{
  "logics": [
    {
      "id": "uuid",
      "name": "...",
      "description": "...",
      "tags": ["..."],
      "createdAt": "...",
      "metrics": {
        "avgExecutionTime": 50,
        "successRate": 0.95
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "pages": 5
  }
}
```

### GET /logics/:id
로직 상세 조회

**Response (200):**
```json
{
  "logic": {
    "id": "uuid",
    "name": "...",
    "description": "...",
    "code": "...",
    "version": 1,
    "author": { "id": "...", "name": "..." },
    "createdAt": "...",
    "updatedAt": "..."
  }
}
```

### PUT /logics/:id
로직 수정

**Request:**
```json
{
  "name": "Updated Strategy Name",
  "code": "function generateSignal(input) { ... }"
}
```

**Response (200):**
```json
{
  "logic": {
    "id": "uuid",
    "version": 2,
    "updatedAt": "..."
  }
}
```

### DELETE /logics/:id
로직 삭제 (소프트 삭제)

**Response (204):** No Content

## 포트폴리오 API

### POST /portfolios
포트폴리오 생성

**Request:**
```json
{
  "name": "Balanced Portfolio",
  "description": "균형잡힌 포트폴리오",
  "logics": [
    { "logicId": "uuid1", "weight": 0.5, "allocation": 0.4 },
    { "logicId": "uuid2", "weight": 0.5, "allocation": 0.6 }
  ],
  "strategy": "weighted"
}
```

**Response (201):**
```json
{
  "portfolio": {
    "id": "uuid",
    "name": "...",
    "status": "active",
    "createdAt": "..."
  }
}
```

### GET /portfolios
포트폴리오 목록

**Response (200):**
```json
{
  "portfolios": [
    {
      "id": "uuid",
      "name": "...",
      "status": "active",
      "return": 5.5,
      "logicCount": 2
    }
  ]
}
```

## 백테스트 API

### POST /backtests
백테스트 실행

**Request:**
```json
{
  "portfolioId": "uuid",
  "startDate": "2024-01-01",
  "endDate": "2024-12-31",
  "initialCash": 10000,
  "symbols": ["BTCUSDT", "ETHUSDT"],
  "commission": { "type": "percentage", "value": 0.001 },
  "slippage": { "type": "percentage", "value": 0.0005 },
  "interval": "1h"
}
```

**Response (202):**
```json
{
  "backtest": {
    "id": "uuid",
    "status": "pending",
    "createdAt": "..."
  }
}
```

### GET /backtests/:id
백테스트 결과 조회

**Response (200):**
```json
{
  "backtest": {
    "id": "uuid",
    "status": "completed",
    "summary": {
      "totalReturn": 0.15,
      "annualizedReturn": 0.18,
      "maxDrawdown": 0.08,
      "sharpeRatio": 1.5
    },
    "trades": {
      "total": 45,
      "winning": 28,
      "losing": 17,
      "winRate": 0.622
    },
    "timeline": [
      { "timestamp": "...", "cash": 10000, "equity": 0, "total": 10000 },
      ...
    ]
  }
}
```

## 실시간 신호 API

### GET /signals/realtime
실시간 신호 조회 (Premium+)

**Query Parameters:**
- `portfolioId`: 포트폴리오 ID
- `since`: 이후 신호 조회 (ISO 8601)
- `limit`: 결과 개수 (default: 50)

**Response (200):**
```json
{
  "signals": [
    {
      "id": "uuid",
      "portfolioId": "...",
      "symbol": "BTCUSDT",
      "action": "ENTRY",
      "orderType": "MARKET",
      "quantity": 0.1,
      "price": 42000,
      "reason": "골든 크로스",
      "confidence": 0.85,
      "timestamp": "..."
    }
  ]
}
```

## WebSocket API

### WS /ws/signals/:portfolioId
실시간 신호 스트림

**Connection:**
```javascript
const ws = new WebSocket('wss://api.signal-factory.com/ws/signals/portfolio-id', {
  headers: {
    'Authorization': 'Bearer token'
  }
});

ws.onmessage = (event) => {
  const signal = JSON.parse(event.data);
  console.log('New signal:', signal);
};
```

**Message Format:**
```json
{
  "type": "SIGNAL",
  "data": {
    "symbol": "BTCUSDT",
    "action": "ENTRY",
    "price": 42000,
    "timestamp": "..."
  }
}
```

## 에러 코드

| Code | Description |
|------|-------------|
| 400 | Bad Request - 잘못된 요청 |
| 401 | Unauthorized - 인증 필요 |
| 403 | Forbidden - 권한 부족 |
| 404 | Not Found - 리소스 없음 |
| 429 | Too Many Requests - Rate limit 초과 |
| 500 | Internal Server Error - 서버 오류 |

**Error Response Format:**
```json
{
  "error": {
    "code": "INVALID_INPUT",
    "message": "Invalid portfolio configuration",
    "details": {
      "field": "logics",
      "issue": "At least one logic is required"
    }
  }
}
```

## Rate Limits

| Tier | Limit |
|------|-------|
| Free | 100 requests/hour |
| Premium | 1000 requests/hour |
| Enterprise | Unlimited |

[← 메인 문서로 돌아가기](./00_overview.md)

\newpage

# 데이터 모델

[← 메인 문서로 돌아가기](./00_overview.md)

## 최적화된 시세 데이터 구조

### 압축된 배열 포맷

```typescript
// 기존 JSON 포맷 (비효율적)
interface TraditionalCandle {
  timestamp: number;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
}

// 최적화된 배열 포맷 (70% 크기 감소)
type CompressedCandle = [
  number, // timestamp
  number, // open
  number, // high
  number, // low
  number, // close
  number  // volume
];

interface MarketData {
  metadata: {
    symbol: string;
    interval: string;
    timezone: string;
    fields: string[]; // ["timestamp", "open", "high", "low", "close", "volume"]
  };
  data: CompressedCandle[];
}
```

### Protocol Buffers 포맷

```protobuf
// market_data.proto
syntax = "proto3";

message Tick {
  int64 timestamp = 1;
  double open = 2;
  double high = 3;
  double low = 4;
  double close = 5;
  double volume = 6;
}

message MarketDataBatch {
  string symbol = 1;
  string interval = 2;
  repeated Tick ticks = 3;
}

// 80-90% 크기 감소
```

### Delta Encoding

```typescript
class DeltaEncoder {
  // 첫 값과 차이만 저장
  encode(candles: number[][]): DeltaEncodedData {
    const base = candles[0];
    const deltas = candles.slice(1).map((candle, i) => 
      candle.map((val, j) => {
        if (j === 0) return val - candles[i][0]; // timestamp delta
        return Math.round((val - candles[i][j]) * 100); // price delta (2 decimals)
      })
    );
    
    return { base, deltas };
  }
  
  decode({ base, deltas }: DeltaEncodedData): number[][] {
    const candles = [base];
    
    deltas.forEach((delta, i) => {
      const prev = candles[i];
      const restored = delta.map((d, j) => {
        if (j === 0) return prev[0] + d;
        return prev[j] + d / 100;
      });
      candles.push(restored);
    });
    
    return candles;
  }
}
```

## 데이터베이스 스키마

### PostgreSQL Schema

```sql
-- 사용자
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  password_hash TEXT NOT NULL,
  tier VARCHAR(20) DEFAULT 'free',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 로직
CREATE TABLE logics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID REFERENCES users(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  code TEXT NOT NULL,
  version INTEGER DEFAULT 1,
  tags TEXT[],
  category VARCHAR(100),
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);

-- 로직 버전 히스토리
CREATE TABLE logic_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  logic_id UUID REFERENCES logics(id),
  version INTEGER NOT NULL,
  code TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(logic_id, version)
);

-- 포트폴리오
CREATE TABLE portfolios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  logics JSONB NOT NULL, -- [{ logic_id, weight, allocation }]
  strategy VARCHAR(50) DEFAULT 'weighted',
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_run_at TIMESTAMP
);

-- 백테스트
CREATE TABLE backtests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  portfolio_id UUID REFERENCES portfolios(id),
  config JSONB NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  results JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP
);

-- 신호
CREATE TABLE signals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  portfolio_id UUID REFERENCES portfolios(id),
  symbol VARCHAR(50) NOT NULL,
  action VARCHAR(10) NOT NULL, -- ENTRY, EXIT, NONE
  order_type VARCHAR(20) NOT NULL,
  quantity DECIMAL(18, 8) NOT NULL,
  price DECIMAL(18, 8),
  reason TEXT,
  confidence DECIMAL(3, 2),
  metadata JSONB,
  timestamp TIMESTAMP DEFAULT NOW(),
  INDEX idx_signals_portfolio_time (portfolio_id, timestamp),
  INDEX idx_signals_symbol_time (symbol, timestamp)
);

-- 거래
CREATE TABLE trades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  portfolio_id UUID REFERENCES portfolios(id),
  signal_id UUID REFERENCES signals(id),
  symbol VARCHAR(50) NOT NULL,
  side VARCHAR(10) NOT NULL, -- BUY, SELL
  quantity DECIMAL(18, 8) NOT NULL,
  price DECIMAL(18, 8) NOT NULL,
  commission DECIMAL(18, 8),
  status VARCHAR(20) DEFAULT 'pending',
  broker_order_id VARCHAR(255),
  executed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### TimescaleDB (시계열 데이터)

```sql
-- 시세 데이터 (하이퍼테이블)
CREATE TABLE market_data (
  time TIMESTAMPTZ NOT NULL,
  symbol VARCHAR(50) NOT NULL,
  open DECIMAL(18, 8) NOT NULL,
  high DECIMAL(18, 8) NOT NULL,
  low DECIMAL(18, 8) NOT NULL,
  close DECIMAL(18, 8) NOT NULL,
  volume DECIMAL(18, 8) NOT NULL
);

-- TimescaleDB 하이퍼테이블 변환
SELECT create_hypertable('market_data', 'time');

-- 인덱스
CREATE INDEX idx_market_data_symbol_time 
  ON market_data (symbol, time DESC);

-- 압축 (6개월 이상 데이터)
ALTER TABLE market_data SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'symbol'
);

SELECT add_compression_policy('market_data', INTERVAL '180 days');

-- 데이터 보관 정책 (2년 후 삭제)
SELECT add_retention_policy('market_data', INTERVAL '2 years');
```

### Redis 데이터 구조

```typescript
// 실시간 시세 (Hash)
// Key: `price:${symbol}`
interface PriceData {
  price: string;
  volume: string;
  timestamp: string;
}

redis.hset('price:BTCUSDT', {
  price: '42000.50',
  volume: '123.45',
  timestamp: Date.now().toString()
});

// 사용자 세션 (String, TTL 7일)
redis.setex(`session:${userId}`, 7 * 24 * 3600, JSON.stringify(sessionData));

// 실시간 신호 큐 (List)
redis.lpush('signals:pending', JSON.stringify(signal));
const signal = await redis.brpop('signals:pending', 0);

// Rate limiting (Sorted Set)
const key = `ratelimit:${userId}:${endpoint}`;
redis.zadd(key, Date.now(), `${Date.now()}-${uuid()}`);
redis.zremrangebyscore(key, 0, Date.now() - windowMs);
const count = await redis.zcard(key);
```

## Parquet 파일 포맷 (S3)

```python
# Python (PyArrow)
import pyarrow as pa
import pyarrow.parquet as pq

# 스키마 정의
schema = pa.schema([
    pa.field('timestamp', pa.timestamp('ms')),
    pa.field('open', pa.float64()),
    pa.field('high', pa.float64()),
    pa.field('low', pa.float64()),
    pa.field('close', pa.float64()),
    pa.field('volume', pa.float64())
])

# 데이터 작성
table = pa.Table.from_pandas(df, schema=schema)
pq.write_table(
    table, 
    's3://bucket/data.parquet',
    compression='snappy',
    use_dictionary=True
)

# Parquet 파일은 70-90% 압축률 제공
# Snappy 압축: 빠른 읽기/쓰기
# 칼럼 저장: 선택적 칼럼 읽기 가능
```

## 파일 시스템 구조

```
s3://signal-factory-data/
├── market-data/
│   ├── BTCUSDT/
│   │   ├── 2024/
│   │   │   ├── 01/
│   │   │   │   ├── 1m.parquet
│   │   │   │   ├── 5m.parquet
│   │   │   │   └── 1h.parquet
│   │   │   └── 02/
│   │   └── 2025/
│   └── ETHUSDT/
├── backtests/
│   ├── {backtest-id}/
│   │   ├── config.json
│   │   ├── trades.parquet
│   │   └── equity-curve.parquet
└── user-logics/
    ├── {user-id}/
    │   ├── {logic-id}/
    │   │   ├── v1.js.enc
    │   │   ├── v2.js.enc
    │   │   └── metadata.json
```

## 관련 문서

- [데이터 파이프라인](./02_data_pipeline.md)
- [API 명세](./09_api_specifications.md)

[← 메인 문서로 돌아가기](./00_overview.md)

\newpage

# 기술 스택

[← 메인 문서로 돌아가기](./00_overview.md)

## 프론트엔드

### 웹 (React)
- **React 18**: UI 라이브러리
- **TypeScript**: 정적 타입 검사
- **Vite**: 빌드 도구
- **React Router**: 라우팅
- **Zustand**: 상태 관리
- **React Query**: 서버 상태 관리
- **Material-UI**: UI 컴포넌트
- **Tailwind CSS**: 유틸리티 CSS
- **Monaco Editor**: 코드 에디터
- **TradingView Lightweight Charts**: 금융 차트
- **Recharts**: 대시보드 차트
- **Axios**: HTTP 클라이언트

### 모바일 (Expo/React Native)
- **Expo SDK 50**: React Native 플랫폼
- **React Native 0.73**: 네이티브 프레임워크
- **TypeScript**: 타입 안전성
- **Expo Router**: 파일 기반 라우팅
- **React Native Paper**: Material Design
- **React Query**: 서버 상태
- **Victory Native**: 차트
- **Expo Notifications**: 푸시 알림

## 백엔드

### Node.js 스택
- **Node.js 18 LTS**: JavaScript 런타임
- **TypeScript**: 타입 안전성
- **Express.js**: 웹 프레임워크
- **Fastify**: 고성능 대안
- **VM2/isolated-vm**: JavaScript 샌드박스
- **Socket.io**: WebSocket 통신
- **Bull**: 작업 큐 (Redis 기반)
- **Winston**: 로깅
- **Joi**: 데이터 검증
- **Helmet**: 보안 헤더
- **Passport.js**: 인증

### Python 스택 (데이터 처리)
- **Python 3.11**: 언어
- **FastAPI**: 고성능 웹 프레임워크
- **Pandas**: 데이터 분석
- **NumPy**: 수치 계산
- **TA-Lib**: 기술적 지표
- **PyArrow**: Parquet 처리
- **Asyncio**: 비동기 처리

### Rust (고성능 컴포넌트)
- **Rust 1.75**: 시스템 프로그래밍 언어
- **Tokio**: 비동기 런타임
- **Actix-web**: 웹 프레임워크
- **Serde**: 직렬화/역직렬화
- **용도**: 실시간 데이터 파싱, 백테스팅 엔진

## 데이터베이스

### 관계형
- **PostgreSQL 15**: 주 데이터베이스
- **TimescaleDB**: 시계열 데이터 확장
- **Prisma**: ORM
- **Knex.js**: 쿼리 빌더 및 마이그레이션

### NoSQL/캐시
- **Redis 7**: 캐시 및 세션 저장소
- **Redis Streams**: 실시간 메시지 큐

### 객체 스토리지
- **AWS S3**: 원시 데이터, 백업
- **MinIO**: S3 호환 자체 호스팅 대안

## 인프라

### 클라우드
- **AWS**: 주요 클라우드 제공자
  - EC2: 컴퓨팅
  - ECS/Fargate: 컨테이너
  - RDS: 관리형 데이터베이스
  - S3: 객체 스토리지
  - CloudFront: CDN
  - Route 53: DNS
  - Secrets Manager: 비밀 관리
  - CloudWatch: 모니터링

### 컨테이너
- **Docker**: 컨테이너화
- **Kubernetes**: 오케스트레이션
- **Helm**: K8s 패키지 관리

### CI/CD
- **GitHub Actions**: CI/CD 파이프라인
- **Docker Hub**: 컨테이너 레지스트리
- **AWS ECR**: 프라이빗 레지스트리

## 모니터링 & 로깅

### 메트릭
- **Prometheus**: 메트릭 수집
- **Grafana**: 시각화 대시보드
- **prom-client**: Node.js 클라이언트

### 로깅
- **Winston**: Node.js 로거
- **Elasticsearch**: 로그 저장 및 검색
- **Logstash**: 로그 수집
- **Kibana**: 로그 시각화

### APM
- **Sentry**: 에러 추적
- **Datadog**: 종합 모니터링 (선택적)

## 보안

### 인증/인가
- **JWT**: 토큰 기반 인증
- **bcrypt**: 비밀번호 해싱
- **OAuth 2.0**: 소셜 로그인

### 암호화
- **crypto (Node.js)**: AES-256-GCM
- **AWS KMS**: 키 관리

### 보안 도구
- **Snyk**: 의존성 취약점 스캔
- **ESLint Security Plugin**: 정적 분석
- **Helmet**: HTTP 보안 헤더

## 테스팅

### 단위 테스트
- **Jest**: JavaScript 테스트 프레임워크
- **React Testing Library**: React 컴포넌트 테스트
- **pytest**: Python 테스트

### E2E 테스트
- **Playwright**: 브라우저 자동화
- **Cypress**: E2E 테스트 (대안)

### 부하 테스트
- **k6**: 부하 테스트 도구

## 개발 도구

### 코드 품질
- **ESLint**: JavaScript 린터
- **Prettier**: 코드 포매터
- **TypeScript**: 타입 체커
- **Husky**: Git 훅

### API 문서
- **Swagger/OpenAPI**: API 문서 자동 생성
- **Redoc**: API 문서 뷰어

## 외부 서비스

### 데이터 제공
- **Binance API**: 암호화폐 데이터
- **Alpha Vantage**: 주식 데이터
- **IEX Cloud**: 금융 데이터

### 알림
- **SendGrid**: 이메일
- **Twilio**: SMS
- **Expo Push**: 모바일 푸시
- **Firebase Cloud Messaging**: 모바일 푸시

### 결제
- **Stripe**: 구독 결제
- **Toss Payments**: 국내 결제 (선택적)

[← 메인 문서로 돌아가기](./00_overview.md)

\newpage

# 사용자 워크플로우

[← 메인 문서로 돌아가기](./00_overview.md)

## 신규 사용자 온보딩

### 1. 회원가입
1. 소셜 계정 선택 (Google, GitHub, Facebook)
2. OAuth 인증 완료
3. 기본 정보 입력 (선택적)
4. 이용 약관 동의
5. 계정 생성 완료

### 2. 튜토리얼
1. **대시보드 둘러보기**
   - 주요 기능 소개
   - 인터페이스 설명

2. **첫 로직 작성**
   - 샘플 로직 제공
   - 코드 에디터 사용법
   - 저장 및 테스트

3. **첫 포트폴리오 생성**
   - 로직 선택
   - 가중치 설정
   - 포트폴리오 저장

4. **백테스트 실행**
   - 테스트 기간 설정
   - 초기 자금 설정
   - 결과 확인

## 일반 사용자 워크플로우

### 로직 개발 워크플로우

```
1. 아이디어 구상
   ↓
2. 로직 에디터에서 코드 작성
   ↓
3. 실시간 문법 검사 확인
   ↓
4. 샘플 데이터로 테스트 실행
   ↓
5. 결과 확인 및 디버깅
   ↓
6. 로직 저장 (버전 관리)
   ↓
7. 태그 및 카테고리 지정
```

### 포트폴리오 구성 워크플로우

```
1. 새 포트폴리오 생성
   ↓
2. 로직 라이브러리에서 로직 선택
   - 내 로직
   - 공개 로직 (선택적)
   ↓
3. 각 로직에 가중치 할당
   ↓
4. 신호 통합 전략 선택
   - 다수결
   - 가중 평균
   - 우선순위
   ↓
5. 포트폴리오 저장
```

### 백테스트 워크플로우

```
1. 포트폴리오 선택
   ↓
2. 백테스트 설정
   - 테스트 기간
   - 초기 자금
   - 거래 종목
   - 수수료/슬리피지
   ↓
3. 백테스트 실행 (비동기)
   ↓
4. 완료 알림 수신
   ↓
5. 결과 분석
   - 수익률 지표
   - 리스크 지표
   - 거래 통계
   - 자산 곡선
   ↓
6. 결과 다운로드 (PDF/CSV)
   ↓
7. 필요시 로직 수정 및 재테스트
```

### 실시간 모니터링 워크플로우

```
1. 포트폴리오 활성화
   ↓
2. 실시간 데이터 구독 시작
   ↓
3. 대시보드에서 모니터링
   - 현재 포지션
   - 실시간 손익
   - 최근 신호
   ↓
4. 신호 발생 시 알림 수신
   - 푸시 알림 (모바일)
   - 이메일 (설정 시)
   ↓
5. 신호 검토 및 판단
   ↓
6. 수동 거래 또는 자동 매매
```

## 프리미엄 사용자 워크플로우

### 자동 매매 설정

```
1. 브로커 연동
   - API 키 등록
   - 권한 확인
   ↓
2. 리스크 파라미터 설정
   - 최대 손실 한도
   - 포지션 크기 제한
   - 일일 거래 횟수 제한
   ↓
3. 자동 매매 활성화
   ↓
4. 페이퍼 트레이딩으로 검증 (권장)
   ↓
5. 실거래 전환
   ↓
6. 지속적 모니터링
   - 거래 내역 확인
   - 성과 추적
   ↓
7. 필요시 킬 스위치 사용
```

### API 활용

```
1. API 키 생성
   ↓
2. API 문서 확인
   ↓
3. 외부 시스템 통합
   - 실시간 신호 수신
   - 커스텀 대시보드 구축
   ↓
4. Rate limit 관리
```

## 시나리오별 워크플로우

### 시나리오 1: 간단한 이동평균 전략 테스트

**목표**: 20/50 이동평균 크로스오버 전략 백테스트

**단계**:
1. 로그인
2. "새 로직" 버튼 클릭
3. 제공된 템플릿 선택: "MA Crossover"
4. 파라미터 조정 (기간: 20, 50)
5. 로직 저장: "My MA Strategy"
6. "새 포트폴리오" 생성
7. "My MA Strategy" 추가
8. "백테스트 실행" 클릭
9. 기간 설정: 2024-01-01 ~ 2024-12-31
10. 종목 선택: BTCUSDT
11. 실행 후 결과 대기 (1-2분)
12. 결과 분석: 수익률 15%, MDD 8%
13. 만족스러우면 실시간 모니터링 활성화

**예상 소요 시간**: 10-15분

### 시나리오 2: 여러 로직 조합

**목표**: 트렌드 추종 + 평균 회귀 전략 조합

**단계**:
1. 첫 번째 로직 작성: "Trend Following"
2. 두 번째 로직 작성: "Mean Reversion"
3. 각각 개별 백테스트
4. 새 포트폴리오 생성: "Hybrid Strategy"
5. 두 로직 추가, 가중치 50:50
6. 통합 전략 선택: "가중 평균"
7. 백테스트 실행
8. 개별 전략 vs 조합 전략 성과 비교
9. 가중치 조정 및 재테스트

**예상 소요 시간**: 30-45분

### 시나리오 3: 자동 매매 설정

**목표**: 검증된 전략으로 자동 매매 시작

**단계**:
1. 백테스트로 충분히 검증된 포트폴리오 선택
2. 페이퍼 트레이딩 활성화
3. 1주일 모니터링
4. 성과 만족 시 실거래 설정
5. Binance API 키 등록
6. 리스크 한도 설정
   - 일일 최대 손실: $100
   - 포지션 크기: 계좌의 10%
7. 자동 매매 활성화
8. 푸시 알림 설정 (모든 거래)
9. 매일 성과 확인
10. 필요시 파라미터 조정

**예상 소요 시간**: 초기 설정 30분, 지속적 관리 5분/일

## 모바일 앱 워크플로우

### 외출 중 신호 확인

1. 푸시 알림 수신
2. 앱 열기 (생체 인증)
3. 신호 상세 확인
   - 종목
   - 액션 (진입/청산)
   - 가격
   - 이유
4. 차트에서 시각적 확인
5. 수동 거래 결정 (Premium+)
6. 브로커 앱으로 이동하여 주문

### 이동 중 포트폴리오 성과 확인

1. 앱 열기
2. 대시보드에서 총 자산 확인
3. 개별 포트폴리오 탭
4. 일별/주별/월별 수익률 확인
5. 최근 거래 내역 확인

## 사용자 지원

### 문제 해결 워크플로우

```
1. 문제 발생
   ↓
2. FAQ 검색
   ↓
3. 해결되지 않으면 고객 지원 티켓 생성
   - 문제 설명
   - 스크린샷 첨부
   ↓
4. 지원팀 응답 대기 (24시간 이내)
   ↓
5. 해결책 적용
   ↓
6. 피드백 제공
```

[← 메인 문서로 돌아가기](./00_overview.md)

\newpage

# 비즈니스 모델

[← 메인 문서로 돌아가기](./00_overview.md)

## 가격 정책

### Free Tier (무료)

**가격**: $0/월

**제공 기능**:
- 로직 작성 및 저장 (최대 5개)
- 포트폴리오 생성 (최대 2개)
- 백테스트 실행 (월 10회)
- 5분 단위 타이머 기반 신호 생성
- 이메일 알림 (일 3건)
- 커뮤니티 지원

**제한사항**:
- 실시간 신호 없음
- API 접근 없음
- 자동 매매 없음
- 고급 지표 제한

**타겟 사용자**:
- 트레이딩 전략 학습자
- 플랫폼 체험 사용자
- 취미 트레이더

### Premium Tier (프리미엄)

**가격**: $29/월 (연간 결제 시 $290, 17% 할인)

**추가 기능**:
- 로직 무제한
- 포트폴리오 무제한
- 백테스트 무제한
- **실시간 신호 생성**
- **포워드 테스트**
- 푸시/SMS 알림 무제한
- 고급 기술 지표 라이브러리
- API 접근 (1,000 req/hour)
- 우선 고객 지원
- 데이터 다운로드 (CSV, Parquet)

**타겟 사용자**:
- 진지한 개인 트레이더
- 알고리즘 트레이딩 학습자
- 프리랜서 트레이더

### Pro Tier (프로)

**가격**: $99/월 (연간 결제 시 $990, 17% 할인)

**추가 기능**:
- Premium의 모든 기능
- **자동 매매 연동 (Paper Trading)**
- **실계좌 신호 API** (직접 연동)
- 고급 이평 데이터 제공
- 멀티 브로커 지원
- API 접근 (10,000 req/hour)
- 맞춤 지표 개발 지원
- 전용 고객 지원 (24시간 이내 응답)
- 과거 데이터 접근 (5년)

**타겟 사용자**:
- 전업 트레이더
- 중소 헤지펀드
- 트레이딩 봇 개발자

### Enterprise Tier (엔터프라이즈)

**가격**: 문의 필요 (Starts at $500/월)

**추가 기능**:
- Pro의 모든 기능
- **계좌 위탁 관리** (별도 계약)
- **전용 인프라**
- **커스텀 브로커 연동**
- **화이트라벨 솔루션**
- 무제한 API 접근
- SLA 보장 (99.9% uptime)
- 전담 계정 매니저
- 맞춤 개발 지원
- 온프레미스 배포 옵션

**타겟 사용자**:
- 헤지펀드
- 자산운용사
- 금융 기관
- 대규모 트레이딩 팀

## 수익 모델

### 1. 구독 수익 (주 수익원)

**예상 구성**:
- Free Tier: 70% (전환 깔때기)
- Premium: 20% (월 $580 per 20 users)
- Pro: 8% (월 $792 per 8 users)
- Enterprise: 2% (월 $1,000+ per 2 clients)

**예상 MRR (1,000 사용자 기준)**:
- 200 Premium × $29 = $5,800
- 80 Pro × $99 = $7,920
- 2 Enterprise × $500 = $1,000
- **Total MRR**: ~$14,720
- **Annual Run Rate**: ~$176,640

### 2. 거래 수수료 (선택적)

Enterprise 고객의 계좌 위탁 시:
- 수익의 10-20% 성과 보수
- 또는 운용 자산의 1-2% 관리 보수

### 3. 마켓플레이스 (향후)

- 로직 판매 수수료: 30%
- 프리미엄 데이터 재판매

### 4. API 사용량 기반 (향후)

- 기본 할당량 초과 시 추가 요금
- $10 per 10,000 추가 요청

## 사용자 획득 전략

### 1. 콘텐츠 마케팅

- **블로그**: 트레이딩 전략 튜토리얼
- **YouTube**: 플랫폼 사용법, 전략 분석
- **Medium**: 기술 블로그
- **SEO**: "algorithmic trading", "backtesting platform" 등 키워드 최적화

### 2. 커뮤니티 구축

- Discord/Slack 커뮤니티
- 사용자 로직 공유 포럼
- 월간 트레이딩 대회

### 3. 제휴 프로그램

- 브로커 제휴 (Binance, Upbit 등)
- 트레이딩 교육 플랫폼 제휴
- 인플루언서 협업

### 4. 무료 체험

- 14일 Premium 무료 체험
- 신용카드 없이 가입 가능
- 체험 종료 시 자동 다운그레이드 (Free)

## 사용자 유지 전략

### 1. 온보딩 최적화

- 인터랙티브 튜토리얼
- 샘플 로직 및 포트폴리오 제공
- 첫 백테스트 안내

### 2. 가치 제공

- 정기 웨비나
- 월간 시장 분석 리포트 (Premium+)
- 신규 지표/기능 우선 제공

### 3. 커뮤니케이션

- 이메일 뉴스레터 (월 2회)
- 주요 업데이트 알림
- 맞춤 사용 팁

### 4. 감마화(Gamification)

- 성과 배지
- 리더보드
- 추천 보상

## 가격 책정 근거

### 경쟁사 분석

| 플랫폼 | 가격 | 주요 기능 |
|-------|------|-----------|
| QuantConnect | $0-$99/월 | 백테스팅, 라이브 트레이딩 |
| TradingView | $0-$60/월 | 차트, 알림 |
| Quantopian | 종료 | - |
| **Signal Factory** | $0-$99/월 | 백테스팅, 라이브, 자동매매 |

### 가치 제안

- **Free**: 학습 및 테스트
- **Premium ($29)**: QuantConnect Lean보다 저렴, TradingView Pro와 유사
- **Pro ($99)**: QuantConnect Professional과 동등, 더 많은 기능
- **Enterprise**: 맞춤형, 경쟁사 대비 유연성

## 성장 예측

### Year 1 (출시 후 12개월)

- **목표 사용자**: 5,000
  - Free: 3,500 (70%)
  - Premium: 1,000 (20%)
  - Pro: 400 (8%)
  - Enterprise: 10 (0.2%)

- **MRR**: ~$73,600
- **ARR**: ~$883,200

### Year 2

- **목표 사용자**: 20,000
- **MRR**: ~$294,400
- **ARR**: ~$3,532,800

### Year 3

- **목표 사용자**: 50,000
- **MRR**: ~$736,000
- **ARR**: ~$8,832,000

## 수익 분배

### 비용 구조

- **인프라**: 30% (AWS, 데이터 피드)
- **인건비**: 40% (개발, 지원)
- **마케팅**: 20%
- **운영**: 10%

### 손익분기점

- **고정 비용**: ~$20,000/월 (초기)
- **변동 비용**: ~30% of revenue
- **손익분기점 MRR**: ~$28,600
- **예상 달성**: 5-6개월 후

## 확장 계획

### 단기 (6-12개월)

- 마켓플레이스 오픈 (로직 판매)
- 모바일 앱 출시
- 추가 브로커 연동 (5개 이상)

### 중기 (1-2년)

- 머신러닝 모델 통합
- 소셜 트레이딩 기능
- 다국어 지원 (영어, 한국어, 일본어)

### 장기 (2-3년)

- 화이트라벨 B2B 솔루션
- 기관 투자자 서비스
- 규제 라이선스 획득

[← 메인 문서로 돌아가기](./00_overview.md)

\newpage

# 개발 로드맵

[← 메인 문서로 돌아가기](./00_overview.md)

## Phase 1: 기초 인프라 (개월 1-2)

### 목표
프로젝트 기반 구축 및 핵심 인프라 설정

### 주요 작업

**Week 1-2: 프로젝트 설정**
- [x] 프로젝트 구조 설계
- [x] 상세 기획 문서 작성
- [ ] Git 저장소 설정
- [ ] 개발 환경 구성
- [ ] CI/CD 파이프라인 기본 설정

**Week 3-4: 데이터 파이프라인**
- [ ] PostgreSQL 스키마 설계
- [ ] TimescaleDB 설정
- [ ] Redis 설정
- [ ] S3 버킷 구조 설계
- [ ] 데이터 수집기 프로토타입
  - [ ] Binance API 연동
  - [ ] 데이터 정규화
  - [ ] 저장 로직

**Week 5-6: 로직 실행 엔진**
- [ ] VM2 샌드박스 구현
- [ ] 로직 인터페이스 정의
- [ ] 기본 헬퍼 함수 (MA, RSI, MACD)
- [ ] 로직 실행 테스트
- [ ] 에러 처리 및 로깅

**Week 7-8: 인증 시스템**
- [ ] JWT 인증 구현
- [ ] 소셜 로그인 (Google, GitHub)
- [ ] 사용자 등급 관리
- [ ] API 키 관리

**Deliverables**
- ✅ 기능하는 데이터 수집 시스템
- ✅ 안전한 로직 실행 환경
- ✅ 사용자 인증 시스템

## Phase 2: 핵심 기능 (개월 3-5)

### 목표
웹 UI 개발 및 백테스팅 엔진 구현

### 주요 작업

**Month 3: 웹 UI 기본**
- [ ] React 프로젝트 설정
- [ ] 레이아웃 및 네비게이션
- [ ] 대시보드 페이지
- [ ] 로직 목록 페이지
- [ ] 로직 에디터 (Monaco)
  - [ ] 문법 강조
  - [ ] 자동 완성
  - [ ] 실시간 린트

**Month 4: 포트폴리오 관리**
- [ ] 포트폴리오 CRUD API
- [ ] 포트폴리오 구성 UI
- [ ] 드래그 앤 드롭
- [ ] 가중치 설정
- [ ] 신호 통합 전략

**Month 5: 백테스팅 엔진**
- [ ] 백테스트 설정 API
- [ ] 시뮬레이션 엔진
  - [ ] 주문 처리
  - [ ] 포지션 관리
  - [ ] 수수료/슬리피지 계산
- [ ] 성과 메트릭 계산
  - [ ] 수익률
  - [ ] MDD
  - [ ] 샤프 비율
- [ ] 백테스트 결과 UI
  - [ ] 자산 곡선 차트
  - [ ] 거래 내역 테이블
  - [ ] PDF 리포트 생성

**Deliverables**
- ✅ 완전한 웹 인터페이스
- ✅ 로직 및 포트폴리오 관리
- ✅ 백테스팅 기능

## Phase 3: 실시간 기능 (개월 6-8)

### 목표
실시간 데이터 연동 및 신호 생성

### 주요 작업

**Month 6: 실시간 데이터**
- [ ] WebSocket 서버 설정
- [ ] 실시간 데이터 스트림
  - [ ] Binance WebSocket
  - [ ] 데이터 정규화
  - [ ] Redis 캐싱
- [ ] 실시간 차트 컴포넌트

**Month 7: 실시간 신호 생성**
- [ ] 신호 생성 워커
- [ ] 신호 큐 (Bull)
- [ ] 실시간 로직 트리거
- [ ] 신호 저장 및 로깅
- [ ] 실시간 신호 UI

**Month 8: 모바일 앱 (Expo)**
- [ ] Expo 프로젝트 설정
- [ ] 기본 네비게이션
- [ ] 대시보드 화면
- [ ] 포트폴리오 목록
- [ ] 실시간 신호 화면
- [ ] 푸시 알림 연동

**Deliverables**
- ✅ 실시간 데이터 스트리밍
- ✅ 실시간 신호 생성
- ✅ 모바일 앱 (iOS/Android)

## Phase 4: 자동 매매 (개월 9-11)

### 목표
브로커 연동 및 자동 매매 시스템

### 주요 작업

**Month 9: 브로커 어댑터**
- [ ] 브로커 인터페이스 정의
- [ ] Binance 어댑터 구현
  - [ ] 인증
  - [ ] 계좌 조회
  - [ ] 주문 생성/취소
  - [ ] 체결 확인
- [ ] Upbit 어댑터 구현 (선택적)

**Month 10: 자동 매매 시스템**
- [ ] 주문 실행 로직
- [ ] 리스크 관리
  - [ ] 손실 한도 체크
  - [ ] 포지션 크기 제한
  - [ ] 일일 거래 횟수 제한
- [ ] 킬 스위치
- [ ] 페이퍼 트레이딩 모드

**Month 11: 자동 매매 UI**
- [ ] 브로커 연동 설정 페이지
- [ ] 리스크 파라미터 설정
- [ ] 거래 내역 조회
- [ ] 실시간 포지션 모니터링
- [ ] 긴급 정지 버튼

**Deliverables**
- ✅ 다중 브로커 지원
- ✅ 자동 매매 기능
- ✅ 리스크 관리 시스템

## Phase 5: 운영 및 확장 (개월 12+)

### 목표
보안 강화, 성능 최적화, 기능 확장

### 주요 작업

**Month 12: 보안 강화**
- [ ] 보안 감사
- [ ] 취약점 스캔 (Snyk)
- [ ] 침투 테스트
- [ ] 보안 패치 적용
- [ ] 암호화 강화

**Month 13-14: 성능 최적화**
- [ ] 데이터베이스 쿼리 최적화
- [ ] 캐싱 전략 개선
- [ ] API 응답 시간 단축
- [ ] 프론트엔드 번들 크기 감소
- [ ] 이미지 최적화

**Month 15-16: 고급 기능**
- [ ] 머신러닝 통합
- [ ] 마켓플레이스 (로직 판매)
- [ ] 소셜 트레이딩
- [ ] 커뮤니티 기능
- [ ] 튜토리얼 비디오

**Month 17-18: 국제화**
- [ ] 다국어 지원 (i18n)
  - [ ] 영어
  - [ ] 한국어
  - [ ] 일본어
- [ ] 타임존 처리
- [ ] 지역별 규정 준수

**Deliverables**
- ✅ 엔터프라이즈급 보안
- ✅ 최적화된 성능
- ✅ 확장된 기능 세트
- ✅ 국제 시장 진출

## 마일스톤

| 마일스톤 | 기간 | 상태 |
|---------|------|------|
| MVP (백테스팅) | Month 5 | 🔵 진행 예정 |
| Beta (실시간) | Month 8 | 🔵 진행 예정 |
| V1.0 (자동매매) | Month 11 | 🔵 진행 예정 |
| V2.0 (고급 기능) | Month 16 | 🔵 진행 예정 |

## 우선순위

### P0 (Must Have)
- 로직 작성 및 저장
- 백테스팅
- 실시간 신호 생성
- 웹 UI

### P1 (Should Have)
- 자동 매매
- 모바일 앱
- 포트폴리오 관리

### P2 (Nice to Have)
- 마켓플레이스
- 소셜 기능
- 머신러닝

## 릴리스 계획

### v0.1.0 - Alpha (Month 5)
- 기본 로직 작성
- 백테스팅
- 내부 테스트

### v0.5.0 - Beta (Month 8)
- 실시간 신호
- 모바일 앱
- 제한된 베타 사용자

### v1.0.0 - Public Launch (Month 11)
- 자동 매매
- 모든 핵심 기능
- 공개 출시

### v2.0.0 - Enhanced (Month 16)
- 고급 기능
- 국제화
- 엔터프라이즈 기능

[← 메인 문서로 돌아가기](./00_overview.md)
