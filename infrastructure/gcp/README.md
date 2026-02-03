# GA Personal - GCP Infrastructure

## Overview

Production infrastructure for GA Personal training management system.

- **Project:** guialmeidapersonal
- **Region:** southamerica-east1 (São Paulo)
- **Domain:** guialmeidapersonal.esp.br

## Architecture

```
                    ┌─────────────────────────────────────────┐
                    │           Cloud DNS                      │
                    │   *.guialmeidapersonal.esp.br           │
                    └───────────────┬─────────────────────────┘
                                    │
                    ┌───────────────▼─────────────────────────┐
                    │      Global HTTPS Load Balancer          │
                    │         + SSL Certificate                │
                    └───────────────┬─────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────┐         ┌─────────────────┐         ┌─────────────────┐
│ Cloud Storage │         │   Cloud Run     │         │ Cloud Storage   │
│ (Frontends)   │         │   (Backend)     │         │   (Media)       │
│ + Cloud CDN   │         │ + VPC Connector │         │                 │
└───────────────┘         └────────┬────────┘         └─────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │         VPC Network          │
                    │      ga-personal-vpc         │
                    └──────────────┬──────────────┘
                                   │
                ┌──────────────────┼──────────────────┐
                │                  │                  │
                ▼                  ▼                  ▼
        ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
        │  Cloud SQL    │ │  Memorystore  │ │    Secret     │
        │  PostgreSQL   │ │    Redis      │ │   Manager     │
        └───────────────┘ └───────────────┘ └───────────────┘
```

## Infrastructure Scripts

Run scripts in order:

| Script | Purpose |
|--------|---------|
| `01-network.sh` | VPC network and subnet |
| `02-vpc-connector.sh` | VPC connector for Cloud Run |
| `03-cloudsql.sh` | PostgreSQL database |
| `04-redis.sh` | Redis cache |
| `05-service-accounts.sh` | Service accounts and IAM |
| `06-secrets.sh` | Secret Manager secrets |
| `07-storage.sh` | Cloud Storage buckets |
| `08-artifact-registry.sh` | Docker image registry |
| `09-build-backend.sh` | Build and push backend image |
| `10-deploy-backend.sh` | Deploy to Cloud Run |
| `11-load-balancer.sh` | HTTPS load balancer with SSL |
| `12-dns.sh` | Cloud DNS records |
| `13-deploy-frontends.sh` | Build and deploy frontends |
| `14-cicd.sh` | GitHub Actions setup |
| `15-monitoring.sh` | Uptime checks |

## Quick Commands

### Deploy Backend
```bash
./infrastructure/gcp/09-build-backend.sh
./infrastructure/gcp/10-deploy-backend.sh
```

### Deploy Frontends
```bash
./infrastructure/gcp/13-deploy-frontends.sh
```

### Check Status
```bash
# Cloud Run service
gcloud run services describe ga-personal-api --region=southamerica-east1

# SSL certificate
gcloud certificate-manager certificates describe ga-personal-cert

# DNS records
gcloud dns record-sets list --zone=guialmeidapersonal-zone
```

## URLs

| Service | URL |
|---------|-----|
| API | https://api.guialmeidapersonal.esp.br |
| Admin | https://admin.guialmeidapersonal.esp.br |
| App | https://app.guialmeidapersonal.esp.br |
| Site | https://guialmeidapersonal.esp.br |

## Secrets

Stored in Secret Manager:
- `database-url` - PostgreSQL connection string
- `redis-url` - Redis connection string
- `jwt-secret` - JWT signing key
- `secret-key-base` - Phoenix secret key

## Cost Estimate

~$110-130/month:
- Cloud SQL (db-perf-optimized-N-2): ~$50/month
- Memorystore Redis (1GB): ~$35/month
- Cloud Run: ~$5-20/month (scales to zero)
- Load Balancer + SSL: ~$20/month
- Cloud Storage + CDN: ~$5-10/month
