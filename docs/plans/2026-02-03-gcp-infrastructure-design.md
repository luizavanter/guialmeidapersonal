# GA Personal - GCP Infrastructure Design

**Date:** 2026-02-03
**Status:** Approved
**Region:** São Paulo (southamerica-east1)
**Project ID:** guialmeidapersonal
**Domain:** guialmeidapersonal.esp.br

---

## Executive Summary

Complete production infrastructure for GA Personal using GCP serverless services optimized for cost and performance. Hybrid architecture with Cloud Run for backend and Cloud Storage + CDN for frontends, providing auto-scaling, high availability, and global content delivery.

**Key Characteristics:**
- Serverless architecture (Cloud Run + Cloud Storage)
- Production-only environment (start simple, add staging later if needed)
- Automated CI/CD on git push
- Start small, scale based on usage
- Private networking for databases
- Automated SSL certificate management
- Estimated cost: ~$100-120/month

---

## 1. Overall Architecture

### Compute Layer

**Cloud Run (Backend API)**
- **Service:** `ga-personal-api`
- **Region:** southamerica-east1 (São Paulo)
- **Configuration:**
  - Min instances: 0 (scale to zero)
  - Max instances: 10
  - CPU: 1 vCPU
  - Memory: 512MB
  - Timeout: 300s
  - Concurrency: 80 requests per instance
- **Ingress:** Internal and Load Balancer only (no direct public access)
- **VPC:** Connected via VPC Connector for Cloud SQL/Redis access

### Frontend Layer

**Cloud Storage + Cloud CDN**

Three separate buckets for static content:

1. **admin-guialmeidapersonal** (Trainer Dashboard)
   - Vue 3 SPA build artifacts
   - Serves: admin.guialmeidapersonal.esp.br

2. **app-guialmeidapersonal** (Student Portal)
   - Vue 3 SPA build artifacts
   - Serves: app.guialmeidapersonal.esp.br

3. **site-guialmeidapersonal** (Marketing Site)
   - VitePress static site
   - Serves: guialmeidapersonal.esp.br

**Cloud CDN Configuration:**
- Cache mode: CACHE_ALL_STATIC
- Cache TTL: 3600s for static assets, 300s for HTML
- Compression: gzip, brotli
- Edge locations: Global PoPs with São Paulo origin

### Data Layer

**Cloud SQL PostgreSQL**
- **Instance:** ga-personal-db
- **Version:** PostgreSQL 16
- **Tier:** db-f1-micro (shared CPU, 614MB RAM, 10GB SSD)
- **Region:** southamerica-east1-a
- **Network:** Private IP only (10.0.1.0/24)
- **High Availability:** Not enabled initially (cost optimization)
- **Backups:**
  - Automated daily at 3 AM BRT
  - Retention: 7 days
  - Point-in-time recovery: Enabled
- **Maintenance:** Sunday 3-4 AM BRT

**Memorystore Redis**
- **Instance:** ga-personal-redis
- **Version:** Redis 7.0
- **Tier:** Basic (M1, 1GB)
- **Region:** southamerica-east1-a
- **Network:** Private IP only (same VPC)
- **Persistence:** RDB snapshots every 12 hours
- **Eviction:** allkeys-lru

### Media Storage

**Cloud Storage (Private Bucket)**
- **Bucket:** media-guialmeidapersonal
- **Purpose:** Evolution photos, exercise videos, documents
- **Access:** Private, signed URLs for authenticated access
- **Lifecycle:**
  - Keep current version in Standard storage
  - Move to Coldline after 90 days
  - Delete after 365 days (configurable)
- **CORS:** Enabled for direct upload from frontend

---

## 2. Networking & Security

### VPC Network

**VPC Configuration:**
- **Name:** ga-personal-vpc
- **Region:** southamerica-east1
- **Subnet:** 10.0.0.0/20 (4,096 IP addresses)
- **Private Google Access:** Enabled
- **Flow Logs:** Enabled for security monitoring

**VPC Connector:**
- **Name:** ga-personal-vpc-connector
- **CIDR:** 10.8.0.0/28 (for Cloud Run to VPC connection)
- **Throughput:** 200-300 Mbps (min-max)

### Service Accounts (Workload Identity)

**1. Backend Service Account**
- **Email:** backend-sa@guialmeidapersonal.iam.gserviceaccount.com
- **Roles:**
  - Cloud SQL Client (cloudsql.client)
  - Memorystore Redis Editor (redis.editor)
  - Cloud Storage Object Admin (storage.objectAdmin) - for media bucket
  - Secret Manager Secret Accessor (secretmanager.secretAccessor)
- **Usage:** Attached to Cloud Run service

**2. CI/CD Service Account**
- **Email:** cicd-sa@guialmeidapersonal.iam.gserviceaccount.com
- **Roles:**
  - Cloud Run Admin (run.admin)
  - Cloud Storage Admin (storage.admin)
  - Artifact Registry Writer (artifactregistry.writer)
  - Service Account User (iam.serviceAccountUser)
- **Usage:** GitHub Actions workflow authentication

**3. Frontend Service Account**
- **Email:** frontend-sa@guialmeidapersonal.iam.gserviceaccount.com
- **Roles:**
  - Cloud Storage Object Viewer (storage.objectViewer) - for public buckets
- **Usage:** Public bucket access via load balancer

### Secrets Management

**Secret Manager Secrets:**

1. **database-url**
   - Connection string: `postgresql://ga_personal_user:${PASSWORD}@10.0.1.x:5432/ga_personal_prod`
   - Accessed by: backend-sa

2. **redis-url**
   - Connection string: `redis://10.0.2.x:6379/0`
   - Accessed by: backend-sa

3. **jwt-secret**
   - Random 64-byte hex string
   - Accessed by: backend-sa

4. **secret-key-base**
   - Phoenix secret (mix phx.gen.secret)
   - Accessed by: backend-sa

5. **github-deploy-key** (optional)
   - SSH key for private repo access
   - Accessed by: cicd-sa

### Firewall Rules

**Default Rules:**
- Cloud Run: Private ingress only (load balancer access)
- Cloud SQL: No public IP, VPC internal only
- Memorystore: VPC internal only
- Cloud Storage (public buckets): Internet accessible via load balancer
- Cloud Storage (media bucket): Private, authenticated access only

---

## 3. CI/CD Pipeline (GitHub Actions)

### Repository

**GitHub Repository:** git@github.com:luizavanter/guialmeidapersonal.git

### Automated Deployment Workflow

**Trigger:** Push to `main` branch

### Backend Deployment Pipeline

**Workflow: `.github/workflows/deploy-backend.yml`**

```yaml
Steps:
1. Checkout code
2. Authenticate to GCP (Workload Identity Federation)
3. Set up Elixir environment
4. Install dependencies (mix deps.get)
5. Run tests (mix test)
6. Compile release (MIX_ENV=prod mix release)
7. Build Docker image
8. Push to Artifact Registry (southamerica-east1-docker.pkg.dev/guialmeidapersonal/ga-personal/backend)
9. Run database migrations (via Cloud SQL Proxy)
10. Deploy to Cloud Run (ga-personal-api)
11. Health check (/api/v1/health)
12. Route traffic to new revision (gradual rollout)
```

**Docker Image:**
- Base: elixir:1.15-alpine
- Multi-stage build (builder + runtime)
- Final size: ~50MB

### Frontend Deployment Pipeline

**Workflow: `.github/workflows/deploy-frontend.yml`**

```yaml
Steps:
1. Checkout code
2. Authenticate to GCP
3. Set up Node.js 20
4. Install dependencies (npm install)
5. Build trainer-app (npm run build)
6. Upload to gs://admin-guialmeidapersonal
7. Build student-app (npm run build)
8. Upload to gs://app-guialmeidapersonal
9. Build site (npm run build)
10. Upload to gs://site-guialmeidapersonal
11. Invalidate Cloud CDN cache
```

**Build Configuration:**
- Environment: VITE_API_URL=https://api.guialmeidapersonal.esp.br
- Optimization: Minification, tree-shaking, code splitting
- Output: dist/ directory per app

### Rollback Strategy

**Backend (Cloud Run):**
- Keeps last 5 revisions
- Instant rollback: `gcloud run services update-traffic --to-revisions=PREVIOUS=100`
- Zero-downtime deployment (gradual traffic shift)

**Frontend (Cloud Storage):**
- Object versioning enabled
- Can restore previous versions: `gsutil cp gs://bucket/file#version ./`
- Deployment includes CDN cache invalidation

### Health Checks

**Backend Health Check:**
- Endpoint: `GET /api/v1/health`
- Expected: 200 OK with JSON `{"status": "ok"}`
- Timeout: 30s
- Retries: 3
- Startup probe: 10s delay

**Frontend Health Check:**
- Load balancer checks HTTP 200 on root path
- Checks: Every 10s
- Unhealthy threshold: 3 consecutive failures

---

## 4. DNS & SSL Configuration

### Cloud DNS

**Hosted Zone:** guialmeidapersonal.esp.br (existing)

**Name Servers:** (Will be functional after propagation)

**DNS Records:**

All A/AAAA records point to Load Balancer external IP:

| Record | Type | Value | TTL |
|--------|------|-------|-----|
| api.guialmeidapersonal.esp.br | A | LB_EXTERNAL_IP | 300 |
| admin.guialmeidapersonal.esp.br | A | LB_EXTERNAL_IP | 300 |
| app.guialmeidapersonal.esp.br | A | LB_EXTERNAL_IP | 300 |
| guialmeidapersonal.esp.br | A | LB_EXTERNAL_IP | 300 |
| www.guialmeidapersonal.esp.br | A | LB_EXTERNAL_IP | 300 |

### SSL Certificates (Certificate Manager)

**Certificate Configuration:**
- **Type:** Google-managed SSL certificate
- **Primary Domain:** guialmeidapersonal.esp.br
- **SANs (Subject Alternative Names):**
  - api.guialmeidapersonal.esp.br
  - admin.guialmeidapersonal.esp.br
  - app.guialmeidapersonal.esp.br
  - www.guialmeidapersonal.esp.br
  - *.guialmeidapersonal.esp.br (wildcard for future subdomains)

**Certificate Provisioning:**
- Method: DNS authorization via Cloud DNS
- Auto-renewal: Enabled (90-day rotation)
- Status check: Automated via Certificate Manager

### Load Balancer Configuration

**Global HTTPS Load Balancer:**
- **Name:** ga-personal-lb
- **Type:** External Application Load Balancer
- **IP:** Static external IPv4 (reserve: `ga-personal-ip`)
- **Ports:**
  - 443 (HTTPS) - primary traffic
  - 80 (HTTP) - redirect to HTTPS

**URL Map (Host/Path Routing):**

```
api.guialmeidapersonal.esp.br/*
  → Backend: Cloud Run (ga-personal-api)

admin.guialmeidapersonal.esp.br/*
  → Backend: Cloud Storage bucket (admin-guialmeidapersonal)

app.guialmeidapersonal.esp.br/*
  → Backend: Cloud Storage bucket (app-guialmeidapersonal)

guialmeidapersonal.esp.br/*
  → Backend: Cloud Storage bucket (site-guialmeidapersonal)

www.guialmeidapersonal.esp.br/*
  → Redirect: 301 to guialmeidapersonal.esp.br
```

**HTTP to HTTPS Redirect:**
- HTTP target proxy: Redirect all HTTP traffic to HTTPS
- Status code: 301 (permanent redirect)

**Security Headers:**
- HSTS: max-age=31536000; includeSubDomains
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- X-XSS-Protection: 1; mode=block

### CDN Configuration

**Cloud CDN Policies:**
- **Cache Mode:** CACHE_ALL_STATIC (for storage backends)
- **Default TTL:** 3600s (1 hour)
- **Client TTL:** 3600s
- **Max TTL:** 86400s (24 hours)
- **Cache Key Policy:**
  - Include protocol
  - Include host
  - Include query string

**Cache Behavior by Content Type:**
- HTML: 300s (5 minutes)
- CSS/JS: 31536000s (1 year) with cache busting via versioned filenames
- Images: 86400s (24 hours)
- Fonts: 31536000s (1 year)

**Compression:**
- Automatic compression enabled
- Formats: gzip, brotli
- Min size: 1KB

---

## 5. Database & Storage Configuration

### Cloud SQL PostgreSQL

**Instance Configuration:**
```
Name: ga-personal-db
Region: southamerica-east1
Zone: southamerica-east1-a
Version: PostgreSQL 16
Tier: db-f1-micro
CPU: 0.6 vCPU (shared)
Memory: 614 MB
Storage: 10 GB SSD (auto-increase enabled, max 100GB)
```

**Network Configuration:**
```
Private IP: 10.0.1.x (assigned by GCP)
VPC: ga-personal-vpc
Public IP: Disabled
Authorized Networks: None (private only)
SSL: Required for all connections
```

**Database Setup:**
```sql
Database: ga_personal_prod
User: ga_personal_user
Password: (stored in Secret Manager)
Extensions: uuid-ossp, pg_trgm, btree_gin
```

**Backup Configuration:**
```
Automated Backups: Enabled
Schedule: Daily at 03:00 BRT
Retention: 7 days
Point-in-time Recovery: Enabled
Transaction Log Retention: 7 days
```

**Maintenance Window:**
```
Day: Sunday
Time: 03:00-04:00 BRT
Order: Prefer maintenance at the beginning of the window
```

**Flags:**
```
max_connections: 100
shared_buffers: 128MB
effective_cache_size: 256MB
work_mem: 4MB
maintenance_work_mem: 64MB
```

### Memorystore Redis

**Instance Configuration:**
```
Name: ga-personal-redis
Region: southamerica-east1
Zone: southamerica-east1-a
Tier: Basic (non-replicated)
Version: Redis 7.0
Memory: 1 GB (M1)
```

**Network Configuration:**
```
Private IP: 10.0.2.x (assigned by GCP)
VPC: ga-personal-vpc
Port: 6379
Connection Mode: Direct peering
```

**Redis Configuration:**
```
maxmemory-policy: allkeys-lru
persistence: RDB
save: 900 1 300 10 60 10000 (RDB snapshots)
appendonly: no (Basic tier limitation)
```

**Maintenance Window:**
```
Day: Sunday
Time: 04:00-05:00 BRT
```

### Cloud Storage Buckets

**Frontend Buckets (Public, CDN-enabled):**

**1. admin-guialmeidapersonal**
```
Location: southamerica-east1
Storage Class: Standard
Public Access: Enabled (allUsers objectViewer)
Versioning: Enabled
Lifecycle:
  - Delete noncurrent versions after 30 days
CORS: Not required (served via load balancer)
```

**2. app-guialmeidapersonal**
```
Location: southamerica-east1
Storage Class: Standard
Public Access: Enabled (allUsers objectViewer)
Versioning: Enabled
Lifecycle:
  - Delete noncurrent versions after 30 days
CORS: Not required (served via load balancer)
```

**3. site-guialmeidapersonal**
```
Location: southamerica-east1
Storage Class: Standard
Public Access: Enabled (allUsers objectViewer)
Versioning: Enabled
Lifecycle:
  - Delete noncurrent versions after 30 days
CORS: Not required (served via load balancer)
```

**Media Bucket (Private):**

**media-guialmeidapersonal**
```
Location: southamerica-east1
Storage Class: Standard
Public Access: Disabled
Versioning: Disabled
Lifecycle:
  - Transition to Coldline after 90 days
  - Delete after 365 days (optional)
CORS:
  - Origin: https://admin.guialmeidapersonal.esp.br, https://app.guialmeidapersonal.esp.br
  - Methods: GET, PUT, POST
  - Headers: Content-Type, Authorization
  - Max Age: 3600s
Signed URL Expiration: 3600s (1 hour)
```

---

## 6. Monitoring, Logging & Cost Management

### Cloud Monitoring

**Dashboards:**

**1. Application Health Dashboard**
- Cloud Run: Request count, latency (p50, p95, p99), error rate, instance count
- Load Balancer: Request count, backend latency, 4xx/5xx rates
- Cloud CDN: Cache hit rate, bandwidth, request count

**2. Database Performance Dashboard**
- Cloud SQL: CPU utilization, memory usage, connections, query performance
- Memorystore: Memory usage, hit rate, evictions, connected clients

**3. Cost Dashboard**
- Breakdown by service
- Daily/monthly trends
- Budget alerts

### Alerting Policies

**Critical Alerts (PagerDuty/Email):**
```
1. Cloud Run 5xx Error Rate > 5%
   Duration: 5 minutes

2. Cloud SQL CPU > 80%
   Duration: 10 minutes

3. Cloud SQL Disk > 80%
   Duration: 1 minute

4. Memorystore Memory > 90%
   Duration: 5 minutes

5. Load Balancer 5xx Rate > 1%
   Duration: 5 minutes
```

**Warning Alerts (Email):**
```
1. Cloud Run Latency p95 > 2s
   Duration: 10 minutes

2. Cloud SQL Connections > 80%
   Duration: 5 minutes

3. Memorystore Evictions > 100/min
   Duration: 10 minutes

4. Cloud CDN Cache Hit Rate < 70%
   Duration: 30 minutes
```

### Cloud Logging

**Log Configuration:**
```
Retention: 30 days
Format: JSON (structured logging)
Severity Levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
```

**Log Sinks:**
```
1. Error Logs → Dedicated log bucket (90-day retention)
2. Access Logs → Standard (30-day retention)
3. Audit Logs → Compliance bucket (1-year retention)
```

**Log-Based Metrics:**
```
1. 5xx errors by endpoint
2. Slow queries (>1s)
3. Authentication failures
4. Failed file uploads
```

### Uptime Checks

**Endpoints to Monitor:**
```
1. https://api.guialmeidapersonal.esp.br/api/v1/health
   Frequency: 1 minute
   Timeout: 10s
   Regions: São Paulo, US, Europe

2. https://admin.guialmeidapersonal.esp.br
   Frequency: 5 minutes
   Expected: 200 OK

3. https://app.guialmeidapersonal.esp.br
   Frequency: 5 minutes
   Expected: 200 OK

4. https://guialmeidapersonal.esp.br
   Frequency: 5 minutes
   Expected: 200 OK
```

### Cost Management

**Monthly Cost Estimates (USD):**

**Compute:**
```
Cloud Run (minimal traffic):
  - CPU: ~$3
  - Memory: ~$2
  - Requests: ~$5
  Subtotal: ~$10

VPC Connector: ~$8
```

**Data:**
```
Cloud SQL db-f1-micro:
  - Instance: ~$7.67
  - Storage (10GB): ~$1.70
  - Backups (70GB): ~$2
  Subtotal: ~$11.37

Memorystore Redis M1:
  - Instance (1GB): ~$38
  - Reserved IP: ~$2
  Subtotal: ~$40
```

**Storage & CDN:**
```
Cloud Storage:
  - Standard (50GB): ~$1
  - Operations: ~$0.50
  Subtotal: ~$1.50

Cloud CDN:
  - Cache fill: ~$5
  - Cache egress (100GB): ~$8
  Subtotal: ~$13
```

**Networking:**
```
Load Balancer:
  - Forwarding rules: ~$18
  - Data processing: ~$8
  Subtotal: ~$26

NAT Gateway (if needed): ~$5
```

**Other:**
```
Certificate Manager: Free
Cloud DNS: ~$0.40 (2M queries)
Secret Manager: ~$0.20
Artifact Registry: ~$0.10 (1GB)
Cloud Logging (basic): ~$5
Cloud Monitoring: Free tier
```

**Total Estimated: ~$110-130/month**

**Cost Optimization Strategies:**
```
1. Cloud Run scales to zero (no traffic = no cost)
2. Cloud CDN reduces backend load significantly
3. Storage lifecycle policies reduce long-term storage costs
4. Committed use discounts (1-year) save 37% on Cloud SQL if scaling up
5. Monitor and right-size resources based on actual usage
```

**Budget Alerts:**
```
Alert 1: 50% of monthly budget ($65)
Alert 2: 80% of monthly budget ($104)
Alert 3: 100% of monthly budget ($130)
Alert 4: 120% of monthly budget ($156)
```

---

## 7. Deployment Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET (HTTPS)                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Cloud DNS (guialmeidapersonal.esp.br)               │
│  api.* │ admin.* │ app.* │ www.* → LB_EXTERNAL_IP              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   HTTPS Load Balancer                            │
│  - SSL Certificate (Certificate Manager)                         │
│  - HTTP → HTTPS Redirect                                         │
│  - URL Map Routing                                               │
└──────────┬──────────────────┬──────────────┬────────────────────┘
           │                  │              │
           ▼                  ▼              ▼
    ┌──────────┐      ┌──────────────┐  ┌──────────────┐
    │ Cloud Run│      │Cloud Storage │  │Cloud Storage │
    │  (API)   │      │   (Admin)    │  │    (App)     │
    └────┬─────┘      └──────────────┘  └──────────────┘
         │
         │ VPC Connector
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    VPC (ga-personal-vpc)                         │
│                     10.0.0.0/20                                  │
│  ┌──────────────────┐              ┌────────────────────┐       │
│  │   Cloud SQL      │              │  Memorystore Redis │       │
│  │  PostgreSQL 16   │              │    Redis 7.0       │       │
│  │  (Private IP)    │              │   (Private IP)     │       │
│  │  10.0.1.x        │              │   10.0.2.x         │       │
│  └──────────────────┘              └────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Cloud Storage   │
                    │     (Media)     │
                    │   (Private)     │
                    └─────────────────┘

CI/CD Pipeline (GitHub Actions):
git push → GitHub → Workload Identity → GCP
  ├─ Backend: Build → Artifact Registry → Cloud Run
  └─ Frontend: Build → Cloud Storage → CDN Invalidate
```

---

## 8. Security Considerations

### Authentication & Authorization

**API Authentication:**
- JWT tokens with 15-minute expiry
- Refresh tokens with 7-day expiry
- Tokens stored in HttpOnly cookies
- CSRF protection enabled

**GCP Access:**
- Service accounts with least-privilege IAM roles
- Workload Identity Federation (no long-lived keys)
- Secret Manager for all sensitive data
- VPC-only access for databases

### Network Security

**Private Networking:**
- Cloud SQL: Private IP only, no public access
- Memorystore: VPC internal only
- Cloud Run: Private ingress, load balancer access only

**Firewall:**
- Default deny all ingress
- Allow from load balancer to Cloud Run
- Allow from Cloud Run to Cloud SQL/Redis (VPC)
- Allow from Cloud Run to Cloud Storage (Private Google Access)

### Data Security

**Encryption:**
- Data at rest: Google-managed encryption keys
- Data in transit: TLS 1.2+ only
- Database connections: SSL required

**Access Control:**
- Media bucket: Private, signed URLs with expiration
- Frontend buckets: Public read-only
- Database: Strong password (stored in Secret Manager)
- Redis: VPC network isolation (no password required)

### Compliance

**Logging & Audit:**
- Admin Activity logs: 400-day retention
- Data Access logs: 30-day retention
- Cloud Audit Logs for all admin actions

**Backup & Recovery:**
- Automated daily database backups
- Point-in-time recovery enabled
- Frontend version history (30-day retention)
- Media bucket versioning disabled (cost optimization)

---

## 9. Migration Strategy

### Phase 1: Infrastructure Setup (Day 1)
1. Create VPC and networking
2. Provision Cloud SQL and Memorystore
3. Create service accounts and secrets
4. Reserve static IP and configure DNS
5. Set up load balancer and SSL certificates

### Phase 2: CI/CD Setup (Day 1)
1. Configure GitHub Actions workflows
2. Set up Workload Identity Federation
3. Create Artifact Registry repository
4. Test build and deployment pipelines

### Phase 3: Initial Deployment (Day 1-2)
1. Deploy backend to Cloud Run
2. Run database migrations
3. Deploy frontends to Cloud Storage
4. Configure load balancer routing
5. Test all endpoints

### Phase 4: DNS Cutover (Day 2)
1. Wait for name servers to propagate (13 minutes remaining)
2. Update DNS records to point to load balancer
3. Verify SSL certificate provisioning
4. Test all domains

### Phase 5: Monitoring & Validation (Day 2-3)
1. Set up monitoring dashboards
2. Configure alerting policies
3. Perform load testing
4. Validate backup/restore procedures

---

## 10. Operational Procedures

### Deployment Procedure
```bash
# Automated via GitHub Actions on push to main
git add .
git commit -m "Your changes"
git push origin main

# Manual deployment (if needed)
gcloud run deploy ga-personal-api \
  --region=southamerica-east1 \
  --image=southamerica-east1-docker.pkg.dev/guialmeidapersonal/ga-personal/backend:latest
```

### Rollback Procedure
```bash
# Cloud Run rollback
gcloud run services update-traffic ga-personal-api \
  --region=southamerica-east1 \
  --to-revisions=PREVIOUS_REVISION=100

# Frontend rollback
gsutil -m cp -r gs://admin-guialmeidapersonal#version ./backup/
gsutil -m rsync -r ./backup/ gs://admin-guialmeidapersonal/
```

### Database Maintenance
```bash
# Manual backup
gcloud sql backups create \
  --instance=ga-personal-db

# Restore from backup
gcloud sql backups restore BACKUP_ID \
  --backup-instance=ga-personal-db \
  --backup-instance=ga-personal-db

# Run migrations
# Via Cloud SQL Proxy in CI/CD pipeline
```

### Scaling Procedures
```bash
# Scale Cloud Run instances
gcloud run services update ga-personal-api \
  --max-instances=20 \
  --region=southamerica-east1

# Upgrade Cloud SQL tier
gcloud sql instances patch ga-personal-db \
  --tier=db-g1-small

# Upgrade Memorystore capacity
gcloud redis instances update ga-personal-redis \
  --size=5 \
  --region=southamerica-east1
```

---

## 11. Success Criteria

✅ All services deployed and accessible via HTTPS
✅ SSL certificates provisioned and auto-renewing
✅ HTTP redirects to HTTPS working
✅ All subdomains resolving correctly
✅ Backend API responding on api.guialmeidapersonal.esp.br
✅ Trainer dashboard accessible on admin.guialmeidapersonal.esp.br
✅ Student portal accessible on app.guialmeidapersonal.esp.br
✅ Marketing site accessible on guialmeidapersonal.esp.br
✅ Database migrations applied successfully
✅ Redis cache functioning
✅ Media uploads working with signed URLs
✅ CI/CD pipeline deploying on git push
✅ Monitoring dashboards showing metrics
✅ Alerting policies configured and tested
✅ Cost within budget (~$100-130/month)

---

## 12. Future Enhancements

**Short-term (1-3 months):**
- Add staging environment for testing
- Implement automated database scaling based on load
- Add Cloud Armor for DDoS protection
- Implement Cloud CDN signed cookies for private content

**Medium-term (3-6 months):**
- Upgrade to Cloud SQL High Availability
- Add read replicas for database scaling
- Implement Cloud Functions for image processing
- Add Cloud Pub/Sub for async job processing

**Long-term (6-12 months):**
- Multi-region deployment for disaster recovery
- Implement Cloud Spanner for global database
- Add Firebase for real-time features
- Implement ML-based anomaly detection

---

*Design approved: 2026-02-03*
*Ready for implementation*
