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

## API 키 관리 (외부 API 단독 사용)

### API 키 발행 프로세스

외부 시스템에서 Signal Factory API를 독립적으로 사용하기 위한 API 키 발행 및 관리 프로세스입니다.

#### 1. API 키 발행

**POST /api/v1/api-keys**

외부 애플리케이션을 위한 API 키를 생성합니다.

**Request:**
```json
{
  "name": "My Trading Bot",
  "description": "자동화된 트레이딩 봇을 위한 API 키",
  "scopes": [
    "logics:read",
    "logics:write",
    "backtests:execute",
    "signals:read"
  ],
  "expiresAt": "2025-12-31T23:59:59Z",
  "ipWhitelist": ["203.0.113.0/24", "198.51.100.10"],
  "rateLimit": {
    "requestsPerHour": 500,
    "requestsPerDay": 10000
  }
}
```

**Response (201):**
```json
{
  "apiKey": {
    "id": "key_2Xhz9K8qLmN4pQrS",
    "key": "sfk_live_example1234567890abcdefghijklmnopqrstuvwxyz",
    "name": "My Trading Bot",
    "description": "자동화된 트레이딩 봇을 위한 API 키",
    "scopes": [
      "logics:read",
      "logics:write",
      "backtests:execute",
      "signals:read"
    ],
    "createdAt": "2025-01-01T00:00:00Z",
    "expiresAt": "2025-12-31T23:59:59Z",
    "lastUsedAt": null
  },
  "warning": "⚠️ API 키는 이 응답에서만 표시됩니다. 안전한 곳에 보관하세요."
}
```

**권한 범위 (Scopes):**

| Scope | 설명 | 필요 등급 |
|-------|------|----------|
| `logics:read` | 로직 조회 | Free+ |
| `logics:write` | 로직 생성/수정/삭제 | Free+ |
| `portfolios:read` | 포트폴리오 조회 | Free+ |
| `portfolios:write` | 포트폴리오 생성/수정/삭제 | Free+ |
| `backtests:execute` | 백테스트 실행 | Free+ |
| `backtests:read` | 백테스트 결과 조회 | Free+ |
| `signals:read` | 실시간 신호 조회 | Premium+ |
| `signals:stream` | 실시간 신호 스트림 (WebSocket) | Premium+ |
| `trades:execute` | 자동 매매 실행 | Enterprise |
| `trades:read` | 거래 내역 조회 | Premium+ |
| `admin:*` | 관리자 권한 | Enterprise |

#### 2. API 키 목록 조회

**GET /api/v1/api-keys**

생성한 API 키 목록을 조회합니다.

**Query Parameters:**
- `status`: 상태 필터 (`active`, `expired`, `revoked`)
- `page`: 페이지 번호 (default: 1)
- `limit`: 페이지 크기 (default: 20)

**Response (200):**
```json
{
  "apiKeys": [
    {
      "id": "key_2Xhz9K8qLmN4pQrS",
      "name": "My Trading Bot",
      "description": "자동화된 트레이딩 봇을 위한 API 키",
      "scopes": ["logics:read", "signals:read"],
      "keyPrefix": "sk_live_51Hxz9...",
      "createdAt": "2025-01-01T00:00:00Z",
      "expiresAt": "2025-12-31T23:59:59Z",
      "lastUsedAt": "2025-01-15T10:30:00Z",
      "status": "active",
      "usage": {
        "requestsToday": 245,
        "requestsThisHour": 45
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 3,
    "pages": 1
  }
}
```

#### 3. API 키 상세 조회

**GET /api/v1/api-keys/:id**

특정 API 키의 상세 정보를 조회합니다.

**Response (200):**
```json
{
  "apiKey": {
    "id": "key_2Xhz9K8qLmN4pQrS",
    "name": "My Trading Bot",
    "description": "자동화된 트레이딩 봇을 위한 API 키",
    "scopes": ["logics:read", "signals:read"],
    "keyPrefix": "sk_live_51Hxz9...",
    "createdAt": "2025-01-01T00:00:00Z",
    "expiresAt": "2025-12-31T23:59:59Z",
    "lastUsedAt": "2025-01-15T10:30:00Z",
    "status": "active",
    "ipWhitelist": ["203.0.113.0/24"],
    "rateLimit": {
      "requestsPerHour": 500,
      "requestsPerDay": 10000
    },
    "usage": {
      "requestsToday": 245,
      "requestsThisHour": 45,
      "totalRequests": 15234
    }
  }
}
```

#### 4. API 키 수정

**PATCH /api/v1/api-keys/:id**

API 키의 설정을 수정합니다. (키 값 자체는 변경 불가)

**Request:**
```json
{
  "name": "Updated Trading Bot",
  "description": "업데이트된 설명",
  "scopes": ["logics:read", "signals:read", "backtests:execute"],
  "ipWhitelist": ["203.0.113.0/24", "198.51.100.0/24"]
}
```

**Response (200):**
```json
{
  "apiKey": {
    "id": "key_2Xhz9K8qLmN4pQrS",
    "name": "Updated Trading Bot",
    "updatedAt": "2025-01-15T10:30:00Z"
  }
}
```

#### 5. API 키 폐기

**DELETE /api/v1/api-keys/:id**

API 키를 즉시 폐기합니다. 폐기된 키는 더 이상 사용할 수 없습니다.

**Response (200):**
```json
{
  "message": "API key revoked successfully",
  "apiKey": {
    "id": "key_2Xhz9K8qLmN4pQrS",
    "status": "revoked",
    "revokedAt": "2025-01-15T10:35:00Z"
  }
}
```

#### 6. API 키 갱신

**POST /api/v1/api-keys/:id/rotate**

보안을 위해 새로운 키로 교체합니다. 기존 키는 24시간 유예 기간 후 자동 폐기됩니다.

**Response (200):**
```json
{
  "apiKey": {
    "id": "key_2Xhz9K8qLmN4pQrS",
    "key": "sfk_live_example9876543210zyxwvutsrqponmlkjihgfedcba",
    "createdAt": "2025-01-15T10:40:00Z"
  },
  "oldKey": {
    "expiresAt": "2025-01-16T10:40:00Z"
  },
  "warning": "⚠️ 이전 키는 24시간 후 자동으로 폐기됩니다. 새 키로 업데이트해주세요."
}
```

### API 키 사용 방법

#### HTTP 헤더를 통한 인증

```bash
curl -X GET https://api.signal-factory.com/api/v1/logics \
  -H "Authorization: Bearer sfk_live_exampleXXXXXXXX..." \
  -H "Content-Type: application/json"
```

#### JavaScript/Node.js 예시

```javascript
const axios = require('axios');

const apiClient = axios.create({
  baseURL: 'https://api.signal-factory.com/api/v1',
  headers: {
    'Authorization': `Bearer ${process.env.SIGNAL_FACTORY_API_KEY}`,
    'Content-Type': 'application/json'
  }
});

// 로직 목록 조회
async function getLogics() {
  try {
    const response = await apiClient.get('/logics');
    return response.data.logics;
  } catch (error) {
    console.error('API Error:', error.response?.data);
    throw error;
  }
}

// 백테스트 실행
async function runBacktest(portfolioId, config) {
  const response = await apiClient.post('/backtests', {
    portfolioId,
    ...config
  });
  return response.data.backtest;
}
```

#### Python 예시

```python
import os
import requests

class SignalFactoryClient:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = 'https://api.signal-factory.com/api/v1'
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        })
    
    def get_logics(self, **params):
        """로직 목록 조회"""
        response = self.session.get(f'{self.base_url}/logics', params=params)
        response.raise_for_status()
        return response.json()['logics']
    
    def create_logic(self, name: str, code: str, **kwargs):
        """로직 생성"""
        payload = {'name': name, 'code': code, **kwargs}
        response = self.session.post(f'{self.base_url}/logics', json=payload)
        response.raise_for_status()
        return response.json()['logic']
    
    def run_backtest(self, portfolio_id: str, config: dict):
        """백테스트 실행"""
        payload = {'portfolioId': portfolio_id, **config}
        response = self.session.post(f'{self.base_url}/backtests', json=payload)
        response.raise_for_status()
        return response.json()['backtest']

# 사용 예시
client = SignalFactoryClient(api_key=os.environ['SIGNAL_FACTORY_API_KEY'])
logics = client.get_logics(limit=10)
```

### API 키 보안 가이드

#### 1. 환경 변수 사용

```bash
# .env 파일
SIGNAL_FACTORY_API_KEY=sfk_live_exampleXXXXXXXX...

# .gitignore에 추가
.env
.env.local
```

#### 2. 최소 권한 원칙

- 필요한 권한만 부여
- 읽기 전용 작업에는 읽기 권한만 부여
- 자동 매매는 별도의 키 사용

```json
// 백테스트 전용 키
{
  "scopes": ["logics:read", "backtests:execute", "backtests:read"]
}

// 신호 모니터링 전용 키
{
  "scopes": ["signals:read"]
}

// 자동 매매용 키 (별도 관리)
{
  "scopes": ["signals:read", "trades:execute", "trades:read"]
}
```

#### 3. IP 화이트리스트

```json
{
  "ipWhitelist": [
    "203.0.113.10",          // 특정 IP
    "198.51.100.0/24",       // CIDR 표기법
    "2001:db8::/32"          // IPv6 지원
  ]
}
```

#### 4. 만료 시간 설정

```json
{
  "expiresAt": "2025-12-31T23:59:59Z"  // 정기적 갱신
}
```

#### 5. 키 교체 전략

- **정기 교체**: 3개월마다 키 갱신
- **침해 의심 시**: 즉시 폐기 및 신규 발급
- **감사**: API 키 사용 내역 정기 검토

### API 키 사용량 모니터링

**GET /api/v1/api-keys/:id/usage**

API 키의 상세한 사용량 통계를 조회합니다.

**Query Parameters:**
- `startDate`: 시작 날짜 (ISO 8601)
- `endDate`: 종료 날짜 (ISO 8601)
- `granularity`: 데이터 세분화 (`hour`, `day`, `week`, `month`)

**Response (200):**
```json
{
  "usage": {
    "period": {
      "start": "2025-01-01T00:00:00Z",
      "end": "2025-01-15T23:59:59Z"
    },
    "summary": {
      "totalRequests": 15234,
      "successfulRequests": 14987,
      "failedRequests": 247,
      "averageResponseTime": 145
    },
    "byEndpoint": [
      {
        "endpoint": "/api/v1/logics",
        "method": "GET",
        "count": 5234,
        "avgResponseTime": 120
      },
      {
        "endpoint": "/api/v1/backtests",
        "method": "POST",
        "count": 3421,
        "avgResponseTime": 2340
      }
    ],
    "timeline": [
      {
        "timestamp": "2025-01-01T00:00:00Z",
        "requests": 234,
        "errors": 5
      }
    ],
    "rateLimitHits": 12,
    "topErrors": [
      {
        "code": 429,
        "count": 12,
        "message": "Rate limit exceeded"
      }
    ]
  }
}
```

### Webhook 설정 (선택적)

API 키 이벤트에 대한 알림을 받을 수 있습니다.

**POST /api/v1/api-keys/:id/webhooks**

```json
{
  "url": "https://my-app.com/webhooks/signal-factory",
  "events": [
    "key.approaching_limit",
    "key.rate_limit_exceeded",
    "key.expired",
    "key.suspicious_activity"
  ],
  "secret": "whsec_abc123..."
}
```

**Webhook Payload 예시:**
```json
{
  "event": "key.rate_limit_exceeded",
  "timestamp": "2025-01-15T10:30:00Z",
  "data": {
    "apiKeyId": "key_2Xhz9K8qLmN4pQrS",
    "limit": 500,
    "current": 500,
    "resetAt": "2025-01-15T11:00:00Z"
  }
}
```

[← 메인 문서로 돌아가기](./00_overview.md)
