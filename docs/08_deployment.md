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

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Lint
      run: npm run lint
    
    - name: Test
      run: npm test
    
    - name: Build
      run: npm run build
  
  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Snyk security scan
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
    
    - name: Run CodeQL analysis
      uses: github/codeql-action/analyze@v2
  
  build:
    needs: [test, security]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
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
  
  deploy:
    needs: build
    runs-on: ubuntu-latest
    
    steps:
    - name: Deploy to ECS
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: task-definition.json
        service: signal-factory-service
        cluster: production-cluster
        wait-for-service-stability: true
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
