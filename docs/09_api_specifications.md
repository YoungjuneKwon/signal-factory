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
