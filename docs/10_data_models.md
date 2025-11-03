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
