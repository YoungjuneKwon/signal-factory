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
