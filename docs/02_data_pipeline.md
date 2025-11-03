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
