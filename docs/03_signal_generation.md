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
