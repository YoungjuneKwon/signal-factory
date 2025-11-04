# 테스팅 가이드

[← 메인 문서로 돌아가기](./00_overview.md)

## 개요

Signal Factory는 안정적이고 신뢰할 수 있는 서비스 제공을 위해 포괄적인 테스트 전략을 채택합니다. 모든 서버측 컴포넌트와 프론트엔드 컴포넌트는 철저한 단위 테스트를 거쳐야 하며, 빌드 및 배포 프로세스에서 테스트는 필수 단계입니다.

## 테스트 피라미드 전략

```
          ╱╲
         ╱E2E╲         <- 적은 수의 E2E 테스트
        ╱──────╲
       ╱통합테스트╲      <- 중간 수준의 통합 테스트  
      ╱──────────╲
     ╱  단위테스트  ╲    <- 많은 수의 단위 테스트
    ╱──────────────╲
```

### 테스트 비율 가이드
- **단위 테스트**: 70%
- **통합 테스트**: 20%
- **E2E 테스트**: 10%

## 서버측 단위 테스트

### 1. Node.js/TypeScript 백엔드 테스트

#### 테스트 환경 설정

```json
// package.json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:ci": "jest --ci --coverage --maxWorkers=2"
  },
  "devDependencies": {
    "@types/jest": "^29.5.0",
    "@types/supertest": "^2.0.12",
    "jest": "^29.5.0",
    "supertest": "^6.3.3",
    "ts-jest": "^29.1.0",
    "nock": "^13.3.0",
    "@faker-js/faker": "^8.0.0"
  }
}
```

```javascript
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.ts', '**/*.test.ts', '**/*.spec.ts'],
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/__tests__/**',
    '!src/**/index.ts'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  coverageReporters: ['text', 'lcov', 'html'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1'
  },
  setupFilesAfterEnv: ['<rootDir>/src/test/setup.ts']
};
```

#### 서비스 레이어 테스트 예시

```typescript
// src/services/__tests__/logic.service.test.ts
import { LogicService } from '../logic.service';
import { LogicRepository } from '../../repositories/logic.repository';
import { SandboxService } from '../sandbox.service';
import { faker } from '@faker-js/faker';

// Mock 의존성
jest.mock('../../repositories/logic.repository');
jest.mock('../sandbox.service');

describe('LogicService', () => {
  let logicService: LogicService;
  let logicRepository: jest.Mocked<LogicRepository>;
  let sandboxService: jest.Mocked<SandboxService>;

  beforeEach(() => {
    logicRepository = new LogicRepository() as jest.Mocked<LogicRepository>;
    sandboxService = new SandboxService() as jest.Mocked<SandboxService>;
    logicService = new LogicService(logicRepository, sandboxService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('createLogic', () => {
    it('should create a logic with valid code', async () => {
      // Arrange
      const userId = faker.string.uuid();
      const logicData = {
        name: 'Test Strategy',
        code: 'function generateSignal(input) { return "BUY"; }',
        description: 'Test description'
      };

      const expectedLogic = {
        id: faker.string.uuid(),
        ...logicData,
        userId,
        version: 1,
        createdAt: new Date()
      };

      sandboxService.validateCode.mockResolvedValue(true);
      logicRepository.create.mockResolvedValue(expectedLogic);

      // Act
      const result = await logicService.createLogic(userId, logicData);

      // Assert
      expect(sandboxService.validateCode).toHaveBeenCalledWith(logicData.code);
      expect(logicRepository.create).toHaveBeenCalledWith({
        ...logicData,
        userId
      });
      expect(result).toEqual(expectedLogic);
    });

    it('should throw error for invalid code', async () => {
      // Arrange
      const userId = faker.string.uuid();
      const logicData = {
        name: 'Test Strategy',
        code: 'require("fs")', // 금지된 패턴
        description: 'Test description'
      };

      sandboxService.validateCode.mockRejectedValue(
        new Error('Forbidden pattern: require')
      );

      // Act & Assert
      await expect(
        logicService.createLogic(userId, logicData)
      ).rejects.toThrow('Forbidden pattern: require');
      
      expect(logicRepository.create).not.toHaveBeenCalled();
    });
  });

  describe('executeLogic', () => {
    it('should execute logic successfully', async () => {
      // Arrange
      const logicId = faker.string.uuid();
      const inputData = {
        prices: [100, 101, 102],
        volume: [1000, 1100, 1200]
      };

      const logic = {
        id: logicId,
        code: 'function generateSignal(input) { return "BUY"; }'
      };

      const expectedResult = { signal: 'BUY', confidence: 0.8 };

      logicRepository.findById.mockResolvedValue(logic);
      sandboxService.execute.mockResolvedValue(expectedResult);

      // Act
      const result = await logicService.executeLogic(logicId, inputData);

      // Assert
      expect(result).toEqual(expectedResult);
      expect(sandboxService.execute).toHaveBeenCalledWith(
        logic.code,
        inputData
      );
    });

    it('should handle execution timeout', async () => {
      // Arrange
      const logicId = faker.string.uuid();
      const inputData = { prices: [100] };
      const logic = {
        id: logicId,
        code: 'while(true) {}'
      };

      logicRepository.findById.mockResolvedValue(logic);
      sandboxService.execute.mockRejectedValue(
        new Error('Execution timeout')
      );

      // Act & Assert
      await expect(
        logicService.executeLogic(logicId, inputData)
      ).rejects.toThrow('Execution timeout');
    });
  });
});
```

#### API 엔드포인트 테스트 예시

```typescript
// src/routes/__tests__/logics.test.ts
import request from 'supertest';
import { app } from '../../app';
import { LogicService } from '../../services/logic.service';
import { generateToken } from '../../utils/auth';

jest.mock('../../services/logic.service');

describe('POST /api/v1/logics', () => {
  const mockUser = {
    id: 'user-123',
    email: 'test@example.com',
    tier: 'premium'
  };

  const authToken = generateToken(mockUser);

  it('should create a logic when authenticated', async () => {
    // Arrange
    const logicData = {
      name: 'Test Strategy',
      code: 'function generateSignal(input) { return "BUY"; }',
      description: 'Test description'
    };

    const createdLogic = {
      id: 'logic-123',
      ...logicData,
      userId: mockUser.id,
      version: 1
    };

    (LogicService.prototype.createLogic as jest.Mock).mockResolvedValue(
      createdLogic
    );

    // Act
    const response = await request(app)
      .post('/api/v1/logics')
      .set('Authorization', `Bearer ${authToken}`)
      .send(logicData);

    // Assert
    expect(response.status).toBe(201);
    expect(response.body.logic).toEqual(createdLogic);
  });

  it('should return 401 when not authenticated', async () => {
    // Act
    const response = await request(app)
      .post('/api/v1/logics')
      .send({
        name: 'Test',
        code: 'test'
      });

    // Assert
    expect(response.status).toBe(401);
    expect(response.body.error).toBe('No token provided');
  });

  it('should return 400 for invalid input', async () => {
    // Act
    const response = await request(app)
      .post('/api/v1/logics')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        name: '', // 빈 이름
        code: 'test'
      });

    // Assert
    expect(response.status).toBe(400);
    expect(response.body.error).toBeDefined();
  });
});
```

#### 데이터베이스 레이어 테스트 (통합 테스트)

```typescript
// src/repositories/__tests__/logic.repository.test.ts
import { LogicRepository } from '../logic.repository';
import { db } from '../../database';
import { faker } from '@faker-js/faker';

describe('LogicRepository', () => {
  let repository: LogicRepository;

  beforeAll(async () => {
    // 테스트 데이터베이스 연결
    await db.connect();
  });

  afterAll(async () => {
    await db.disconnect();
  });

  beforeEach(async () => {
    // 테스트 전 데이터 초기화
    await db.query('TRUNCATE TABLE logics CASCADE');
    repository = new LogicRepository();
  });

  describe('create', () => {
    it('should create a new logic', async () => {
      // Arrange
      const logicData = {
        name: faker.commerce.productName(),
        code: 'function test() {}',
        userId: faker.string.uuid(),
        description: faker.lorem.sentence()
      };

      // Act
      const result = await repository.create(logicData);

      // Assert
      expect(result.id).toBeDefined();
      expect(result.name).toBe(logicData.name);
      expect(result.version).toBe(1);
    });
  });

  describe('findById', () => {
    it('should return logic by id', async () => {
      // Arrange
      const logic = await repository.create({
        name: 'Test Logic',
        code: 'test',
        userId: faker.string.uuid()
      });

      // Act
      const result = await repository.findById(logic.id);

      // Assert
      expect(result).toBeDefined();
      expect(result?.id).toBe(logic.id);
    });

    it('should return null for non-existent id', async () => {
      // Act
      const result = await repository.findById('non-existent-id');

      // Assert
      expect(result).toBeNull();
    });
  });
});
```

### 2. Python 백엔드 테스트

#### 테스트 환경 설정

```python
# pytest.ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    --verbose
    --cov=src
    --cov-report=html
    --cov-report=term
    --cov-fail-under=80
markers =
    unit: Unit tests
    integration: Integration tests
    slow: Slow running tests
```

```python
# requirements-dev.txt
pytest==7.4.0
pytest-cov==4.1.0
pytest-asyncio==0.21.0
pytest-mock==3.11.1
hypothesis==6.82.0
factory-boy==3.3.0
faker==19.2.0
```

#### 서비스 테스트 예시

```python
# tests/services/test_data_processor.py
import pytest
from unittest.mock import Mock, patch
from src.services.data_processor import DataProcessor
from src.models.tick_data import TickData
from faker import Faker

fake = Faker()

@pytest.fixture
def data_processor():
    return DataProcessor()

@pytest.fixture
def sample_tick_data():
    return TickData(
        symbol='BTCUSDT',
        timestamp=fake.unix_time(),
        open=40000.0,
        high=41000.0,
        low=39000.0,
        close=40500.0,
        volume=1000.0
    )

class TestDataProcessor:
    """데이터 처리 서비스 테스트"""
    
    @pytest.mark.unit
    def test_calculate_moving_average(self, data_processor):
        """이동평균 계산 테스트"""
        # Arrange
        prices = [100, 102, 101, 103, 105]
        period = 3
        
        # Act
        result = data_processor.calculate_moving_average(prices, period)
        
        # Assert
        assert len(result) == 3
        assert result[0] == pytest.approx(101.0)
        assert result[1] == pytest.approx(102.0)
        assert result[2] == pytest.approx(103.0)
    
    @pytest.mark.unit
    def test_calculate_moving_average_insufficient_data(self, data_processor):
        """데이터 부족 시 예외 발생 테스트"""
        # Arrange
        prices = [100, 101]
        period = 3
        
        # Act & Assert
        with pytest.raises(ValueError, match="Insufficient data"):
            data_processor.calculate_moving_average(prices, period)
    
    @pytest.mark.unit
    async def test_process_tick_data(self, data_processor, sample_tick_data):
        """틱 데이터 처리 테스트"""
        # Arrange
        mock_storage = Mock()
        data_processor.storage = mock_storage
        
        # Act
        result = await data_processor.process_tick_data(sample_tick_data)
        
        # Assert
        assert result.symbol == sample_tick_data.symbol
        assert result.normalized is True
        mock_storage.save.assert_called_once()
    
    @pytest.mark.integration
    async def test_fetch_and_process_data(self, data_processor):
        """데이터 조회 및 처리 통합 테스트"""
        # Arrange
        with patch('src.services.data_processor.ExternalAPI') as mock_api:
            mock_api.return_value.fetch_data.return_value = [
                {'price': 100, 'volume': 1000},
                {'price': 101, 'volume': 1100}
            ]
            
            # Act
            result = await data_processor.fetch_and_process_data('BTCUSDT')
            
            # Assert
            assert len(result) == 2
            assert result[0]['price'] == 100
```

#### 속성 기반 테스트 (Hypothesis)

```python
# tests/test_indicators.py
from hypothesis import given, strategies as st
from src.indicators.technical import calculate_rsi

class TestTechnicalIndicators:
    @given(
        prices=st.lists(
            st.floats(min_value=1.0, max_value=100000.0),
            min_size=15,
            max_size=100
        ),
        period=st.integers(min_value=2, max_value=14)
    )
    def test_rsi_always_between_0_and_100(self, prices, period):
        """RSI는 항상 0과 100 사이 값이어야 함"""
        # Act
        rsi_values = calculate_rsi(prices, period)
        
        # Assert
        for rsi in rsi_values:
            assert 0 <= rsi <= 100
    
    @given(
        prices=st.lists(
            st.floats(min_value=1.0, max_value=100000.0),
            min_size=20,
            max_size=100
        )
    )
    def test_moving_average_smooths_data(self, prices):
        """이동평균은 원본 데이터보다 변동성이 작아야 함"""
        from src.indicators.technical import calculate_ma
        
        # Act
        ma = calculate_ma(prices, period=5)
        
        # Assert
        original_variance = sum((p - sum(prices)/len(prices))**2 for p in prices)
        ma_variance = sum((m - sum(ma)/len(ma))**2 for m in ma)
        
        assert ma_variance <= original_variance
```

## 프론트엔드 단위 테스트

### 1. React 웹 애플리케이션 테스트

#### 테스트 환경 설정

```json
// package.json
{
  "scripts": {
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage"
  },
  "devDependencies": {
    "@testing-library/react": "^14.0.0",
    "@testing-library/jest-dom": "^6.1.0",
    "@testing-library/user-event": "^14.5.0",
    "vitest": "^1.0.0",
    "@vitest/ui": "^1.0.0",
    "@vitest/coverage-v8": "^1.0.0",
    "msw": "^2.0.0",
    "jsdom": "^23.0.0"
  }
}
```

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './src/test/setup.ts',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: [
        'node_modules/',
        'src/test/',
        '**/*.d.ts',
        '**/*.config.*',
        '**/mockData',
        'src/main.tsx'
      ],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80
      }
    }
  }
});
```

#### React 컴포넌트 테스트 예시

```typescript
// src/components/__tests__/LogicEditor.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { LogicEditor } from '../LogicEditor';
import { vi } from 'vitest';

describe('LogicEditor', () => {
  it('renders editor with initial code', () => {
    // Arrange
    const initialCode = 'function generateSignal() {}';
    
    // Act
    render(<LogicEditor initialCode={initialCode} />);
    
    // Assert
    expect(screen.getByRole('textbox')).toHaveValue(initialCode);
  });

  it('calls onSave when save button is clicked', async () => {
    // Arrange
    const user = userEvent.setup();
    const mockOnSave = vi.fn();
    const code = 'function test() {}';
    
    render(<LogicEditor initialCode={code} onSave={mockOnSave} />);
    
    // Act
    const saveButton = screen.getByRole('button', { name: /save/i });
    await user.click(saveButton);
    
    // Assert
    await waitFor(() => {
      expect(mockOnSave).toHaveBeenCalledWith(code);
    });
  });

  it('shows validation error for invalid code', async () => {
    // Arrange
    const user = userEvent.setup();
    const invalidCode = 'require("fs")';
    
    render(<LogicEditor initialCode="" />);
    
    // Act
    const editor = screen.getByRole('textbox');
    await user.clear(editor);
    await user.type(editor, invalidCode);
    
    const validateButton = screen.getByRole('button', { name: /validate/i });
    await user.click(validateButton);
    
    // Assert
    expect(await screen.findByText(/forbidden pattern/i)).toBeInTheDocument();
  });

  it('displays loading state during validation', async () => {
    // Arrange
    const user = userEvent.setup();
    render(<LogicEditor initialCode="test" />);
    
    // Act
    const validateButton = screen.getByRole('button', { name: /validate/i });
    await user.click(validateButton);
    
    // Assert
    expect(screen.getByText(/validating/i)).toBeInTheDocument();
  });
});
```

#### 커스텀 훅 테스트

```typescript
// src/hooks/__tests__/useLogics.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useLogics } from '../useLogics';
import { server } from '../../test/mocks/server';
import { http, HttpResponse } from 'msw';
import { ReactNode } from 'react';

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false }
    }
  });
  
  return ({ children }: { children: ReactNode }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
};

describe('useLogics', () => {
  it('fetches logics successfully', async () => {
    // Arrange
    const mockLogics = [
      { id: '1', name: 'Strategy 1' },
      { id: '2', name: 'Strategy 2' }
    ];

    server.use(
      http.get('/api/v1/logics', () => {
        return HttpResponse.json({ logics: mockLogics });
      })
    );

    // Act
    const { result } = renderHook(() => useLogics(), {
      wrapper: createWrapper()
    });

    // Assert
    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });
    expect(result.current.data).toEqual(mockLogics);
  });

  it('handles error when fetching logics fails', async () => {
    // Arrange
    server.use(
      http.get('/api/v1/logics', () => {
        return HttpResponse.json(
          { error: 'Server error' },
          { status: 500 }
        );
      })
    );

    // Act
    const { result } = renderHook(() => useLogics(), {
      wrapper: createWrapper()
    });

    // Assert
    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });
  });
});
```

#### API 모킹 (MSW)

```typescript
// src/test/mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  // 로직 목록 조회
  http.get('/api/v1/logics', () => {
    return HttpResponse.json({
      logics: [
        {
          id: '1',
          name: 'Test Strategy',
          description: 'Test description',
          createdAt: '2025-01-01T00:00:00Z'
        }
      ],
      pagination: {
        page: 1,
        limit: 20,
        total: 1,
        pages: 1
      }
    });
  }),

  // 로직 생성
  http.post('/api/v1/logics', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json(
      {
        logic: {
          id: '2',
          ...body,
          version: 1,
          createdAt: new Date().toISOString()
        }
      },
      { status: 201 }
    );
  }),

  // 로직 실행 (백테스트)
  http.post('/api/v1/backtests', () => {
    return HttpResponse.json(
      {
        backtest: {
          id: 'bt-1',
          status: 'pending',
          createdAt: new Date().toISOString()
        }
      },
      { status: 202 }
    );
  })
];
```

```typescript
// src/test/mocks/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);
```

```typescript
// src/test/setup.ts
import '@testing-library/jest-dom';
import { server } from './mocks/server';

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

### 2. React Native/Expo 모바일 앱 테스트

#### 테스트 환경 설정

```json
// package.json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  },
  "devDependencies": {
    "@testing-library/react-native": "^12.0.0",
    "@testing-library/jest-native": "^5.4.0",
    "jest-expo": "^50.0.0",
    "react-test-renderer": "18.2.0"
  },
  "jest": {
    "preset": "jest-expo",
    "transformIgnorePatterns": [
      "node_modules/(?!((jest-)?react-native|@react-native(-community)?)|expo(nent)?|@expo(nent)?/.*|@expo-google-fonts/.*|react-navigation|@react-navigation/.*|@unimodules/.*|unimodules|sentry-expo|native-base|react-native-svg)"
    ],
    "collectCoverageFrom": [
      "src/**/*.{ts,tsx}",
      "!src/**/*.d.ts",
      "!src/**/__tests__/**"
    ],
    "setupFilesAfterEnv": ["<rootDir>/jest-setup.ts"]
  }
}
```

```typescript
// jest-setup.ts
import '@testing-library/jest-native/extend-expect';

// Mock AsyncStorage
jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock')
);

// Mock Expo modules
jest.mock('expo-notifications', () => ({
  getPermissionsAsync: jest.fn(),
  requestPermissionsAsync: jest.fn()
}));
```

#### 모바일 컴포넌트 테스트 예시

```typescript
// src/screens/__tests__/LogicListScreen.test.tsx
import { render, screen, waitFor } from '@testing-library/react-native';
import { LogicListScreen } from '../LogicListScreen';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { NavigationContainer } from '@react-navigation/native';

const createTestQueryClient = () => {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false }
    }
  });
};

const renderWithProviders = (component: React.ReactElement) => {
  const queryClient = createTestQueryClient();
  
  return render(
    <QueryClientProvider client={queryClient}>
      <NavigationContainer>
        {component}
      </NavigationContainer>
    </QueryClientProvider>
  );
};

describe('LogicListScreen', () => {
  it('renders logic list', async () => {
    // Arrange & Act
    renderWithProviders(<LogicListScreen />);
    
    // Assert
    expect(screen.getByText(/my strategies/i)).toBeOnScreen();
    
    await waitFor(() => {
      expect(screen.getByText('Test Strategy')).toBeOnScreen();
    });
  });

  it('shows empty state when no logics', async () => {
    // Mock empty response
    global.fetch = jest.fn(() =>
      Promise.resolve({
        ok: true,
        json: async () => ({ logics: [] })
      })
    ) as jest.Mock;

    // Act
    renderWithProviders(<LogicListScreen />);
    
    // Assert
    await waitFor(() => {
      expect(screen.getByText(/no strategies yet/i)).toBeOnScreen();
    });
  });
});
```

## CI/CD 파이프라인 통합

### GitHub Actions 워크플로우

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  # 백엔드 Node.js 테스트
  backend-node-test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: signal_factory_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
      
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: backend/package-lock.json
      
      - name: Install dependencies
        working-directory: backend
        run: npm ci
      
      - name: Run linter
        working-directory: backend
        run: npm run lint
      
      - name: Run type check
        working-directory: backend
        run: npm run type-check
      
      - name: Run unit tests
        working-directory: backend
        run: npm run test:ci
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/signal_factory_test
          REDIS_URL: redis://localhost:6379
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./backend/coverage/lcov.info
          flags: backend
          name: backend-coverage
      
      - name: Check coverage threshold
        working-directory: backend
        run: |
          COVERAGE=$(npm run test:coverage --silent | grep "All files" | awk '{print $10}' | sed 's/%//')
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage $COVERAGE% is below 80%"
            exit 1
          fi

  # 백엔드 Python 테스트
  backend-python-test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
          cache: 'pip'
      
      - name: Install dependencies
        working-directory: data-processor
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
      
      - name: Run linter
        working-directory: data-processor
        run: |
          flake8 src tests
          black --check src tests
          mypy src
      
      - name: Run tests
        working-directory: data-processor
        run: pytest -v --cov=src --cov-report=xml --cov-report=term
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./data-processor/coverage.xml
          flags: data-processor
          name: python-coverage

  # 프론트엔드 웹 테스트
  frontend-web-test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: web/package-lock.json
      
      - name: Install dependencies
        working-directory: web
        run: npm ci
      
      - name: Run linter
        working-directory: web
        run: npm run lint
      
      - name: Run type check
        working-directory: web
        run: npm run type-check
      
      - name: Run unit tests
        working-directory: web
        run: npm run test:coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./web/coverage/lcov.info
          flags: frontend-web
          name: web-coverage

  # 모바일 앱 테스트
  mobile-test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: mobile/package-lock.json
      
      - name: Install dependencies
        working-directory: mobile
        run: npm ci
      
      - name: Run linter
        working-directory: mobile
        run: npm run lint
      
      - name: Run tests
        working-directory: mobile
        run: npm run test:coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./mobile/coverage/lcov.info
          flags: mobile
          name: mobile-coverage

  # E2E 테스트
  e2e-test:
    runs-on: ubuntu-latest
    needs: [backend-node-test, frontend-web-test]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Install Playwright
        run: npx playwright install --with-deps
      
      - name: Start services
        run: |
          docker-compose -f docker-compose.test.yml up -d
          npm run wait-for-services
      
      - name: Run E2E tests
        run: npm run test:e2e
      
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30

  # 테스트 결과 필수 체크
  test-required:
    runs-on: ubuntu-latest
    needs: [backend-node-test, backend-python-test, frontend-web-test, mobile-test]
    if: always()
    
    steps:
      - name: Check test results
        run: |
          if [[ "${{ needs.backend-node-test.result }}" != "success" ]] ||
             [[ "${{ needs.backend-python-test.result }}" != "success" ]] ||
             [[ "${{ needs.frontend-web-test.result }}" != "success" ]] ||
             [[ "${{ needs.mobile-test.result }}" != "success" ]]; then
            echo "One or more test jobs failed"
            exit 1
          fi
          echo "All tests passed successfully"
```

### Pre-commit Hooks (Husky)

```json
// package.json
{
  "scripts": {
    "prepare": "husky install"
  },
  "devDependencies": {
    "husky": "^8.0.3",
    "lint-staged": "^14.0.0"
  },
  "lint-staged": {
    "*.{ts,tsx}": [
      "eslint --fix",
      "prettier --write",
      "vitest related --run"
    ],
    "*.{py}": [
      "black",
      "flake8",
      "pytest --testmon"
    ]
  }
}
```

```bash
# .husky/pre-commit
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# Lint staged files
npx lint-staged

# Run affected tests
npm run test:affected
```

```bash
# .husky/pre-push
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# Run all tests before push
npm run test:all

# Check coverage threshold
npm run test:coverage:check
```

## 테스트 자동화 및 모니터링

### 커버리지 추적

```yaml
# codecov.yml
coverage:
  status:
    project:
      default:
        target: 80%
        threshold: 1%
    patch:
      default:
        target: 90%
  
  ignore:
    - "src/test"
    - "**/__tests__"
    - "**/*.test.ts"
    - "**/*.spec.ts"
    - "**/mockData"

comment:
  layout: "header, diff, files"
  behavior: default
```

### 테스트 리포팅

```typescript
// jest.config.js
module.exports = {
  reporters: [
    'default',
    [
      'jest-junit',
      {
        outputDirectory: './test-results',
        outputName: 'junit.xml',
        classNameTemplate: '{classname}',
        titleTemplate: '{title}',
        ancestorSeparator: ' › ',
        usePathForSuiteName: true
      }
    ],
    [
      'jest-html-reporters',
      {
        publicPath: './test-results/html',
        filename: 'report.html',
        expand: true
      }
    ]
  ]
};
```

## 테스트 베스트 프랙티스

### 1. AAA 패턴 (Arrange-Act-Assert)

```typescript
it('should calculate total price correctly', () => {
  // Arrange - 테스트 준비
  const items = [
    { price: 100, quantity: 2 },
    { price: 50, quantity: 1 }
  ];
  
  // Act - 실행
  const total = calculateTotal(items);
  
  // Assert - 검증
  expect(total).toBe(250);
});
```

### 2. 테스트 격리

```typescript
describe('UserService', () => {
  let service: UserService;
  let mockRepository: jest.Mocked<UserRepository>;
  
  beforeEach(() => {
    // 각 테스트마다 새로운 인스턴스 생성
    mockRepository = createMockRepository();
    service = new UserService(mockRepository);
  });
  
  afterEach(() => {
    // 테스트 후 정리
    jest.clearAllMocks();
  });
});
```

### 3. 의미 있는 테스트 이름

```typescript
// ❌ 나쁜 예
it('test1', () => { ... });
it('should work', () => { ... });

// ✅ 좋은 예
it('should return user when valid id is provided', () => { ... });
it('should throw error when user is not found', () => { ... });
it('should update user email and send confirmation', () => { ... });
```

### 4. 테스트 데이터 팩토리 사용

```typescript
// test/factories/user.factory.ts
import { faker } from '@faker-js/faker';

export const createUser = (overrides = {}) => ({
  id: faker.string.uuid(),
  email: faker.internet.email(),
  name: faker.person.fullName(),
  tier: 'free',
  createdAt: new Date(),
  ...overrides
});

// 사용
const user = createUser({ tier: 'premium' });
```

### 5. 경계값 테스트

```typescript
describe('validatePortfolioWeights', () => {
  it('should accept weights summing to 1.0', () => {
    expect(validateWeights([0.5, 0.3, 0.2])).toBe(true);
  });
  
  it('should reject weights summing to less than 1.0', () => {
    expect(validateWeights([0.4, 0.3, 0.2])).toBe(false);
  });
  
  it('should reject weights summing to more than 1.0', () => {
    expect(validateWeights([0.6, 0.3, 0.2])).toBe(false);
  });
  
  it('should reject negative weights', () => {
    expect(validateWeights([-0.1, 0.6, 0.5])).toBe(false);
  });
  
  it('should handle empty array', () => {
    expect(validateWeights([])).toBe(false);
  });
});
```

## 관련 문서

- [기술 스택](./11_tech_stack.md)
- [배포 및 운영](./08_deployment.md)
- [API 명세](./09_api_specifications.md)

[← 메인 문서로 돌아가기](./00_overview.md)
