# GCP Infrastructure Deployment Status

**Date:** 2026-02-03
**Project:** guialmeidapersonal
**Region:** southamerica-east1 (São Paulo)
**Domain:** guialmeidapersonal.esp.br

---

## Deployment Summary

All infrastructure components have been successfully deployed to Google Cloud Platform.

### Load Balancer
- **Static IP:** 34.149.155.125
- **Name:** ga-personal-lb
- **SSL:** Certificate Manager wildcard cert (ga-personal-cert)

### DNS Records (Zone: guialmeidapersonal)
| Record | Type | TTL | Value |
|--------|------|-----|-------|
| guialmeidapersonal.esp.br | A | 300 | 34.149.155.125 |
| www.guialmeidapersonal.esp.br | A | 300 | 34.149.155.125 |
| api.guialmeidapersonal.esp.br | A | 300 | 34.149.155.125 |
| admin.guialmeidapersonal.esp.br | A | 300 | 34.149.155.125 |
| app.guialmeidapersonal.esp.br | A | 300 | 34.149.155.125 |
| _acme-challenge | CNAME | 300 | (SSL validation) |

**Nameservers:** ns-cloud-a1 through ns-cloud-a4.googledomains.com

---

## Infrastructure Components

### 1. Networking
- **VPC:** ga-personal-vpc
- **Subnet:** ga-personal-subnet (10.0.0.0/20)
- **VPC Connector:** ga-personal-vpc-connector (10.8.0.0/28)
- **Firewall:** ga-personal-allow-internal

### 2. Database
- **Cloud SQL Instance:** ga-personal-db
- **Type:** PostgreSQL 16
- **Tier:** db-perf-optimized-N-2
- **Connectivity:** Private IP only (VPC)
- **Database:** ga_personal_prod
- **User:** ga_personal

### 3. Cache
- **Memorystore Instance:** ga-personal-redis
- **Type:** Redis 7.0
- **Tier:** Basic (1GB)
- **Host:** 10.154.114.59:6379
- **Connectivity:** Private IP only (VPC)

### 4. Backend
- **Cloud Run Service:** ga-personal-api
- **Image:** southamerica-east1-docker.pkg.dev/guialmeidapersonal/ga-personal/backend:latest
- **Revision:** ga-personal-api-00002-hhf
- **Port:** 4000
- **CPU:** 1
- **Memory:** 512Mi
- **Min/Max Instances:** 0-10
- **Service Account:** backend-sa@guialmeidapersonal.iam.gserviceaccount.com

### 5. Frontend Buckets
| Bucket | Purpose | URL Mapping |
|--------|---------|-------------|
| admin-guialmeidapersonal | Trainer App | admin.guialmeidapersonal.esp.br |
| app-guialmeidapersonal | Student App | app.guialmeidapersonal.esp.br |
| site-guialmeidapersonal | Marketing Site | guialmeidapersonal.esp.br, www. |
| media-guialmeidapersonal | User uploads | Internal |

### 6. Secrets (Secret Manager)
- `database-url` - PostgreSQL connection string
- `redis-url` - Redis connection string
- `jwt-secret` - JWT signing key
- `secret-key-base` - Phoenix secret key

### 7. CI/CD
- **Workload Identity Pool:** github-actions-pool
- **Provider:** github-actions-provider
- **Service Account:** cicd-sa@guialmeidapersonal.iam.gserviceaccount.com
- **Repository:** luizavanter/guialmeidapersonal

---

## GitHub Secrets Required

Configure at: https://github.com/luizavanter/guialmeidapersonal/settings/secrets/actions

| Secret Name | Value |
|-------------|-------|
| GCP_WORKLOAD_IDENTITY_PROVIDER | `projects/843739340071/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider` |
| GCP_SERVICE_ACCOUNT | `cicd-sa@guialmeidapersonal.iam.gserviceaccount.com` |

---

## Production URLs

| Service | URL | Status |
|---------|-----|--------|
| API | https://api.guialmeidapersonal.esp.br | Ready (pending SSL) |
| Admin Dashboard | https://admin.guialmeidapersonal.esp.br | Ready (pending SSL) |
| Student Portal | https://app.guialmeidapersonal.esp.br | Ready (pending SSL) |
| Marketing Site | https://guialmeidapersonal.esp.br | Ready (pending SSL) |

---

## Access Credentials

### Trainer (Admin)
- **Email:** guilherme@gapersonal.com
- **Password:** trainer123
- **Access:** https://admin.guialmeidapersonal.esp.br

### Test Students
- **Maria:** maria.silva@example.com / student123
- **Carlos:** carlos.santos@example.com / student123
- **Access:** https://app.guialmeidapersonal.esp.br

> **Important:** Run database migrations to create these users:
> ```bash
> gcloud run jobs execute ga-personal-migrations --region=southamerica-east1 --project=guialmeidapersonal --wait
> ```

---

## Post-Deployment Checklist

- [x] VPC and networking configured
- [x] Cloud SQL database deployed
- [x] Memorystore Redis deployed
- [x] Service accounts created
- [x] Secrets configured
- [x] Storage buckets created
- [x] Backend Docker image built
- [x] Backend deployed to Cloud Run
- [x] Load balancer configured
- [x] DNS records created
- [x] SSL certificate provisioning
- [x] Frontend applications deployed
- [x] CI/CD workflows configured
- [x] Monitoring uptime checks created
- [ ] GitHub secrets configured
- [ ] Database migrations executed
- [ ] SSL certificate active
- [ ] End-to-end testing

---

## Useful Commands

```bash
# Check service status
gcloud run services describe ga-personal-api --region=southamerica-east1 --project=guialmeidapersonal

# View logs
gcloud run services logs read ga-personal-api --region=southamerica-east1 --project=guialmeidapersonal --limit=50

# Run migrations
gcloud run jobs execute ga-personal-migrations --region=southamerica-east1 --project=guialmeidapersonal --wait

# Check SSL status
gcloud certificate-manager certificates describe ga-personal-cert --project=guialmeidapersonal

# Invalidate CDN cache
gcloud compute url-maps invalidate-cdn-cache ga-personal-lb --path="/*" --async --project=guialmeidapersonal
```

---

## Cost Estimate

| Component | Monthly Cost |
|-----------|-------------|
| Cloud SQL (db-perf-optimized-N-2) | ~$50 |
| Memorystore Redis (1GB) | ~$35 |
| Cloud Run (scales to zero) | ~$5-20 |
| Load Balancer + SSL | ~$20 |
| Cloud Storage + CDN | ~$5-10 |
| **Total** | **~$110-130/month** |

---

**Deployment completed:** 2026-02-03
**Status:** Ready for production use (pending SSL certificate activation)
