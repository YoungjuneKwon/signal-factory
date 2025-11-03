# 보안

[← 메인 문서로 돌아가기](./00_overview.md)

## 보안 위협 모델

### 주요 위협

1. **악성 로직 실행**
   - 시스템 리소스 고갈
   - 무한 루프, 메모리 폭탄
   - 네트워크/파일시스템 접근 시도

2. **데이터 유출**
   - 사용자 로직 코드 유출
   - API 키 및 크리덴셜 노출
   - 거래 전략 탈취

3. **API 오남용**
   - Rate limiting 우회
   - DDoS 공격
   - 무단 접근

4. **자동 매매 리스크**
   - 버그로 인한 예상치 못한 거래
   - 시장 조작 시도
   - 자금 손실

## 샌드박스 격리

### VM2 기반 격리 (Node.js)

```javascript
const { VM } = require('vm2');

class SecureVM {
  constructor() {
    this.vm = new VM({
      timeout: 5000,
      sandbox: {
        // 허용된 함수만 제공
        calculateMA: this.calculateMA,
        Math: Math,
        Date: Date
      },
      compiler: 'javascript',
      eval: false,
      wasm: false
    });
  }
  
  run(code, input) {
    // 위험한 패턴 사전 검사
    this.validateCode(code);
    
    return this.vm.run(`
      (function(input) {
        ${code}
        return generateSignal(input);
      })
    `)(input);
  }
  
  validateCode(code) {
    const blacklist = [
      /require\(/,
      /import /,
      /eval\(/,
      /Function\(/,
      /process\./,
      /child_process/,
      /__dirname/,
      /__filename/,
      /global\./
    ];
    
    for (const pattern of blacklist) {
      if (pattern.test(code)) {
        throw new Error(`Forbidden pattern: ${pattern}`);
      }
    }
  }
}
```

### Deno 격리 (더 안전한 대안)

```typescript
// deno-worker.ts
import { serve } from "https://deno.land/std/http/server.ts";

async function executeLogic(code: string, input: any) {
  // Deno는 기본적으로 권한이 차단됨
  const func = new Function('input', `
    ${code}
    return generateSignal(input);
  `);
  
  return func(input);
}

serve(async (req) => {
  const { code, input } = await req.json();
  
  try {
    const result = await executeLogic(code, input);
    return new Response(JSON.stringify(result));
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400
    });
  }
});
```

### 컨테이너 격리 (Docker)

```dockerfile
# Dockerfile.logic-runner
FROM node:18-alpine

# 비특권 사용자 생성
RUN addgroup -S logicrunner && adduser -S logicrunner -G logicrunner

WORKDIR /app

# 필요한 패키지만 설치
COPY package.json package-lock.json ./
RUN npm ci --only=production

COPY src ./src

# 읽기 전용 파일시스템
RUN chmod -R 555 /app

USER logicrunner

# 네트워크 격리
# docker run --network=none

CMD ["node", "src/logic-runner.js"]
```

### gVisor 격리 (더 강력한 격리)

```yaml
# docker-compose.yml
version: '3.8'
services:
  logic-runner:
    image: logic-runner:latest
    runtime: runsc
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp
    networks:
      - isolated
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 128M
```

## 인증 및 인가

### JWT 기반 인증

```javascript
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

class AuthService {
  async login(email, password) {
    const user = await db.users.findByEmail(email);
    if (!user) {
      throw new Error('Invalid credentials');
    }
    
    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      throw new Error('Invalid credentials');
    }
    
    const token = jwt.sign(
      { 
        userId: user.id, 
        role: user.role,
        tier: user.tier
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    return { token, user };
  }
  
  verifyToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      throw new Error('Invalid token');
    }
  }
}

// Express 미들웨어
function authenticate(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  try {
    req.user = authService.verifyToken(token);
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// 권한 체크
function authorize(requiredTier) {
  return (req, res, next) => {
    const tierLevels = { free: 0, premium: 1, enterprise: 2 };
    
    if (tierLevels[req.user.tier] < tierLevels[requiredTier]) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    
    next();
  };
}

// 사용 예
app.get('/api/v1/signals/realtime', 
  authenticate, 
  authorize('premium'),
  (req, res) => {
    // ...
  }
);
```

### API 키 관리

```javascript
class APIKeyService {
  async generateKey(userId, description) {
    const key = crypto.randomBytes(32).toString('hex');
    const hash = await bcrypt.hash(key, 10);
    
    await db.apiKeys.create({
      userId,
      keyHash: hash,
      description,
      createdAt: new Date()
    });
    
    // 키는 한 번만 반환
    return key;
  }
  
  async validateKey(key) {
    const allKeys = await db.apiKeys.findActive();
    
    for (const record of allKeys) {
      const valid = await bcrypt.compare(key, record.keyHash);
      if (valid) {
        await this.recordUsage(record.id);
        return record;
      }
    }
    
    throw new Error('Invalid API key');
  }
  
  async revokeKey(keyId, userId) {
    await db.apiKeys.update(keyId, {
      revokedAt: new Date(),
      revokedBy: userId
    });
  }
}
```

## Rate Limiting

### Redis 기반 Rate Limiter

```javascript
const Redis = require('ioredis');
const redis = new Redis();

class RateLimiter {
  async checkLimit(userId, endpoint, maxRequests, windowMs) {
    const key = `ratelimit:${userId}:${endpoint}`;
    const now = Date.now();
    const windowStart = now - windowMs;
    
    // 오래된 요청 제거
    await redis.zremrangebyscore(key, 0, windowStart);
    
    // 현재 윈도우 내 요청 수
    const count = await redis.zcard(key);
    
    if (count >= maxRequests) {
      const oldestRequest = await redis.zrange(key, 0, 0, 'WITHSCORES');
      const resetTime = parseInt(oldestRequest[1]) + windowMs;
      
      throw new Error(`Rate limit exceeded. Retry after ${new Date(resetTime).toISOString()}`);
    }
    
    // 새 요청 기록
    await redis.zadd(key, now, `${now}-${crypto.randomBytes(8).toString('hex')}`);
    await redis.expire(key, Math.ceil(windowMs / 1000));
    
    return {
      remaining: maxRequests - count - 1,
      reset: now + windowMs
    };
  }
}

// Express 미들웨어
function rateLimit(maxRequests, windowMs) {
  return async (req, res, next) => {
    try {
      const result = await rateLimiter.checkLimit(
        req.user.id,
        req.path,
        maxRequests,
        windowMs
      );
      
      res.set('X-RateLimit-Remaining', result.remaining);
      res.set('X-RateLimit-Reset', result.reset);
      
      next();
    } catch (error) {
      res.status(429).json({ error: error.message });
    }
  };
}

// 사용 예
app.get('/api/v1/backtests',
  authenticate,
  rateLimit(10, 60000), // 10 requests per minute
  async (req, res) => {
    // ...
  }
);
```

## 암호화

### 데이터 암호화

```javascript
const crypto = require('crypto');

class Encryption {
  constructor(key) {
    this.algorithm = 'aes-256-gcm';
    this.key = Buffer.from(key, 'hex');
  }
  
  encrypt(text) {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(this.algorithm, this.key, iv);
    
    let encrypted = cipher.update(text, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    const authTag = cipher.getAuthTag();
    
    return {
      encrypted,
      iv: iv.toString('hex'),
      authTag: authTag.toString('hex')
    };
  }
  
  decrypt(encrypted, iv, authTag) {
    const decipher = crypto.createDecipheriv(
      this.algorithm,
      this.key,
      Buffer.from(iv, 'hex')
    );
    
    decipher.setAuthTag(Buffer.from(authTag, 'hex'));
    
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  }
}

// 로직 코드 암호화 저장
async function saveLogicSecurely(userId, code) {
  const encryption = new Encryption(process.env.ENCRYPTION_KEY);
  const { encrypted, iv, authTag } = encryption.encrypt(code);
  
  await db.logics.create({
    userId,
    encryptedCode: encrypted,
    iv,
    authTag
  });
}
```

### TLS/SSL 설정

```nginx
# nginx.conf
server {
    listen 443 ssl http2;
    server_name api.signal-factory.com;
    
    ssl_certificate /etc/ssl/certs/signal-factory.crt;
    ssl_certificate_key /etc/ssl/private/signal-factory.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    location / {
        proxy_pass http://backend:3000;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 감사 로깅

```javascript
class AuditLogger {
  async log(event) {
    await db.auditLogs.create({
      userId: event.userId,
      action: event.action,
      resource: event.resource,
      resourceId: event.resourceId,
      ipAddress: event.ipAddress,
      userAgent: event.userAgent,
      timestamp: new Date(),
      metadata: event.metadata
    });
  }
}

// 미들웨어
function auditLog(action) {
  return async (req, res, next) => {
    res.on('finish', async () => {
      await auditLogger.log({
        userId: req.user?.id,
        action,
        resource: req.baseUrl + req.path,
        resourceId: req.params.id,
        ipAddress: req.ip,
        userAgent: req.get('user-agent'),
        metadata: {
          method: req.method,
          statusCode: res.statusCode
        }
      });
    });
    
    next();
  };
}

// 사용 예
app.delete('/api/v1/logics/:id',
  authenticate,
  auditLog('DELETE_LOGIC'),
  async (req, res) => {
    // ...
  }
);
```

## 관련 문서

- [아키텍처 개요](./01_architecture_overview.md)
- [신호 생성 시스템](./03_signal_generation.md)
- [배포 및 운영](./08_deployment.md)

[← 메인 문서로 돌아가기](./00_overview.md)
