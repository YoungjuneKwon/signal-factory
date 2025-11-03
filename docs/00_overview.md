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

## 테스팅 전략

### 서버측 단위 테스트

**테스트 프레임워크:**
- **Jest**: JavaScript/TypeScript 단위 테스트
- **Supertest**: API 엔드포인트 테스트
- **pytest**: Python 컴포넌트 테스트
- **mockito**: 모킹 및 스텁

**테스트 대상 및 커버리지 요구사항:**

1. **API 엔드포인트 (필수 커버리지 80%+)**
   - 모든 RESTful 엔드포인트에 대한 성공/실패 케이스
   - 인증/인가 검증
   - 입력 검증 및 에러 핸들링
   - Rate limiting 동작 확인

2. **비즈니스 로직 (필수 커버리지 90%+)**
   - 신호 생성 알고리즘
   - 포트폴리오 계산 로직
   - 백테스팅 엔진
   - 리스크 관리 함수

3. **데이터베이스 레이어 (필수 커버리지 85%+)**
   - CRUD 작업 검증
   - 트랜잭션 처리
   - 데이터 무결성 제약조건
   - 마이그레이션 테스트

4. **보안 컴포넌트 (필수 커버리지 95%+)**
   - 인증/인가 미들웨어
   - 암호화/복호화 함수
   - 샌드박스 격리
   - API 키 검증

**단위 테스트 작성 예시:**

```javascript
// tests/api/logics.test.js
const request = require('supertest');
const app = require('../../src/app');
const db = require('../../src/db');

describe('Logic API', () => {
  beforeEach(async () => {
    await db.seed.run();
  });

  afterEach(async () => {
    await db.cleanupTestData();
  });

  describe('POST /api/v1/logics', () => {
    it('should create a new logic with valid data', async () => {
      const response = await request(app)
        .post('/api/v1/logics')
        .set('Authorization', 'Bearer valid-token')
        .send({
          name: 'Test Strategy',
          code: 'function generateSignal(input) { return "BUY"; }',
          description: 'Test description'
        });

      expect(response.status).toBe(201);
      expect(response.body.logic).toHaveProperty('id');
      expect(response.body.logic.name).toBe('Test Strategy');
    });

    it('should reject logic with malicious code', async () => {
      const response = await request(app)
        .post('/api/v1/logics')
        .set('Authorization', 'Bearer valid-token')
        .send({
          name: 'Malicious',
          code: 'require("child_process").exec("rm -rf /")'
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toContain('Forbidden pattern');
    });

    it('should enforce authentication', async () => {
      const response = await request(app)
        .post('/api/v1/logics')
        .send({ name: 'Test' });

      expect(response.status).toBe(401);
    });
  });

  describe('GET /api/v1/logics', () => {
    it('should return paginated logic list', async () => {
      const response = await request(app)
        .get('/api/v1/logics?page=1&limit=10')
        .set('Authorization', 'Bearer valid-token');

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('logics');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.pagination.page).toBe(1);
    });
  });
});

// tests/services/backtesting.test.js
const BacktestEngine = require('../../src/services/backtesting');

describe('Backtest Engine', () => {
  let engine;

  beforeEach(() => {
    engine = new BacktestEngine();
  });

  it('should calculate correct returns', () => {
    const trades = [
      { entry: 100, exit: 110, quantity: 1 },
      { entry: 110, exit: 105, quantity: 1 }
    ];

    const result = engine.calculateReturns(trades, 100);
    
    expect(result.totalReturn).toBeCloseTo(0.05); // 5%
    expect(result.winRate).toBe(0.5); // 50%
  });

  it('should handle empty trade list', () => {
    const result = engine.calculateReturns([], 100);
    
    expect(result.totalReturn).toBe(0);
    expect(result.trades).toBe(0);
  });

  it('should respect commission settings', () => {
    const trades = [{ entry: 100, exit: 110, quantity: 1 }];
    const commission = 0.001; // 0.1%

    const result = engine.calculateReturns(trades, 100, commission);
    
    // Return should be less than without commission
    expect(result.totalReturn).toBeLessThan(0.1);
  });
});
```

**테스트 디렉토리 구조:**

```
project-root/
├── src/
│   ├── api/
│   ├── services/
│   ├── models/
│   └── utils/
├── tests/
│   ├── unit/
│   │   ├── api/
│   │   │   ├── auth.test.js
│   │   │   ├── logics.test.js
│   │   │   └── portfolios.test.js
│   │   ├── services/
│   │   │   ├── backtesting.test.js
│   │   │   ├── signal-generation.test.js
│   │   │   └── sandbox.test.js
│   │   └── utils/
│   │       ├── validation.test.js
│   │       └── encryption.test.js
│   ├── integration/
│   │   ├── api-flow.test.js
│   │   └── database.test.js
│   └── fixtures/
│       ├── sample-logics.js
│       └── test-data.json
└── jest.config.js
```

### 빌드 및 배포 단위 테스트 필수화

**CI/CD 파이프라인 테스트 단계:**

모든 빌드 및 배포 프로세스에서 단위 테스트 통과가 필수 조건입니다.

**GitHub Actions 워크플로우 예시:**

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test
          POSTGRES_DB: signal_factory_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run unit tests
        run: npm run test:unit
        env:
          DATABASE_URL: postgresql://postgres:test@localhost:5432/signal_factory_test
          REDIS_URL: redis://localhost:6379

      - name: Run integration tests
        run: npm run test:integration
        env:
          DATABASE_URL: postgresql://postgres:test@localhost:5432/signal_factory_test
          REDIS_URL: redis://localhost:6379

      - name: Generate coverage report
        run: npm run test:coverage

      - name: Check coverage thresholds
        run: |
          npm run test:coverage -- --coverageThreshold='{"global":{"branches":80,"functions":85,"lines":85,"statements":85}}'

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/coverage-final.json
          fail_ci_if_error: true

  build:
    name: Build Application
    needs: test  # 테스트 통과 필수
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Build Docker image
        run: docker build -t signal-factory:${{ github.sha }} .

  deploy-staging:
    name: Deploy to Staging
    needs: build  # 빌드 성공 필수
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    
    steps:
      - name: Deploy to staging
        run: |
          # 스테이징 배포 스크립트
          echo "Deploying to staging..."

      - name: Run smoke tests
        run: npm run test:smoke -- --env=staging

  deploy-production:
    name: Deploy to Production
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Deploy to production
        run: |
          # 프로덕션 배포 스크립트
          echo "Deploying to production..."

      - name: Run smoke tests
        run: npm run test:smoke -- --env=production

      - name: Notify deployment
        run: |
          # Slack 알림 등
          echo "Deployment completed"
```

**테스트 실패 시 배포 차단:**

```javascript
// jest.config.js
module.exports = {
  testEnvironment: 'node',
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 85,
      lines: 85,
      statements: 85
    },
    './src/api/': {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    },
    './src/services/': {
      branches: 90,
      functions: 90,
      lines: 90,
      statements: 90
    },
    './src/security/': {
      branches: 95,
      functions: 95,
      lines: 95,
      statements: 95
    }
  },
  collectCoverageFrom: [
    'src/**/*.{js,ts}',
    '!src/**/*.d.ts',
    '!src/**/index.{js,ts}',
    '!src/**/*.mock.{js,ts}'
  ],
  testMatch: [
    '**/tests/**/*.test.{js,ts}',
    '**/__tests__/**/*.{js,ts}'
  ]
};
```

**Pre-commit Hook:**

```bash
# .husky/pre-commit
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

echo "🧪 Running pre-commit tests..."

# Lint staged files
npm run lint-staged

# Run unit tests for changed files
npm run test:changed

if [ $? -ne 0 ]; then
  echo "❌ Tests failed. Commit aborted."
  exit 1
fi

echo "✅ All tests passed. Proceeding with commit."
```

**Package.json 스크립트:**

```json
{
  "scripts": {
    "test": "jest",
    "test:unit": "jest --testPathPattern=tests/unit",
    "test:integration": "jest --testPathPattern=tests/integration",
    "test:coverage": "jest --coverage",
    "test:changed": "jest --changedSince=HEAD --coverage",
    "test:watch": "jest --watch",
    "test:smoke": "jest --testPathPattern=tests/smoke",
    "lint": "eslint src tests --ext .js,.ts",
    "lint-staged": "lint-staged"
  }
}
```

### 프론트엔드 단위 테스트

**테스트 프레임워크:**
- **Jest**: 테스트 러너
- **React Testing Library**: React 컴포넌트 테스트
- **MSW (Mock Service Worker)**: API 모킹
- **jest-dom**: DOM 검증 확장
- **user-event**: 사용자 상호작용 시뮬레이션

**테스트 대상 및 접근 방법:**

1. **컴포넌트 테스트**
   - 렌더링 검증
   - 사용자 상호작용 (클릭, 입력 등)
   - 상태 변화 확인
   - 조건부 렌더링

2. **커스텀 훅 테스트**
   - 상태 관리 로직
   - 사이드 이펙트
   - 의존성 배열

3. **유틸리티 함수 테스트**
   - 순수 함수 검증
   - 엣지 케이스 처리
   - 데이터 변환 로직

**프론트엔드 테스트 예시:**

```typescript
// tests/components/LogicEditor.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { LogicEditor } from '@/components/LogicEditor';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false }
    }
  });

  return ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
};

describe('LogicEditor', () => {
  it('should render editor with default code', () => {
    render(<LogicEditor />, { wrapper: createWrapper() });
    
    expect(screen.getByRole('textbox')).toBeInTheDocument();
    expect(screen.getByText(/function generateSignal/i)).toBeInTheDocument();
  });

  it('should update code on user input', async () => {
    const user = userEvent.setup();
    render(<LogicEditor />, { wrapper: createWrapper() });
    
    const editor = screen.getByRole('textbox');
    await user.clear(editor);
    await user.type(editor, 'const newCode = "test";');
    
    expect(editor).toHaveValue('const newCode = "test";');
  });

  it('should show validation errors for invalid code', async () => {
    const user = userEvent.setup();
    render(<LogicEditor />, { wrapper: createWrapper() });
    
    const editor = screen.getByRole('textbox');
    await user.clear(editor);
    await user.type(editor, 'require("fs")');
    
    await waitFor(() => {
      expect(screen.getByText(/forbidden pattern/i)).toBeInTheDocument();
    });
  });

  it('should save logic on save button click', async () => {
    const user = userEvent.setup();
    const onSave = jest.fn();
    
    render(<LogicEditor onSave={onSave} />, { wrapper: createWrapper() });
    
    const saveButton = screen.getByRole('button', { name: /save/i });
    await user.click(saveButton);
    
    expect(onSave).toHaveBeenCalled();
  });
});

// tests/components/BacktestResults.test.tsx
import { render, screen } from '@testing-library/react';
import { BacktestResults } from '@/components/BacktestResults';
import { server } from '@/mocks/server';
import { rest } from 'msw';

describe('BacktestResults', () => {
  it('should display loading state', () => {
    render(<BacktestResults backtestId="test-id" />);
    
    expect(screen.getByText(/loading/i)).toBeInTheDocument();
  });

  it('should display backtest results', async () => {
    render(<BacktestResults backtestId="test-id" />);
    
    await waitFor(() => {
      expect(screen.getByText(/total return/i)).toBeInTheDocument();
    });
    
    expect(screen.getByText(/15.0%/i)).toBeInTheDocument();
    expect(screen.getByText(/sharpe ratio/i)).toBeInTheDocument();
  });

  it('should handle error state', async () => {
    server.use(
      rest.get('/api/v1/backtests/:id', (req, res, ctx) => {
        return res(ctx.status(500), ctx.json({ error: 'Server error' }));
      })
    );

    render(<BacktestResults backtestId="test-id" />);
    
    await waitFor(() => {
      expect(screen.getByText(/error/i)).toBeInTheDocument();
    });
  });
});

// tests/hooks/useWebSocket.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { useWebSocket } from '@/hooks/useWebSocket';
import WS from 'jest-websocket-mock';

describe('useWebSocket', () => {
  let server: WS;

  beforeEach(() => {
    server = new WS('ws://localhost:1234/signals');
  });

  afterEach(() => {
    WS.clean();
  });

  it('should connect to WebSocket', async () => {
    const { result } = renderHook(() => 
      useWebSocket('ws://localhost:1234/signals')
    );

    await server.connected;
    
    expect(result.current.isConnected).toBe(true);
  });

  it('should receive messages', async () => {
    const { result } = renderHook(() => 
      useWebSocket('ws://localhost:1234/signals')
    );

    await server.connected;
    
    server.send(JSON.stringify({ type: 'SIGNAL', data: { action: 'BUY' } }));
    
    await waitFor(() => {
      expect(result.current.data).toEqual({ 
        type: 'SIGNAL', 
        data: { action: 'BUY' } 
      });
    });
  });
});

// tests/utils/formatters.test.ts
import { formatCurrency, formatPercent } from '@/utils/formatters';

describe('Formatters', () => {
  describe('formatCurrency', () => {
    it('should format positive numbers', () => {
      expect(formatCurrency(1234.56)).toBe('$1,234.56');
    });

    it('should format negative numbers', () => {
      expect(formatCurrency(-1234.56)).toBe('-$1,234.56');
    });

    it('should handle zero', () => {
      expect(formatCurrency(0)).toBe('$0.00');
    });
  });

  describe('formatPercent', () => {
    it('should format decimal as percentage', () => {
      expect(formatPercent(0.1234)).toBe('12.34%');
    });

    it('should handle negative percentages', () => {
      expect(formatPercent(-0.05)).toBe('-5.00%');
    });
  });
});
```

**MSW 설정 (API 모킹):**

```typescript
// src/mocks/handlers.ts
import { rest } from 'msw';

export const handlers = [
  rest.get('/api/v1/backtests/:id', (req, res, ctx) => {
    return res(
      ctx.json({
        backtest: {
          id: req.params.id,
          status: 'completed',
          summary: {
            totalReturn: 0.15,
            annualizedReturn: 0.18,
            sharpeRatio: 1.5,
            maxDrawdown: 0.08
          }
        }
      })
    );
  }),

  rest.get('/api/v1/logics', (req, res, ctx) => {
    return res(
      ctx.json({
        logics: [
          { id: '1', name: 'Strategy 1', createdAt: '2025-01-01' },
          { id: '2', name: 'Strategy 2', createdAt: '2025-01-02' }
        ],
        pagination: { page: 1, total: 2 }
      })
    );
  })
];

// src/mocks/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

// tests/setup.ts
import '@testing-library/jest-dom';
import { server } from '@/mocks/server';

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

**E2E 테스트 (Playwright):**

```typescript
// e2e/logic-workflow.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Logic Creation Workflow', () => {
  test('should create a new logic end-to-end', async ({ page }) => {
    // 로그인
    await page.goto('/login');
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'password');
    await page.click('button[type="submit"]');

    // 로직 페이지로 이동
    await page.goto('/logics/new');

    // 로직 작성
    await page.fill('[name="name"]', 'Test Strategy');
    await page.fill('[name="description"]', 'E2E test strategy');
    
    const editor = page.locator('.monaco-editor');
    await editor.click();
    await page.keyboard.type('function generateSignal(input) { return "BUY"; }');

    // 저장
    await page.click('button:has-text("Save")');

    // 성공 메시지 확인
    await expect(page.locator('.success-message')).toBeVisible();
    
    // 리스트에서 확인
    await page.goto('/logics');
    await expect(page.locator('text=Test Strategy')).toBeVisible();
  });
});
```

### 외부 API 독립 사용을 위한 토큰 발행

**API 토큰 인증 시스템:**

Signal Factory API를 외부 애플리케이션에서 독립적으로 사용하기 위한 토큰 기반 인증 시스템을 제공합니다.

**토큰 유형:**

1. **개인 액세스 토큰 (Personal Access Token)**
   - 사용자 계정에 연결된 장기 토큰
   - 특정 스코프와 권한 설정 가능
   - 만료 기간 설정 가능 (30일, 90일, 1년, 무제한)

2. **서비스 계정 토큰 (Service Account Token)**
   - 특정 서비스/애플리케이션용 토큰
   - 사용자 계정과 독립적
   - 엔터프라이즈 티어 전용

3. **임시 토큰 (Temporary Token)**
   - 단기간 사용을 위한 토큰
   - 제한된 스코프
   - 24시간 후 자동 만료

**토큰 발행 프로세스:**

**1. 웹 UI를 통한 토큰 생성:**

```
사용자 로그인 → 설정 → API 토큰 → 새 토큰 생성
```

**토큰 생성 화면 구성:**
- 토큰 이름/설명 입력
- 권한 스코프 선택 (read:logics, write:logics, read:signals, execute:backtests 등)
- 만료 기간 설정
- IP 화이트리스트 (선택사항)

**2. API를 통한 토큰 생성:**

```bash
# 토큰 생성
POST /api/v1/tokens
Authorization: Bearer <existing-jwt-token>
Content-Type: application/json

{
  "name": "My External App Token",
  "description": "Token for automated trading bot",
  "scopes": ["read:signals", "write:orders"],
  "expiresIn": "90d",
  "ipWhitelist": ["203.0.113.0/24"]
}

# Response
{
  "token": {
    "id": "token_abc123xyz",
    "token": "sfact_1a2b3c4d5e6f7g8h9i0j", 
    "name": "My External App Token",
    "scopes": ["read:signals", "write:orders"],
    "createdAt": "2025-01-15T10:00:00Z",
    "expiresAt": "2025-04-15T10:00:00Z"
  }
}
```

⚠️ **중요**: 토큰은 생성 시 단 한 번만 표시되며, 이후 조회 불가능합니다. 안전한 곳에 보관하세요.

**3. 토큰 관리 API:**

```bash
# 토큰 목록 조회
GET /api/v1/tokens
Authorization: Bearer <jwt-token>

# Response
{
  "tokens": [
    {
      "id": "token_abc123xyz",
      "name": "My External App Token",
      "scopes": ["read:signals", "write:orders"],
      "lastUsed": "2025-01-14T15:30:00Z",
      "createdAt": "2025-01-15T10:00:00Z",
      "expiresAt": "2025-04-15T10:00:00Z"
    }
  ]
}

# 토큰 상세 조회
GET /api/v1/tokens/:tokenId
Authorization: Bearer <jwt-token>

# 토큰 폐기
DELETE /api/v1/tokens/:tokenId
Authorization: Bearer <jwt-token>

# 토큰 스코프 업데이트
PATCH /api/v1/tokens/:tokenId
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "scopes": ["read:signals", "read:logics"]
}
```

**토큰 사용 예시:**

```bash
# HTTP Header를 통한 인증
curl -X GET https://api.signal-factory.com/api/v1/signals/realtime \
  -H "Authorization: Bearer sfact_1a2b3c4d5e6f7g8h9i0j" \
  -H "Content-Type: application/json"

# Python 예시
import requests

API_TOKEN = "sfact_1a2b3c4d5e6f7g8h9i0j"
BASE_URL = "https://api.signal-factory.com/api/v1"

headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

# 실시간 신호 조회
response = requests.get(
    f"{BASE_URL}/signals/realtime",
    headers=headers,
    params={"portfolioId": "portfolio-123"}
)

signals = response.json()

# JavaScript/Node.js 예시
const axios = require('axios');

const API_TOKEN = 'sfact_1a2b3c4d5e6f7g8h9i0j';
const BASE_URL = 'https://api.signal-factory.com/api/v1';

const client = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Authorization': `Bearer ${API_TOKEN}`
  }
});

// 백테스트 실행
async function runBacktest() {
  const response = await client.post('/backtests', {
    portfolioId: 'portfolio-123',
    startDate: '2024-01-01',
    endDate: '2024-12-31',
    initialCash: 10000
  });
  
  return response.data;
}
```

**토큰 스코프 정의:**

| 스코프 | 설명 | 허용 작업 |
|-------|------|----------|
| `read:logics` | 로직 읽기 | GET /logics, GET /logics/:id |
| `write:logics` | 로직 생성/수정 | POST /logics, PUT /logics/:id, DELETE /logics/:id |
| `read:portfolios` | 포트폴리오 읽기 | GET /portfolios, GET /portfolios/:id |
| `write:portfolios` | 포트폴리오 생성/수정 | POST /portfolios, PUT /portfolios/:id |
| `execute:backtests` | 백테스트 실행 | POST /backtests, GET /backtests/:id |
| `read:signals` | 실시간 신호 조회 | GET /signals/realtime, WebSocket 연결 |
| `write:orders` | 주문 실행 (엔터프라이즈) | POST /orders, DELETE /orders/:id |
| `admin` | 관리자 권한 | 모든 API 접근 |

**보안 고려사항:**

1. **토큰 저장:**
   - 데이터베이스에는 해시된 형태로만 저장
   - bcrypt를 사용한 단방향 해싱
   - 원본 토큰은 생성 시점에만 노출

2. **토큰 검증:**
   - 요청마다 토큰 유효성 검증
   - 만료 시간 확인
   - IP 화이트리스트 검증 (설정된 경우)
   - Rate limiting 적용

3. **감사 로깅:**
   - 모든 토큰 사용 기록
   - 비정상적인 사용 패턴 감지
   - 토큰 생성/폐기 이력 보관

**토큰 구현 예시:**

```javascript
// src/services/tokenService.js
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const db = require('../db');

class TokenService {
  async createToken(userId, options) {
    // 토큰 생성 (접두사 + 랜덤 문자열)
    const randomBytes = crypto.randomBytes(32).toString('hex');
    const token = `sfact_${randomBytes}`;
    
    // 토큰 해싱
    const hash = await bcrypt.hash(token, 10);
    
    // DB에 저장
    const record = await db.tokens.create({
      userId,
      tokenHash: hash,
      name: options.name,
      description: options.description,
      scopes: options.scopes,
      expiresAt: this.calculateExpiry(options.expiresIn),
      ipWhitelist: options.ipWhitelist || null
    });
    
    // 원본 토큰은 한 번만 반환
    return { ...record, token };
  }
  
  async validateToken(token, requiredScopes = []) {
    // 모든 활성 토큰 조회
    const tokens = await db.tokens.findActive();
    
    for (const record of tokens) {
      // 토큰 매칭 확인
      const valid = await bcrypt.compare(token, record.tokenHash);
      
      if (valid) {
        // 만료 확인
        if (record.expiresAt && new Date() > record.expiresAt) {
          throw new Error('Token expired');
        }
        
        // 스코프 확인
        if (!this.hasRequiredScopes(record.scopes, requiredScopes)) {
          throw new Error('Insufficient scopes');
        }
        
        // 마지막 사용 시간 업데이트
        await db.tokens.updateLastUsed(record.id);
        
        return record;
      }
    }
    
    throw new Error('Invalid token');
  }
  
  hasRequiredScopes(tokenScopes, requiredScopes) {
    if (tokenScopes.includes('admin')) return true;
    return requiredScopes.every(scope => tokenScopes.includes(scope));
  }
  
  calculateExpiry(expiresIn) {
    if (!expiresIn) return null;
    
    const units = {
      'd': 24 * 60 * 60 * 1000,
      'w': 7 * 24 * 60 * 60 * 1000,
      'm': 30 * 24 * 60 * 60 * 1000,
      'y': 365 * 24 * 60 * 60 * 1000
    };
    
    const match = expiresIn.match(/^(\d+)([dwmy])$/);
    if (!match) throw new Error('Invalid expiry format');
    
    const [, amount, unit] = match;
    return new Date(Date.now() + parseInt(amount) * units[unit]);
  }
  
  async revokeToken(tokenId, userId) {
    return db.tokens.update(tokenId, {
      revokedAt: new Date(),
      revokedBy: userId
    });
  }
}

// Express 미들웨어
function authenticateToken(requiredScopes = []) {
  return async (req, res, next) => {
    const authHeader = req.headers.authorization;
    const token = authHeader?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }
    
    try {
      const tokenRecord = await tokenService.validateToken(token, requiredScopes);
      
      // IP 화이트리스트 확인
      if (tokenRecord.ipWhitelist && tokenRecord.ipWhitelist.length > 0) {
        const clientIp = req.ip;
        if (!this.isIpAllowed(clientIp, tokenRecord.ipWhitelist)) {
          return res.status(403).json({ error: 'IP not allowed' });
        }
      }
      
      req.tokenAuth = {
        userId: tokenRecord.userId,
        tokenId: tokenRecord.id,
        scopes: tokenRecord.scopes
      };
      
      next();
    } catch (error) {
      return res.status(401).json({ error: error.message });
    }
  };
}

// 사용 예
app.get('/api/v1/signals/realtime',
  authenticateToken(['read:signals']),
  async (req, res) => {
    // 토큰 인증된 요청 처리
  }
);
```

**Rate Limiting (토큰별):**

```javascript
class TokenRateLimiter {
  async checkLimit(tokenId, tier) {
    const limits = {
      free: { requests: 100, window: 3600000 }, // 100/hour
      premium: { requests: 1000, window: 3600000 }, // 1000/hour
      enterprise: { requests: -1, window: 0 } // unlimited
    };
    
    const limit = limits[tier];
    if (limit.requests === -1) return; // unlimited
    
    const key = `ratelimit:token:${tokenId}`;
    const count = await redis.incr(key);
    
    if (count === 1) {
      await redis.expire(key, Math.ceil(limit.window / 1000));
    }
    
    if (count > limit.requests) {
      throw new Error('Rate limit exceeded');
    }
  }
}
```

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
11. [기술 스택](./11_tech_stack.md) - 테스트 프레임워크 포함
12. [사용자 워크플로우](./12_user_workflows.md)
13. [비즈니스 모델](./13_business_model.md)
14. [개발 로드맵](./14_roadmap.md)

## 문서 생성 정보

- **생성일**: 2025-11-03
- **버전**: 1.0.0
- **작성 근거**: PROJECT_PLAN.md 전체 분석
- **목적**: 계층적 구조의 상세 기획 문서 체계 구축
