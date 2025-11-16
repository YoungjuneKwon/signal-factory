# 배포 및 운영

[← 메인 문서로 돌아가기](./00_overview.md)

## 인프라 아키텍처

### 클라우드 제공자
- **AWS**: 주요 인프라 (EC2, ECS, RDS, S3, CloudFront)
- **Vercel**: 프론트엔드 배포 (선택적)
- **Railway/Render**: 작은 서비스 배포 (선택적)

### Kubernetes 클러스터

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: trading-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: trading-service
  template:
    metadata:
      labels:
        app: trading-service
    spec:
      containers:
      - name: trading-service
        image: signal-factory/trading-service:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: trading-service
spec:
  selector:
    app: trading-service
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: LoadBalancer
```

## Serverless 우선 설계

### 원칙

Signal Factory는 **Serverless-first** 아키텍처를 지향하며, 관리형 서비스와 이벤트 기반 패턴을 우선 활용하여 운영 부담을 최소화하고 확장성과 비용 효율성을 극대화합니다.

**핵심 설계 원칙:**

- **Serverless-first 우선순위**: Cloudflare Workers, Pages, Durable Objects, KV, Queues, R2, GitHub Actions cron, managed Time-Series DB 등 관리형 서비스를 기본으로 채택
- **Kubernetes 보완적 활용**: 장기 실행 프로세스, 높은 상태 복잡도, 특수 성능 요구사항이 있는 경우에만 K8s 사용
- **데이터 수명주기 관리**: Hot (실시간 쿼리) ↔ Cool (분석) ↔ Cold (아카이브/P2P/IPFS) 계층화
- **이벤트 기반 느슨한 결합**: Queues/PubSub를 통한 비동기 처리, 최소한의 영구 상태 (Durable Objects는 제한적 범위)
- **다중 리전/벤더 복원력**: 벤더 종속성 최소화 및 지역 분산을 통한 고가용성 확보
- **거버넌스**: 아티팩트 서명, SBOM, 최소 권한 원칙, 비밀 자동 교체

### 기능별 실행/호스팅 모달리티 매핑

| 기능/서브시스템 | 주 실행/호스팅 | 보완 대안 (K8s/Containers) | 자동화/트리거 | 데이터/아티팩트 저장소 | 보안/거버넌스 포인트 |
|---|---|---|---|---|---|
| **실시간 신호 생성** | Cloudflare Workers (Edge) | ECS/K8s (long-running listener) | WebSocket/SSE, Queue trigger | Cloudflare KV (캐시), PostgreSQL (영구) | WASM 격리, Rate limiting, API key rotation |
| **백테스트 실행** | GitHub Actions (cron/manual), Durable Objects (orchestration) | K8s Jobs (대규모 병렬) | cron schedule, Queue (on-demand) | R2 (결과), IPFS (historical data distribution) | Artifact signing, Ephemeral credentials, Audit log |
| **웹 UI 배포** | Cloudflare Pages | Vercel, K8s (static serve) | Git push (main), PR preview | R2/CDN (assets), KV (metadata) | CSP headers, SRI, HTTPS-only |
| **API 서비스** | Cloudflare Workers (stateless), Durable Objects (stateful sessions) | ECS/K8s (complex API) | HTTP request, Queue consumer | PostgreSQL/Neon, KV (cache) | JWT validation, mTLS, Secrets Manager |
| **데이터 수집기** | GitHub Actions cron, Cloudflare Workers (scheduled) | K8s CronJob (high-freq) | cron (hourly/daily), event webhook | TimescaleDB/InfluxDB Cloud, R2 (raw) | Encrypted at rest, Least privilege IAM, Input validation |
| **전략 샌드박스** | Cloudflare Workers (WASM) | K8s (isolated pods) | API call, Queue | Durable Objects (state), R2 (code bundles) | Resource/time limits, Deterministic seeding, Code signing |
| **모바일 API 백엔드** | Cloudflare Workers (global edge) | K8s (regional fallback) | HTTPS/GraphQL | KV (session), PostgreSQL | Auth0/Clerk integration, Rate limiting |
| **일괄 데이터 분석** | GitHub Actions (matrix), Durable Objects (coordination) | K8s Spark/Flink | cron (weekly), manual dispatch | R2 (Parquet), ClickHouse Cloud | SBOM, Environment isolation |
| **아카이브 스냅샷** | GitHub Actions cron | K8s CronJob | cron (daily) | R2 → IPFS (public historical data), Glacier (long-term) | Content hashing, Signature verification |
| **알림/통지** | Cloudflare Queues → Workers | K8s (notification service) | Queue event | KV (subscriptions), R2 (templates) | Encrypted payloads, User consent |
| **메트릭/모니터링** | Prometheus Cloud, Grafana Cloud, Cloudflare Analytics | K8s (Prometheus/Grafana) | scrape interval, push gateway | Managed TSDB (Prometheus Cloud) | Access control, Retention policies |
| **CI/CD 파이프라인** | GitHub Actions | Jenkins on K8s (legacy) | Git push, PR, cron | GitHub Container Registry, R2 (cache) | OIDC auth, Secret scanning, Branch protection |

### 지속 가능성 원칙

- **Serverless-first 선택 로직**:
  - 상태가 없거나 최소 상태 → Cloudflare Workers/GitHub Actions
  - 단기 실행 (<15분), 이벤트 기반 → Serverless 함수
  - 장기 실행, 복잡한 상태 관리 → Durable Objects 또는 K8s (최후 수단)
  - 글로벌 저지연 요구 → Cloudflare Workers (Edge)

- **데이터 수명주기 관리**:
  - **Hot**: 실시간 쿼리 (KV, PostgreSQL, TimescaleDB)
  - **Cool**: 분석/집계 (ClickHouse Cloud, R2 Parquet)
  - **Cold**: 아카이브/공개 배포 (IPFS, Glacier, R2 Infrequent Access)
  - 자동 수명주기 정책 (R2 → IPFS after 90 days)

- **이벤트 구동 &amp; 내결함성 패턴**:
  - Circuit Breaker: 외부 API 실패 시 자동 차단 및 폴백
  - Exponential Backoff: 재시도 간격 증가 (최대 5회)
  - Dead Letter Queue: 실패한 메시지 격리 및 분석
  - Idempotency Keys: 중복 처리 방지

- **멀티 리전/벤더 전략**:
  - Primary: Cloudflare (Edge), GitHub Actions
  - Fallback: AWS (ECS/Lambda), Vercel
  - 데이터: PostgreSQL (Neon multi-region), R2 + IPFS
  - DNS/CDN: Cloudflare with AWS Route53 failover

- **GitOps &amp; 재현성**:
  - 모든 인프라 변경은 PR/GitHub Actions를 통해 추적
  - Terraform/Pulumi로 IaC 관리
  - Docker 이미지 태그 고정 (semantic versioning)
  - 환경별 Config-as-Code (dev/staging/prod)

### 운영 워크플로 예시

#### 1. 실시간 신호 처리

**시나리오**: 사용자가 웹 UI에서 실시간 신호를 구독하면, Edge에서 신호를 생성하여 WebSocket으로 푸시

**흐름**:
1. 사용자가 Cloudflare Pages (Web UI)에서 신호 구독 요청
2. Cloudflare Workers API가 요청을 받아 KV에 구독 정보 저장
3. Durable Object (SignalProcessor)가 WebSocket 연결 유지 및 신호 생성
4. 데이터 수집기 (GitHub Actions cron)가 시장 데이터를 R2 및 PostgreSQL에 저장
5. Durable Object가 새 데이터를 감지하면 신호 계산 실행 (WASM 샌드박스)
6. 계산된 신호를 WebSocket으로 클라이언트에 전송
7. Cloudflare Analytics로 성능 메트릭 수집

**장점**: 글로벌 저지연 (<50ms), 자동 확장, 상태 관리 격리

#### 2. 일괄 백테스트

**시나리오**: 사용자가 과거 데이터로 전략 성능 검증

**흐름**:
1. 사용자가 Web UI에서 백테스트 요청 (날짜 범위, 전략 코드)
2. Cloudflare Workers API가 요청을 Cloudflare Queue에 전송
3. GitHub Actions (manual dispatch)가 Queue 이벤트를 감지하여 백테스트 Job 시작
4. Job이 R2/IPFS에서 historical 데이터 로드 (Parquet 형식)
5. 전략 코드를 WASM으로 컴파일하여 샌드박스 실행 (deterministic seeding)
6. 결과 (성과 지표, 차트)를 R2에 저장하고 아티팩트 서명
7. 결과 URL을 사용자에게 반환 (Cloudflare Workers API)
8. Grafana Cloud에 백테스트 메트릭 (실행 시간, 성공률) 기록

**장점**: 비용 효율적 (cron 기반, on-demand), 재현 가능, 격리된 실행

#### 3. 아카이브 스냅샷 배포

**시나리오**: 일일 시장 데이터 스냅샷을 IPFS에 배포하여 커뮤니티와 공유

**흐름**:
1. GitHub Actions cron (매일 02:00 UTC)이 스냅샷 Job 트리거
2. Job이 PostgreSQL/TimescaleDB에서 전날 데이터 추출
3. Parquet 형식으로 압축 및 SBOM 생성
4. R2에 스냅샷 업로드 (versioning 활성화)
5. IPFS 노드에 스냅샷 고정 (pinning) 및 CID 생성
6. Cloudflare KV에 최신 CID 및 메타데이터 저장
7. Web UI에서 IPFS 게이트웨이 링크 제공 (예: ipfs.io/ipfs/{CID})
8. Slack/Discord 웹훅으로 배포 알림 전송

**장점**: 탈중앙화 배포, 영구 보관, 무료 대역폭 (P2P)

### 전략 샌드박스 실행

**개요**: 사용자 제공 전략 코드를 안전하게 실행하기 위한 격리 환경

**구현**:
- **WASM 격리**: Cloudflare Workers의 V8 Isolate를 활용하여 각 전략을 독립 실행
- **리소스 제한**:
  - CPU 시간: 최대 50ms (실시간), 10초 (백테스트)
  - 메모리: 128MB
  - 네트워크: 차단 (데이터는 사전 제공)
- **시간 제한**: Timeout 설정으로 무한 루프 방지
- **Deterministic Seeding**: 난수 생성 시드 고정으로 백테스트 재현성 보장
- **코드 서명**: 전략 코드 해시를 KV에 저장하여 변경 감지
- **Audit Log**: 모든 실행 로그를 R2에 저장 (사용자별, 전략별)

**예시 코드**:
```javascript
// Cloudflare Worker - 전략 실행 샌드박스
export default {
  async fetch(request, env) {
    const { strategyCode, marketData, seed } = await request.json();
    
    // WASM 모듈 로드 및 실행
    const wasmModule = await WebAssembly.instantiate(strategyCode);
    const result = wasmModule.exports.execute(marketData, seed);
    
    // 결과 저장 및 반환
    await env.RESULTS.put(`result:${Date.now()}`, JSON.stringify(result));
    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
```

### 관련 문서

- [아키텍처 개요](./01_architecture_overview.md) - 전체 시스템 구조 및 마이크로서비스 구성
- [데이터 파이프라인](./02_data_pipeline.md) - 데이터 수집, 정규화, 저장 흐름
- [신호 생성](./03_signal_generation.md) - 신호 로직 엔진 및 백테스트 프레임워크
- [보안](./07_security.md) - 인증, 권한, 암호화, 감사 로그

## CI/CD 파이프라인

### GitHub Actions

#### 필수 테스트 정책

**모든 빌드 및 배포는 반드시 단위 테스트를 통과해야 합니다.**

- ✅ 단위 테스트 커버리지 80% 이상 필수
- ✅ 핵심 비즈니스 로직 90% 이상 필수
- ✅ 테스트 실패 시 빌드 및 배포 차단
- ✅ Pull Request 병합 전 테스트 필수

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  # 단위 테스트 (필수)
  unit-test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [backend, data-processor, web, mobile]
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Node.js
      if: matrix.service != 'data-processor'
      uses: actions/setup-node@v4
      with:
        node-version: '18'
        cache: 'npm'
        cache-dependency-path: ${{ matrix.service }}/package-lock.json
    
    - name: Setup Python
      if: matrix.service == 'data-processor'
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
        cache: 'pip'
    
    - name: Install dependencies (Node.js)
      if: matrix.service != 'data-processor'
      working-directory: ${{ matrix.service }}
      run: npm ci
    
    - name: Install dependencies (Python)
      if: matrix.service == 'data-processor'
      working-directory: ${{ matrix.service }}
      run: |
        pip install -r requirements.txt
        pip install -r requirements-dev.txt
    
    - name: Run linter
      working-directory: ${{ matrix.service }}
      run: npm run lint || (cd ${{ matrix.service }} && flake8 src tests)
    
    - name: Run type check
      if: matrix.service != 'data-processor'
      working-directory: ${{ matrix.service }}
      run: npm run type-check
    
    - name: Run type check (Python)
      if: matrix.service == 'data-processor'
      working-directory: ${{ matrix.service }}
      run: mypy src
    
    # 필수: 단위 테스트 실행 및 커버리지 체크
    - name: Run unit tests with coverage
      working-directory: ${{ matrix.service }}
      run: |
        if [ "${{ matrix.service }}" == "data-processor" ]; then
          pytest -v --cov=src --cov-report=xml --cov-report=term --cov-fail-under=80
        else
          npm run test:ci
        fi
    
    # 필수: 커버리지 임계값 체크
    - name: Check coverage threshold
      working-directory: ${{ matrix.service }}
      run: |
        if [ "${{ matrix.service }}" == "data-processor" ]; then
          COVERAGE=$(coverage report | grep "TOTAL" | awk '{print $4}' | sed 's/%//')
        else
          COVERAGE=$(npm run test:coverage --silent | grep "All files" | awk '{print $10}' | sed 's/%//')
        fi
        
        if (( $(echo "$COVERAGE < 80" | bc -l) )); then
          echo "❌ Coverage $COVERAGE% is below 80% threshold"
          exit 1
        fi
        echo "✅ Coverage $COVERAGE% meets the 80% threshold"
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        files: ./${{ matrix.service }}/coverage/lcov.info,./${{ matrix.service }}/coverage.xml
        flags: ${{ matrix.service }}
        name: ${{ matrix.service }}-coverage
        fail_ci_if_error: true
  
  # 통합 테스트 (필수)
  integration-test:
    runs-on: ubuntu-latest
    needs: unit-test
    
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
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run integration tests
      run: npm run test:integration
      env:
        DATABASE_URL: postgresql://test:test@localhost:5432/signal_factory_test
        REDIS_URL: redis://localhost:6379
        NODE_ENV: test
  
  # 보안 스캔
  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run Snyk security scan
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
    
    - name: Run CodeQL analysis
      uses: github/codeql-action/analyze@v2
  
  # 빌드 (테스트 통과 필수)
  build:
    needs: [unit-test, integration-test, security]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ap-northeast-2
    
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1
    
    - name: Build and push Docker image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        docker build -t $ECR_REGISTRY/signal-factory:$IMAGE_TAG .
        docker push $ECR_REGISTRY/signal-factory:$IMAGE_TAG
        docker tag $ECR_REGISTRY/signal-factory:$IMAGE_TAG $ECR_REGISTRY/signal-factory:latest
        docker push $ECR_REGISTRY/signal-factory:latest
  
  # 배포 (프로덕션 - 모든 테스트 통과 필수)
  deploy-production:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://signal-factory.com
    
    steps:
    - name: Deploy to ECS
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: task-definition.json
        service: signal-factory-service
        cluster: production-cluster
        wait-for-service-stability: true
    
    - name: Run smoke tests
      run: |
        npm run test:smoke:production
    
    - name: Notify deployment
      if: success()
      uses: 8398a7/action-slack@v3
      with:
        status: custom
        custom_payload: |
          {
            text: '✅ Production deployment successful',
            attachments: [{
              color: 'good',
              text: `Commit: ${{ github.sha }}\nAuthor: ${{ github.actor }}`
            }]
          }
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
  
  # 배포 (스테이징)
  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment:
      name: staging
      url: https://staging.signal-factory.com
    
    steps:
    - name: Deploy to ECS (Staging)
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: task-definition.staging.json
        service: signal-factory-staging-service
        cluster: staging-cluster
        wait-for-service-stability: true
```

### 브랜치 보호 규칙

GitHub 리포지토리 설정에서 다음 규칙을 적용합니다:

```yaml
# .github/branch-protection.yml
main:
  required_status_checks:
    strict: true
    contexts:
      - unit-test (backend)
      - unit-test (data-processor)
      - unit-test (web)
      - unit-test (mobile)
      - integration-test
      - security
  required_pull_request_reviews:
    required_approving_review_count: 2
    dismiss_stale_reviews: true
    require_code_owner_reviews: true
  enforce_admins: true
  required_linear_history: false
  allow_force_pushes: false
  allow_deletions: false
  
develop:
  required_status_checks:
    strict: true
    contexts:
      - unit-test (backend)
      - unit-test (data-processor)
      - unit-test (web)
      - unit-test (mobile)
  required_pull_request_reviews:
    required_approving_review_count: 1
```

## 모니터링

### Prometheus + Grafana

```yaml
# prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'trading-service'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - production
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        action: keep
        regex: trading-service
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod
```

### 애플리케이션 메트릭

```javascript
// metrics.js
const prometheus = require('prom-client');

const register = new prometheus.Registry();

// 기본 메트릭
prometheus.collectDefaultMetrics({ register });

// 커스텀 메트릭
const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const logicExecutions = new prometheus.Counter({
  name: 'logic_executions_total',
  help: 'Total number of logic executions',
  labelNames: ['logic_id', 'status']
});

const backtestDuration = new prometheus.Histogram({
  name: 'backtest_duration_seconds',
  help: 'Duration of backtest execution',
  buckets: [1, 5, 10, 30, 60, 120]
});

register.registerMetric(httpRequestDuration);
register.registerMetric(logicExecutions);
register.registerMetric(backtestDuration);

// Express 미들웨어
function metricsMiddleware(req, res, next) {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .observe(duration);
  });
  
  next();
}

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

## 로깅

### Winston Logger

```javascript
const winston = require('winston');
const { ElasticsearchTransport } = require('winston-elasticsearch');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'signal-factory',
    environment: process.env.NODE_ENV
  },
  transports: [
    // Console
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }),
    
    // File
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error'
    }),
    new winston.transports.File({
      filename: 'logs/combined.log'
    }),
    
    // Elasticsearch (Production)
    ...(process.env.NODE_ENV === 'production' ? [
      new ElasticsearchTransport({
        level: 'info',
        clientOpts: {
          node: process.env.ELASTICSEARCH_URL
        },
        index: 'signal-factory-logs'
      })
    ] : [])
  ]
});

module.exports = logger;
```

## 데이터베이스 관리

### 마이그레이션

```javascript
// migrations/001_create_users.js
exports.up = async (knex) => {
  await knex.schema.createTable('users', (table) => {
    table.uuid('id').primary();
    table.string('email').notNullable().unique();
    table.string('name').notNullable();
    table.string('password_hash').notNullable();
    table.enum('tier', ['free', 'premium', 'enterprise']).defaultTo('free');
    table.timestamps(true, true);
  });
};

exports.down = async (knex) => {
  await knex.schema.dropTable('users');
};

// Run migrations
// npx knex migrate:latest
```

### 백업

```bash
#!/bin/bash
# scripts/backup-db.sh

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_${TIMESTAMP}.sql.gz"

# PostgreSQL 백업
pg_dump -h $DB_HOST -U $DB_USER $DB_NAME | gzip > /tmp/$BACKUP_FILE

# S3 업로드
aws s3 cp /tmp/$BACKUP_FILE s3://signal-factory-backups/database/

# 로컬 파일 삭제
rm /tmp/$BACKUP_FILE

# 30일 이상 된 백업 삭제
aws s3 ls s3://signal-factory-backups/database/ | \
  awk '{print $4}' | \
  while read file; do
    age=$(( ($(date +%s) - $(date -d "$(echo $file | cut -d'_' -f2 | cut -d'.' -f1)" +%s)) / 86400 ))
    if [ $age -gt 30 ]; then
      aws s3 rm s3://signal-factory-backups/database/$file
    fi
  done
```

## 스케일링

### 수평적 확장 (Horizontal Scaling)

```yaml
# k8s/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: trading-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: trading-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 15
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

## 환경 변수 관리

### AWS Secrets Manager

```javascript
const AWS = require('aws-sdk');
const secretsManager = new AWS.SecretsManager();

async function getSecrets() {
  const secretName = `signal-factory/${process.env.NODE_ENV}`;
  
  const data = await secretsManager.getSecretValue({
    SecretId: secretName
  }).promise();
  
  const secrets = JSON.parse(data.SecretString);
  
  // 환경 변수로 설정
  Object.entries(secrets).forEach(([key, value]) => {
    process.env[key] = value;
  });
}

// 시작 시 로드
getSecrets().then(() => {
  require('./app');
});
```

## 재해 복구

### 다중 리전 배포

```yaml
# terraform/multi-region.tf
provider "aws" {
  alias  = "primary"
  region = "ap-northeast-2"
}

provider "aws" {
  alias  = "secondary"
  region = "us-west-2"
}

# Primary RDS
resource "aws_db_instance" "primary" {
  provider = aws.primary
  
  identifier = "signal-factory-primary"
  engine     = "postgres"
  instance_class = "db.t3.medium"
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
}

# Read Replica in secondary region
resource "aws_db_instance" "replica" {
  provider = aws.secondary
  
  replicate_source_db = aws_db_instance.primary.arn
  identifier          = "signal-factory-replica"
  instance_class      = "db.t3.medium"
}
```

## 관련 문서

- [아키텍처 개요](./01_architecture_overview.md)
- [보안](./07_security.md)

[← 메인 문서로 돌아가기](./00_overview.md)
