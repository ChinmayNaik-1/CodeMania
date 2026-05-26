# CodeMania Deployment Checklist

## Pre-Deployment

### Backend Configuration
- [ ] Update `NODE_ENV=production` in `.env`
- [ ] Set strong `JWT_SECRET` (minimum 32 characters)
- [ ] Set strong database password (not default 'codemania')
- [ ] Configure `CLIENT_URL` to production domain
- [ ] Update `SOCKET_CORS_ORIGIN` to production domain(s)
- [ ] Increase `PISTON_MEMORY_LIMIT` if needed (default: 128000 = 128MB)
- [ ] Set `PISTON_RUN_TIMEOUT` appropriately (default: 3000ms = 3s)
- [ ] Enable database backups (PostgreSQL WAL archiving)
- [ ] Configure Redis persistence (`appendonly yes`)

### Flutter Configuration
- [ ] Generate Flutter web build: `flutter build web --release --web-renderer html`
- [ ] Copy `flutter_app/build/web` to `backend/public`
- [ ] Or run one command: `build_and_deploy.bat`
- [ ] Build Android APK: `flutter build apk --release`
- [ ] Build iOS app: `flutter build ios --release`

### Security
- [ ] Rotate JWT secret regularly
- [ ] Enable database SSL connections
- [ ] Use HTTPS everywhere (SSL certificate from Let's Encrypt/Certbot)
- [ ] Configure CORS properly (whitelist specific origins)
- [ ] Implement rate limiting on endpoints
- [ ] Add request logging and monitoring
- [ ] Validate all user inputs server-side
- [ ] Use environment secrets manager (AWS Secrets Manager / HashiCorp Vault)
- [ ] Enable password complexity requirements
- [ ] Set token expiration to 24 hours or less

### Infrastructure
- [ ] Deploy to cloud (AWS/GCP/Azure/DigitalOcean)
- [ ] Use managed PostgreSQL (RDS/Cloud SQL/Azure DB)
- [ ] Use managed Redis (ElastiCache/Cloud Memorystore)
- [ ] Use CDN for static assets (CloudFront/Akamai)
- [ ] Configure auto-scaling for containers
- [ ] Set up health check endpoints
- [ ] Enable monitoring and alerting (DataDog/New Relic)
- [ ] Configure log aggregation (ELK/Splunk)

---

## Deployment Architectures

### Option 1: Docker Compose (Small Production ~$100/month)
```bash
# On VPS (DigitalOcean/Linode)
git clone <repo>
cd codemania

# Setup
cp backend/.env.example backend/.env
# Edit .env for production values
cp backend/serviceAccountKey.json .

# Deploy
docker-compose -f docker-compose.prod.yml up -d

# Database
docker-compose exec postgres psql -U postgres -c "ALTER USER codemania WITH PASSWORD 'NEW_SECURE_PASSWORD';"
docker-compose exec postgres psql -U codemania -d codemania -f schema.sql

# SSL with Let's Encrypt
certbot certonly --standalone -d yourdomain.com
```

### Option 2: Kubernetes (Medium Production ~$200/month)
```yaml
# kubernetes/deployment.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: codemania-config
data:
  DATABASE_URL: postgresql://codemania:password@postgres-service:5432/codemania
  REDIS_URL: redis://redis-service:6379
  PISTON_URL: http://piston-service:2000/api/v2/execute
  CLIENT_URL: https://yourdomain.com

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: backend
        image: node:18-alpine
        volumeMounts:
        - name: code
          mountPath: /app
        env:
        - name: NODE_ENV
          value: production
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1024Mi"
            cpu: "500m"

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: piston
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: piston
        image: ghcr.io/engineer-man/piston:latest
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
```

### Option 3: Serverless (AWS Lambda ~$50/month for small usage)
```
Note: Piston requires long-running processes, not ideal for Lambda
Consider AWS ECS Fargate instead
```

---

## Production Deploy Script

```bash
#!/bin/bash
# deploy.sh

set -e

DOMAIN="yourdomain.com"
BRANCH="main"

echo "🚀 Deploying CodeMania to production..."

# 1. Pull latest code
echo "📦 Pulling latest code..."
git fetch origin
git checkout $BRANCH
git pull origin $BRANCH

# 2. Build backend
echo "🔨 Building backend..."
cd backend
npm install --production
npm audit fix

# 3. Build Flutter web
echo "🔨 Building Flutter web..."
cd ../flutter_app
flutter clean
flutter pub get
flutter build web --release

# 4. Stop running containers
echo "🛑 Stopping running services..."
docker-compose down

# 5. Start new containers
echo "▶️  Starting new services..."
docker-compose -f docker-compose.prod.yml up -d

# 6. Run migrations (if any)
echo "📊 Running database migrations..."
docker-compose exec -T postgres psql -U codemania -d codemania -f ../schema.sql

# 7. Verify deployment
echo "✅ Verifying deployment..."

# Check backend health
BACKEND_HEALTH=$(curl -s http://localhost:3000/health)
if echo "$BACKEND_HEALTH" | grep -q "ok"; then
    echo "✓ Backend healthy"
else
    echo "✗ Backend health check failed"
    exit 1
fi

# Check database
docker-compose exec -T postgres psql -U codemania -d codemania -c "SELECT 1;" > /dev/null && echo "✓ Database healthy" || exit 1

# 8. Notify
echo ""
echo "✨ Deployment successful!"
echo "🌐 Available at: https://$DOMAIN"
echo ""
```

---

## Monitoring & Alerts

### Key Metrics to Monitor
```
Backend:
├─ Response time (p50, p95, p99)
├─ Error rate (4xx, 5xx)
├─ Active connections
├─ Database query time
└─ Memory usage

Piston:
├─ Compilation success rate
├─ Execution time distribution
└─ Memory usage per containerization

Frontend:
├─ First Contentful Paint (FCP)
├─ Largest Contentful Paint (LCP)
├─ Cumulative Layout Shift (CLS)
└─ User interaction latency

Business:
├─ Active users
├─ Submissions per hour
├─ Problem difficulty distribution
└─ Contest participation rate
```

### Alert Rules
```
Database CPU > 80% for 5min → Page on-call
Backend error rate > 0.5% for 5min → Page on-call
Piston timeout rate > 2% → Page on-call
Response time p95 > 2s → Warning (not page)
Memory usage > 90% → Immediate shutdown + manual review
```

---

## Backup Strategy

### PostgreSQL
```bash
# Daily automated backup
0 2 * * * pg_dump -U codemania -h localhost codemania | gzip > /backups/db_$(date +\%Y\%m\%d).sql.gz

# Upload to S3
at 3:00am daily: aws s3 sync /backups s3://codemania-backups/
```

### Redis
```bash
# Redis persists to disk by default (RDB snapshots)
# Additional: Point-in-time recovery with AOF (Append Only File)

# In redis.conf:
appendonly yes
appendfsync everysec
```

### Application Code
```
Git repository itself is the source backup
- Push all changes to GitHub/GitLab
- Use branch protection + code review
- Tag releases: git tag -a v1.0.0 -m "Release 1.0.0"
```

---

## Rollback Procedure

### If Deployment Fails
```bash
# 1. Identify issue from logs
docker logs codemania-backend | tail -50

# 2. Revert Docker images
docker-compose down
git checkout main~1  # Go back one commit
docker-compose up -d

# 3. Verify services
curl http://localhost:3000/health

# 4. Investigate and fix issue
git log --oneline -5  # Review recent changes
git diff main~1  # See what changed
```

---

## Performance Tuning

### PostgreSQL
```sql
-- Connection pooling (pgBouncer)
max_connections = 200
work_mem = 16MB

-- Indexes
CREATE INDEX idx_problems_created ON problems(created_at DESC);
CREATE INDEX idx_submissions_created ON submissions(created_at DESC);

-- Vacuum & Analyze
VACUUM ANALYZE;  -- Run daily

-- Stats
SELECT pg_size_pretty(pg_database_size('codemania'));
SELECT tablename, pg_size_pretty(pg_total_relation_size(tablename)) 
FROM pg_tables WHERE schemaname='public'
ORDER BY pg_total_relation_size(tablename) DESC;
```

### Node.js
```
Enable clustering (multi-core utilization):
- pm2 start index.js -i 4  (use 4 worker processes)
- Sticky sessions for WebSocket (Socket.IO adapter)

Memory:
- Increase Node heap: NODE_OPTIONS="--max-old-space-size=2048"

Logging:
- Use structured logging (Winston/Pino)
- Rotate logs (logrotate)
```

### Redis
```bash
# Monitor commands
redis-cli MONITOR  # Real-time command stream

# Performance stats
redis-cli INFO stats

# Memory optimization
CONFIG SET maxmemory-policy allkeys-lru
CONFIG SET maxmemory 1gb
```

---

## Disaster Recovery

### RTO (Recovery Time Objective): 1 hour
### RPO (Recovery Point Objective): 24 hours

### Steps
```
1. Restore database from latest daily backup
2. Redeploy backend code from latest git tag
3. Rebuild Flutter web from latest release
4. Verify all services are healthy
5. Run smoke tests
6. Notify users if data loss > 24hrs
```

---

## Compliance

### GDPR Compliance
- [ ] User data deletion endpoint (`DELETE /user/profile`)
- [ ] Data export endpoint (GDPR right to portability)
- [ ] Privacy policy page (HTTPS + clear language)
- [ ] Terms of service
- [ ] Cookie consent (if applicable)

### Security Compliance
- [ ] HTTPS everywhere (A+ SSL rating)
- [ ] No plaintext passwords (bcrypt/Argon2)
- [ ] No API keys in logs
- [ ] Rate limiting to prevent abuse
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS protection (CSP headers)

---

## Cost Optimization

### Current Estimate (Single Instance)
```
VPS (2 vCPU, 4GB RAM):        $20-30/month
Managed PostgreSQL (10GB):    $20-30/month
Managed Redis (1GB):          $10-15/month
Domain:                       $10-15/month
SSL Certificate:              $0 (Let's Encrypt)
Backup storage (100GB):       $5-10/month
─────────────────────────────────────────
Total:                        ~$65-100/month
```

### Cost Reduction Tips
```
1. Use shared hosting initially
2. Combine database & Redis on same VPS
3. Use free tier databases (limited)
4. Cache aggressively
5. Compress assets
6. Use CDN only for peaks
```

---

**Last Updated:** March 2026
**Next Review:** June 2026
