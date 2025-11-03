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
