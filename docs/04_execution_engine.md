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
