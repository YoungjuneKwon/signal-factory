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
