# GCP Infrastructure Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deploy the complete GA Personal system to Google Cloud Platform with production-ready infrastructure, automated CI/CD, and monitoring in São Paulo region.

**Architecture:** Cloud Run for Phoenix backend with private VPC connectivity to Cloud SQL PostgreSQL and Memorystore Redis. Cloud Storage + CDN for three Vue frontend applications. Global HTTPS Load Balancer with Certificate Manager SSL routing traffic to backends. GitHub Actions CI/CD with Workload Identity Federation for automated deployments.

**Tech Stack:** GCP (Cloud Run, Cloud SQL, Memorystore, Cloud Storage, Load Balancer, Certificate Manager), Docker, GitHub Actions, Terraform (optional), gcloud CLI

**Constraints:**
- All work in project: `guialmeidapersonal`
- Region: `southamerica-east1` (São Paulo)
- Domain: `guialmeidapersonal.esp.br` (name servers ready in ~10 minutes)
- Credentials stored in project only (no local user credentials)
- Production-only environment

---

## Prerequisites Verification

### Task 0: Verify GCP Project Access and Configure gcloud

**Files:**
- None (gcloud configuration only)

**Step 1: Check if gcloud is installed**

```bash
gcloud --version
```

Expected: Cloud SDK version info (if not installed, install from https://cloud.google.com/sdk/docs/install)

**Step 2: Authenticate with GCP using project-scoped credentials**

```bash
# Create a service account for local deployment work
gcloud auth login --project=guialmeidapersonal

# Set default project
gcloud config set project guialmeidapersonal

# Verify active account and project
gcloud config list
```

Expected: Shows `guialmeidapersonal` as active project

**Step 3: Enable required GCP APIs**

```bash
gcloud services enable \
  compute.googleapis.com \
  run.googleapis.com \
  sqladmin.googleapis.com \
  redis.googleapis.com \
  storage.googleapis.com \
  cloudresourcemanager.googleapis.com \
  servicenetworking.googleapis.com \
  vpcaccess.googleapis.com \
  dns.googleapis.com \
  certificatemanager.googleapis.com \
  cloudscheduler.googleapis.com \
  secretmanager.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com \
  --project=guialmeidapersonal
```

Expected: "Operation finished successfully" for each API

**Step 4: Verify API enablement**

```bash
gcloud services list --enabled --project=guialmeidapersonal | grep -E "(run|sql|redis|storage)"
```

Expected: List shows all required APIs enabled

**Step 5: Create directory for GCP infrastructure code**

```bash
mkdir -p /Users/luizpenha/guipersonal/infrastructure/gcp
cd /Users/luizpenha/guipersonal
```

**Step 6: Commit setup documentation**

Create file: `infrastructure/gcp/README.md`

```markdown
# GCP Infrastructure

Project: guialmeidapersonal
Region: southamerica-east1 (São Paulo)

## Prerequisites
- gcloud CLI authenticated with project
- All APIs enabled (see task 0)

## Components
- Cloud Run: Backend API
- Cloud SQL: PostgreSQL database
- Memorystore: Redis cache
- Cloud Storage: Frontend static files
- Load Balancer: HTTPS routing
- Certificate Manager: SSL certificates
```

```bash
git add infrastructure/gcp/README.md
git commit -m "infra: Add GCP infrastructure directory and documentation"
```

---

## Phase 1: Networking & VPC Setup

### Task 1: Create VPC Network and Subnets

**Files:**
- Create: `infrastructure/gcp/01-network.sh`

**Step 1: Create VPC network**

```bash
gcloud compute networks create ga-personal-vpc \
  --subnet-mode=custom \
  --bgp-routing-mode=regional \
  --project=guialmeidapersonal
```

Expected: "Created network [ga-personal-vpc]"

**Step 2: Create subnet in São Paulo**

```bash
gcloud compute networks subnets create ga-personal-subnet \
  --network=ga-personal-vpc \
  --region=southamerica-east1 \
  --range=10.0.0.0/20 \
  --enable-private-ip-google-access \
  --project=guialmeidapersonal
```

Expected: "Created subnet [ga-personal-subnet]"

**Step 3: Verify network creation**

```bash
gcloud compute networks describe ga-personal-vpc --project=guialmeidapersonal
gcloud compute networks subnets describe ga-personal-subnet --region=southamerica-east1 --project=guialmeidapersonal
```

Expected: Shows network and subnet details with correct CIDR ranges

**Step 4: Create firewall rule for internal traffic**

```bash
gcloud compute firewall-rules create ga-personal-allow-internal \
  --network=ga-personal-vpc \
  --allow=tcp,udp,icmp \
  --source-ranges=10.0.0.0/20 \
  --project=guialmeidapersonal
```

Expected: "Created firewall rule [ga-personal-allow-internal]"

**Step 5: Save network setup script**

Create file: `infrastructure/gcp/01-network.sh`

```bash
#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
NETWORK="ga-personal-vpc"
SUBNET="ga-personal-subnet"

echo "Creating VPC network..."
gcloud compute networks create $NETWORK \
  --subnet-mode=custom \
  --bgp-routing-mode=regional \
  --project=$PROJECT_ID

echo "Creating subnet..."
gcloud compute networks subnets create $SUBNET \
  --network=$NETWORK \
  --region=$REGION \
  --range=10.0.0.0/20 \
  --enable-private-ip-google-access \
  --project=$PROJECT_ID

echo "Creating firewall rules..."
gcloud compute firewall-rules create ga-personal-allow-internal \
  --network=$NETWORK \
  --allow=tcp,udp,icmp \
  --source-ranges=10.0.0.0/20 \
  --project=$PROJECT_ID

echo "Network setup complete!"
```

```bash
chmod +x infrastructure/gcp/01-network.sh
```

**Step 6: Commit network configuration**

```bash
git add infrastructure/gcp/01-network.sh
git commit -m "infra: Add VPC network and subnet configuration"
```

---

### Task 2: Create VPC Connector for Cloud Run

**Files:**
- Create: `infrastructure/gcp/02-vpc-connector.sh`

**Step 1: Create VPC connector**

```bash
gcloud compute networks vpc-access connectors create ga-personal-vpc-connector \
  --region=southamerica-east1 \
  --network=ga-personal-vpc \
  --range=10.8.0.0/28 \
  --min-throughput=200 \
  --max-throughput=300 \
  --project=guialmeidapersonal
```

Expected: "Creating VPC Access connector..." (takes 3-5 minutes)

**Step 2: Wait for connector to be ready**

```bash
gcloud compute networks vpc-access connectors describe ga-personal-vpc-connector \
  --region=southamerica-east1 \
  --project=guialmeidapersonal \
  --format="value(state)"
```

Expected: "READY"

**Step 3: Verify connector configuration**

```bash
gcloud compute networks vpc-access connectors describe ga-personal-vpc-connector \
  --region=southamerica-east1 \
  --project=guialmeidapersonal
```

Expected: Shows connector details with state=READY, ipCidrRange=10.8.0.0/28

**Step 4: Save VPC connector script**

Create file: `infrastructure/gcp/02-vpc-connector.sh`

```bash
#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
CONNECTOR_NAME="ga-personal-vpc-connector"
NETWORK="ga-personal-vpc"

echo "Creating VPC connector for Cloud Run..."
gcloud compute networks vpc-access connectors create $CONNECTOR_NAME \
  --region=$REGION \
  --network=$NETWORK \
  --range=10.8.0.0/28 \
  --min-throughput=200 \
  --max-throughput=300 \
  --project=$PROJECT_ID

echo "Waiting for connector to be ready..."
while [ "$(gcloud compute networks vpc-access connectors describe $CONNECTOR_NAME --region=$REGION --project=$PROJECT_ID --format='value(state)')" != "READY" ]; do
  echo "Waiting..."
  sleep 10
done

echo "VPC connector ready!"
```

```bash
chmod +x infrastructure/gcp/02-vpc-connector.sh
```

**Step 5: Commit VPC connector configuration**

```bash
git add infrastructure/gcp/02-vpc-connector.sh
git commit -m "infra: Add VPC connector for Cloud Run to VPC access"
```

---

## Phase 2: Database & Cache Setup

### Task 3: Create Cloud SQL PostgreSQL Instance

**Files:**
- Create: `infrastructure/gcp/03-cloudsql.sh`

**Step 1: Allocate IP range for private service connection**

```bash
gcloud compute addresses create ga-personal-sql-range \
  --global \
  --purpose=VPC_PEERING \
  --prefix-length=16 \
  --network=ga-personal-vpc \
  --project=guialmeidapersonal
```

Expected: "Created address [ga-personal-sql-range]"

**Step 2: Create private service connection**

```bash
gcloud services vpc-peerings connect \
  --service=servicenetworking.googleapis.com \
  --ranges=ga-personal-sql-range \
  --network=ga-personal-vpc \
  --project=guialmeidapersonal
```

Expected: "Operation finished successfully" (takes 2-3 minutes)

**Step 3: Create Cloud SQL instance**

```bash
gcloud sql instances create ga-personal-db \
  --database-version=POSTGRES_16 \
  --tier=db-f1-micro \
  --region=southamerica-east1 \
  --network=projects/guialmeidapersonal/global/networks/ga-personal-vpc \
  --no-assign-ip \
  --backup-start-time=03:00 \
  --maintenance-window-day=SUN \
  --maintenance-window-hour=3 \
  --enable-bin-log \
  --storage-auto-increase \
  --storage-size=10GB \
  --project=guialmeidapersonal
```

Expected: "Creating Cloud SQL instance..." (takes 5-10 minutes)

**Step 4: Wait for instance to be ready**

```bash
while [ "$(gcloud sql instances describe ga-personal-db --project=guialmeidapersonal --format='value(state)')" != "RUNNABLE" ]; do
  echo "Waiting for Cloud SQL to be ready..."
  sleep 15
done
echo "Cloud SQL instance ready!"
```

**Step 5: Generate secure database password**

```bash
DB_PASSWORD=$(openssl rand -base64 32)
echo "Generated database password (save this): $DB_PASSWORD"
```

**Step 6: Set root password**

```bash
gcloud sql users set-password postgres \
  --instance=ga-personal-db \
  --password="$DB_PASSWORD" \
  --project=guialmeidapersonal
```

Expected: "Updated user [postgres]"

**Step 7: Create application database and user**

```bash
gcloud sql databases create ga_personal_prod \
  --instance=ga-personal-db \
  --project=guialmeidapersonal
```

```bash
gcloud sql users create ga_personal_user \
  --instance=ga-personal-db \
  --password="$DB_PASSWORD" \
  --project=guialmeidapersonal
```

Expected: "Created database [ga_personal_prod]" and "Created user [ga_personal_user]"

**Step 8: Get Cloud SQL connection name and private IP**

```bash
gcloud sql instances describe ga-personal-db \
  --project=guialmeidapersonal \
  --format="value(connectionName)"

gcloud sql instances describe ga-personal-db \
  --project=guialmeidapersonal \
  --format="value(ipAddresses[0].ipAddress)"
```

Expected: Connection name like `guialmeidapersonal:southamerica-east1:ga-personal-db` and private IP like `10.x.x.x`

**Step 9: Save Cloud SQL setup script**

Create file: `infrastructure/gcp/03-cloudsql.sh`

```bash
#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
INSTANCE_NAME="ga-personal-db"
NETWORK="ga-personal-vpc"
DB_NAME="ga_personal_prod"
DB_USER="ga_personal_user"

echo "Allocating IP range for private service connection..."
gcloud compute addresses create ga-personal-sql-range \
  --global \
  --purpose=VPC_PEERING \
  --prefix-length=16 \
  --network=$NETWORK \
  --project=$PROJECT_ID

echo "Creating private service connection..."
gcloud services vpc-peerings connect \
  --service=servicenetworking.googleapis.com \
  --ranges=ga-personal-sql-range \
  --network=$NETWORK \
  --project=$PROJECT_ID

echo "Generating database password..."
DB_PASSWORD=$(openssl rand -base64 32)
echo "Database password: $DB_PASSWORD"
echo "IMPORTANT: Save this password - you'll need it for Secret Manager"

echo "Creating Cloud SQL instance (this takes 5-10 minutes)..."
gcloud sql instances create $INSTANCE_NAME \
  --database-version=POSTGRES_16 \
  --tier=db-f1-micro \
  --region=$REGION \
  --network=projects/$PROJECT_ID/global/networks/$NETWORK \
  --no-assign-ip \
  --backup-start-time=03:00 \
  --maintenance-window-day=SUN \
  --maintenance-window-hour=3 \
  --enable-bin-log \
  --storage-auto-increase \
  --storage-size=10GB \
  --project=$PROJECT_ID

echo "Waiting for instance to be ready..."
while [ "$(gcloud sql instances describe $INSTANCE_NAME --project=$PROJECT_ID --format='value(state)')" != "RUNNABLE" ]; do
  echo "Waiting..."
  sleep 15
done

echo "Setting database password..."
gcloud sql users set-password postgres \
  --instance=$INSTANCE_NAME \
  --password="$DB_PASSWORD" \
  --project=$PROJECT_ID

echo "Creating application database and user..."
gcloud sql databases create $DB_NAME \
  --instance=$INSTANCE_NAME \
  --project=$PROJECT_ID

gcloud sql users create $DB_USER \
  --instance=$INSTANCE_NAME \
  --password="$DB_PASSWORD" \
  --project=$PROJECT_ID

echo "Getting connection details..."
CONNECTION_NAME=$(gcloud sql instances describe $INSTANCE_NAME --project=$PROJECT_ID --format="value(connectionName)")
PRIVATE_IP=$(gcloud sql instances describe $INSTANCE_NAME --project=$PROJECT_ID --format="value(ipAddresses[0].ipAddress)")

echo ""
echo "Cloud SQL setup complete!"
echo "Connection Name: $CONNECTION_NAME"
echo "Private IP: $PRIVATE_IP"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Password: $DB_PASSWORD"
echo ""
echo "Database URL: postgresql://$DB_USER:$DB_PASSWORD@$PRIVATE_IP:5432/$DB_NAME"
```

```bash
chmod +x infrastructure/gcp/03-cloudsql.sh
```

**Step 10: Commit Cloud SQL configuration**

```bash
git add infrastructure/gcp/03-cloudsql.sh
git commit -m "infra: Add Cloud SQL PostgreSQL instance configuration"
```

---

### Task 4: Create Memorystore Redis Instance

**Files:**
- Create: `infrastructure/gcp/04-redis.sh`

**Step 1: Create Memorystore Redis instance**

```bash
gcloud redis instances create ga-personal-redis \
  --size=1 \
  --region=southamerica-east1 \
  --network=projects/guialmeidapersonal/global/networks/ga-personal-vpc \
  --redis-version=redis_7_0 \
  --tier=basic \
  --project=guialmeidapersonal
```

Expected: "Creating Cloud Memorystore instance..." (takes 3-5 minutes)

**Step 2: Wait for Redis instance to be ready**

```bash
while [ "$(gcloud redis instances describe ga-personal-redis --region=southamerica-east1 --project=guialmeidapersonal --format='value(state)')" != "READY" ]; do
  echo "Waiting for Redis to be ready..."
  sleep 10
done
echo "Redis instance ready!"
```

**Step 3: Get Redis connection details**

```bash
gcloud redis instances describe ga-personal-redis \
  --region=southamerica-east1 \
  --project=guialmeidapersonal \
  --format="value(host,port)"
```

Expected: Shows host (private IP) and port (6379)

**Step 4: Save Redis setup script**

Create file: `infrastructure/gcp/04-redis.sh`

```bash
#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
INSTANCE_NAME="ga-personal-redis"
NETWORK="ga-personal-vpc"

echo "Creating Memorystore Redis instance (takes 3-5 minutes)..."
gcloud redis instances create $INSTANCE_NAME \
  --size=1 \
  --region=$REGION \
  --network=projects/$PROJECT_ID/global/networks/$NETWORK \
  --redis-version=redis_7_0 \
  --tier=basic \
  --project=$PROJECT_ID

echo "Waiting for Redis to be ready..."
while [ "$(gcloud redis instances describe $INSTANCE_NAME --region=$REGION --project=$PROJECT_ID --format='value(state)')" != "READY" ]; do
  echo "Waiting..."
  sleep 10
done

echo "Getting connection details..."
REDIS_HOST=$(gcloud redis instances describe $INSTANCE_NAME --region=$REGION --project=$PROJECT_ID --format="value(host)")
REDIS_PORT=$(gcloud redis instances describe $INSTANCE_NAME --region=$REGION --project=$PROJECT_ID --format="value(port)")

echo ""
echo "Memorystore Redis setup complete!"
echo "Host: $REDIS_HOST"
echo "Port: $REDIS_PORT"
echo ""
echo "Redis URL: redis://$REDIS_HOST:$REDIS_PORT/0"
```

```bash
chmod +x infrastructure/gcp/04-redis.sh
```

**Step 5: Commit Redis configuration**

```bash
git add infrastructure/gcp/04-redis.sh
git commit -m "infra: Add Memorystore Redis instance configuration"
```

---

## Phase 3: Service Accounts & Secrets

### Task 5: Create Service Accounts

**Files:**
- Create: `infrastructure/gcp/05-service-accounts.sh`

**Step 1: Create backend service account**

```bash
gcloud iam service-accounts create backend-sa \
  --display-name="Backend Service Account" \
  --description="Service account for Cloud Run backend API" \
  --project=guialmeidapersonal
```

Expected: "Created service account [backend-sa]"

**Step 2: Create CI/CD service account**

```bash
gcloud iam service-accounts create cicd-sa \
  --display-name="CI/CD Service Account" \
  --description="Service account for GitHub Actions deployments" \
  --project=guialmeidapersonal
```

Expected: "Created service account [cicd-sa]"

**Step 3: Grant backend service account necessary roles**

```bash
# Cloud SQL Client
gcloud projects add-iam-policy-binding guialmeidapersonal \
  --member="serviceAccount:backend-sa@guialmeidapersonal.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"

# Redis Editor
gcloud projects add-iam-policy-binding guialmeidapersonal \
  --member="serviceAccount:backend-sa@guialmeidapersonal.iam.gserviceaccount.com" \
  --role="roles/redis.editor"

# Storage Object Admin (for media bucket)
gcloud projects add-iam-policy-binding guialmeidapersonal \
  --member="serviceAccount:backend-sa@guialmeidapersonal.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Secret Manager Secret Accessor
gcloud projects add-iam-policy-binding guialmeidapersonal \
  --member="serviceAccount:backend-sa@guialmeidapersonal.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

Expected: "Updated IAM policy for project [guialmeidapersonal]" for each

**Step 4: Grant CI/CD service account necessary roles**

```bash
# Cloud Run Admin
gcloud projects add-iam-policy-binding guialmeidapersonal \
  --member="serviceAccount:cicd-sa@guialmeidapersonal.iam.gserviceaccount.com" \
  --role="roles/run.admin"

# Storage Admin
gcloud projects add-iam-policy-binding guialmeidapersonal \
  --member="serviceAccount:cicd-sa@guialmeidapersonal.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Artifact Registry Writer
gcloud projects add-iam-policy-binding guialmeidapersonal \
  --member="serviceAccount:cicd-sa@guialmeidapersonal.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

# Service Account User (to act as backend-sa)
gcloud projects add-iam-policy-binding guialmeidapersonal \
  --member="serviceAccount:cicd-sa@guialmeidapersonal.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Cloud SQL Admin (for migrations)
gcloud projects add-iam-policy-binding guialmeidapersonal \
  --member="serviceAccount:cicd-sa@guialmeidapersonal.iam.gserviceaccount.com" \
  --role="roles/cloudsql.admin"
```

Expected: "Updated IAM policy for project [guialmeidapersonal]" for each

**Step 5: Save service accounts script**

Create file: `infrastructure/gcp/05-service-accounts.sh`

```bash
#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"

echo "Creating backend service account..."
gcloud iam service-accounts create backend-sa \
  --display-name="Backend Service Account" \
  --description="Service account for Cloud Run backend API" \
  --project=$PROJECT_ID

echo "Creating CI/CD service account..."
gcloud iam service-accounts create cicd-sa \
  --display-name="CI/CD Service Account" \
  --description="Service account for GitHub Actions deployments" \
  --project=$PROJECT_ID

echo "Granting backend service account permissions..."
for role in cloudsql.client redis.editor storage.objectAdmin secretmanager.secretAccessor; do
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:backend-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/$role"
done

echo "Granting CI/CD service account permissions..."
for role in run.admin storage.admin artifactregistry.writer iam.serviceAccountUser cloudsql.admin; do
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:cicd-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/$role"
done

echo ""
echo "Service accounts created!"
echo "Backend SA: backend-sa@$PROJECT_ID.iam.gserviceaccount.com"
echo "CI/CD SA: cicd-sa@$PROJECT_ID.iam.gserviceaccount.com"
```

```bash
chmod +x infrastructure/gcp/05-service-accounts.sh
```

**Step 6: Commit service accounts configuration**

```bash
git add infrastructure/gcp/05-service-accounts.sh
git commit -m "infra: Add service accounts with IAM roles"
```

---

### Task 6: Create Secrets in Secret Manager

**Files:**
- Create: `infrastructure/gcp/06-secrets.sh`

**Step 1: Generate secrets**

```bash
# JWT secret (64-byte hex)
JWT_SECRET=$(openssl rand -hex 64)

# Phoenix secret key base
SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d '\n')

echo "Generated secrets (save these):"
echo "JWT_SECRET: $JWT_SECRET"
echo "SECRET_KEY_BASE: $SECRET_KEY_BASE"
```

**Step 2: Get database and Redis connection strings**

```bash
# Get from previous tasks
DB_PASSWORD="<from task 3>"
DB_PRIVATE_IP=$(gcloud sql instances describe ga-personal-db --project=guialmeidapersonal --format="value(ipAddresses[0].ipAddress)")
REDIS_HOST=$(gcloud redis instances describe ga-personal-redis --region=southamerica-east1 --project=guialmeidapersonal --format="value(host)")

DATABASE_URL="postgresql://ga_personal_user:${DB_PASSWORD}@${DB_PRIVATE_IP}:5432/ga_personal_prod"
REDIS_URL="redis://${REDIS_HOST}:6379/0"

echo "DATABASE_URL: $DATABASE_URL"
echo "REDIS_URL: $REDIS_URL"
```

**Step 3: Create secrets in Secret Manager**

```bash
echo -n "$DATABASE_URL" | gcloud secrets create database-url \
  --data-file=- \
  --replication-policy="user-managed" \
  --locations="southamerica-east1" \
  --project=guialmeidapersonal

echo -n "$REDIS_URL" | gcloud secrets create redis-url \
  --data-file=- \
  --replication-policy="user-managed" \
  --locations="southamerica-east1" \
  --project=guialmeidapersonal

echo -n "$JWT_SECRET" | gcloud secrets create jwt-secret \
  --data-file=- \
  --replication-policy="user-managed" \
  --locations="southamerica-east1" \
  --project=guialmeidapersonal

echo -n "$SECRET_KEY_BASE" | gcloud secrets create secret-key-base \
  --data-file=- \
  --replication-policy="user-managed" \
  --locations="southamerica-east1" \
  --project=guialmeidapersonal
```

Expected: "Created secret [<name>]" for each

**Step 4: Grant backend service account access to secrets**

```bash
for secret in database-url redis-url jwt-secret secret-key-base; do
  gcloud secrets add-iam-policy-binding $secret \
    --member="serviceAccount:backend-sa@guialmeidapersonal.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor" \
    --project=guialmeidapersonal
done
```

Expected: "Updated IAM policy for secret [<name>]" for each

**Step 5: Verify secrets are accessible**

```bash
gcloud secrets versions access latest --secret="database-url" --project=guialmeidapersonal
```

Expected: Shows the database URL

**Step 6: Save secrets setup script**

Create file: `infrastructure/gcp/06-secrets.sh`

```bash
#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"

echo "Generating secrets..."
JWT_SECRET=$(openssl rand -hex 64)
SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d '\n')

echo "Getting database and Redis connection details..."
DB_PRIVATE_IP=$(gcloud sql instances describe ga-personal-db --project=$PROJECT_ID --format="value(ipAddresses[0].ipAddress)")
REDIS_HOST=$(gcloud redis instances describe ga-personal-redis --region=$REGION --project=$PROJECT_ID --format="value(host)")

echo "Enter the database password from Task 3:"
read -s DB_PASSWORD

DATABASE_URL="postgresql://ga_personal_user:${DB_PASSWORD}@${DB_PRIVATE_IP}:5432/ga_personal_prod"
REDIS_URL="redis://${REDIS_HOST}:6379/0"

echo ""
echo "Creating secrets in Secret Manager..."

echo -n "$DATABASE_URL" | gcloud secrets create database-url \
  --data-file=- \
  --replication-policy="user-managed" \
  --locations="$REGION" \
  --project=$PROJECT_ID

echo -n "$REDIS_URL" | gcloud secrets create redis-url \
  --data-file=- \
  --replication-policy="user-managed" \
  --locations="$REGION" \
  --project=$PROJECT_ID

echo -n "$JWT_SECRET" | gcloud secrets create jwt-secret \
  --data-file=- \
  --replication-policy="user-managed" \
  --locations="$REGION" \
  --project=$PROJECT_ID

echo -n "$SECRET_KEY_BASE" | gcloud secrets create secret-key-base \
  --data-file=- \
  --replication-policy="user-managed" \
  --locations="$REGION" \
  --project=$PROJECT_ID

echo "Granting backend service account access to secrets..."
for secret in database-url redis-url jwt-secret secret-key-base; do
  gcloud secrets add-iam-policy-binding $secret \
    --member="serviceAccount:backend-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor" \
    --project=$PROJECT_ID
done

echo ""
echo "Secrets created successfully!"
echo "Verify with: gcloud secrets list --project=$PROJECT_ID"
```

```bash
chmod +x infrastructure/gcp/06-secrets.sh
```

**Step 7: Commit secrets configuration**

```bash
git add infrastructure/gcp/06-secrets.sh
git commit -m "infra: Add Secret Manager configuration for sensitive data"
```

---

## Phase 4: Storage & CDN Setup

### Task 7: Create Cloud Storage Buckets

**Files:**
- Create: `infrastructure/gcp/07-storage.sh`

**Step 1: Create frontend buckets**

```bash
# Trainer dashboard bucket
gsutil mb -p guialmeidapersonal -c STANDARD -l southamerica-east1 gs://admin-guialmeidapersonal/

# Student portal bucket
gsutil mb -p guialmeidapersonal -c STANDARD -l southamerica-east1 gs://app-guialmeidapersonal/

# Marketing site bucket
gsutil mb -p guialmeidapersonal -c STANDARD -l southamerica-east1 gs://site-guialmeidapersonal/
```

Expected: "Creating gs://..." for each

**Step 2: Make frontend buckets publicly readable**

```bash
gsutil iam ch allUsers:objectViewer gs://admin-guialmeidapersonal
gsutil iam ch allUsers:objectViewer gs://app-guialmeidapersonal
gsutil iam ch allUsers:objectViewer gs://site-guialmeidapersonal
```

Expected: Updated IAM policy for each bucket

**Step 3: Enable versioning on frontend buckets**

```bash
gsutil versioning set on gs://admin-guialmeidapersonal
gsutil versioning set on gs://app-guialmeidapersonal
gsutil versioning set on gs://site-guialmeidapersonal
```

Expected: "Enabling versioning for gs://..."

**Step 4: Set lifecycle policy for old versions**

Create file: `infrastructure/gcp/lifecycle-policy.json`

```json
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "numNewerVersions": 3,
          "isLive": false
        }
      }
    ]
  }
}
```

```bash
gsutil lifecycle set infrastructure/gcp/lifecycle-policy.json gs://admin-guialmeidapersonal
gsutil lifecycle set infrastructure/gcp/lifecycle-policy.json gs://app-guialmeidapersonal
gsutil lifecycle set infrastructure/gcp/lifecycle-policy.json gs://site-guialmeidapersonal
```

Expected: "Setting lifecycle configuration on gs://..."

**Step 5: Create media bucket (private)**

```bash
gsutil mb -p guialmeidapersonal -c STANDARD -l southamerica-east1 gs://media-guialmeidapersonal/
```

**Step 6: Set CORS policy for media bucket**

Create file: `infrastructure/gcp/cors-policy.json`

```json
[
  {
    "origin": [
      "https://admin.guialmeidapersonal.esp.br",
      "https://app.guialmeidapersonal.esp.br"
    ],
    "method": ["GET", "PUT", "POST"],
    "responseHeader": ["Content-Type", "Authorization"],
    "maxAgeSeconds": 3600
  }
]
```

```bash
gsutil cors set infrastructure/gcp/cors-policy.json gs://media-guialmeidapersonal
```

Expected: "Setting CORS on gs://media-guialmeidapersonal..."

**Step 7: Set lifecycle policy for media bucket**

Create file: `infrastructure/gcp/media-lifecycle-policy.json`

```json
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "SetStorageClass", "storageClass": "COLDLINE"},
        "condition": {"age": 90}
      }
    ]
  }
}
```

```bash
gsutil lifecycle set infrastructure/gcp/media-lifecycle-policy.json gs://media-guialmeidapersonal
```

**Step 8: Save storage setup script**

Create file: `infrastructure/gcp/07-storage.sh`

```bash
#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"

echo "Creating frontend buckets..."
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://admin-guialmeidapersonal/
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://app-guialmeidapersonal/
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://site-guialmeidapersonal/

echo "Making frontend buckets public..."
gsutil iam ch allUsers:objectViewer gs://admin-guialmeidapersonal
gsutil iam ch allUsers:objectViewer gs://app-guialmeidapersonal
gsutil iam ch allUsers:objectViewer gs://site-guialmeidapersonal

echo "Enabling versioning..."
gsutil versioning set on gs://admin-guialmeidapersonal
gsutil versioning set on gs://app-guialmeidapersonal
gsutil versioning set on gs://site-guialmeidapersonal

echo "Setting lifecycle policies..."
cat > /tmp/lifecycle-policy.json << 'EOF'
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "numNewerVersions": 3,
          "isLive": false
        }
      }
    ]
  }
}
EOF

gsutil lifecycle set /tmp/lifecycle-policy.json gs://admin-guialmeidapersonal
gsutil lifecycle set /tmp/lifecycle-policy.json gs://app-guialmeidapersonal
gsutil lifecycle set /tmp/lifecycle-policy.json gs://site-guialmeidapersonal

echo "Creating media bucket..."
gsutil mb -p $PROJECT_ID -c STANDARD -l $REGION gs://media-guialmeidapersonal/

echo "Setting CORS policy for media bucket..."
cat > /tmp/cors-policy.json << 'EOF'
[
  {
    "origin": [
      "https://admin.guialmeidapersonal.esp.br",
      "https://app.guialmeidapersonal.esp.br"
    ],
    "method": ["GET", "PUT", "POST"],
    "responseHeader": ["Content-Type", "Authorization"],
    "maxAgeSeconds": 3600
  }
]
EOF

gsutil cors set /tmp/cors-policy.json gs://media-guialmeidapersonal

echo "Setting lifecycle policy for media bucket..."
cat > /tmp/media-lifecycle.json << 'EOF'
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "SetStorageClass", "storageClass": "COLDLINE"},
        "condition": {"age": 90}
      }
    ]
  }
}
EOF

gsutil lifecycle set /tmp/media-lifecycle.json gs://media-guialmeidapersonal

echo ""
echo "Storage buckets created!"
gsutil ls -p $PROJECT_ID
```

```bash
chmod +x infrastructure/gcp/07-storage.sh
```

**Step 9: Commit storage configuration**

```bash
git add infrastructure/gcp/07-storage.sh infrastructure/gcp/*.json
git commit -m "infra: Add Cloud Storage buckets with lifecycle and CORS policies"
```

---

## Phase 5: Artifact Registry & Backend Container

### Task 8: Create Artifact Registry Repository

**Files:**
- Create: `infrastructure/gcp/08-artifact-registry.sh`

**Step 1: Create Docker repository in Artifact Registry**

```bash
gcloud artifacts repositories create ga-personal \
  --repository-format=docker \
  --location=southamerica-east1 \
  --description="Docker images for GA Personal application" \
  --project=guialmeidapersonal
```

Expected: "Created repository [ga-personal]"

**Step 2: Configure Docker authentication**

```bash
gcloud auth configure-docker southamerica-east1-docker.pkg.dev
```

Expected: "Docker configuration file updated"

**Step 3: Verify repository creation**

```bash
gcloud artifacts repositories describe ga-personal \
  --location=southamerica-east1 \
  --project=guialmeidapersonal
```

Expected: Shows repository details

**Step 4: Save Artifact Registry setup script**

Create file: `infrastructure/gcp/08-artifact-registry.sh`

```bash
#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
REPO_NAME="ga-personal"

echo "Creating Artifact Registry repository..."
gcloud artifacts repositories create $REPO_NAME \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker images for GA Personal application" \
  --project=$PROJECT_ID

echo "Configuring Docker authentication..."
gcloud auth configure-docker ${REGION}-docker.pkg.dev

echo ""
echo "Artifact Registry repository created!"
echo "Repository: $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME"
```

```bash
chmod +x infrastructure/gcp/08-artifact-registry.sh
```

**Step 5: Commit Artifact Registry configuration**

```bash
git add infrastructure/gcp/08-artifact-registry.sh
git commit -m "infra: Add Artifact Registry repository for Docker images"
```

---

### Task 9: Create Dockerfile for Phoenix Backend

**Files:**
- Create: `Dockerfile`
- Create: `.dockerignore`

**Step 1: Create .dockerignore**

```
# .dockerignore
.git
.gitignore
README.md
docs/
reference/
frontend/
infrastructure/
_build/
deps/
*.log
.DS_Store
```

**Step 2: Create multi-stage Dockerfile**

Create file: `Dockerfile`

```dockerfile
# Build stage
FROM elixir:1.15-alpine AS builder

# Install build dependencies
RUN apk add --no-cache build-base git

# Set working directory
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
COPY apps/ga_personal/mix.exs apps/ga_personal/
COPY apps/ga_personal_web/mix.exs apps/ga_personal_web/
RUN mix do deps.get --only prod, deps.compile

# Copy application code
COPY apps ./apps
COPY config ./config

# Compile and build release
RUN mix do compile, phx.digest, release

# Runtime stage
FROM alpine:3.18 AS runtime

# Install runtime dependencies
RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    libstdc++ \
    libgcc

# Create app user
RUN addgroup -g 1000 app && \
    adduser -D -u 1000 -G app app

# Set working directory
WORKDIR /app

# Copy release from builder
COPY --from=builder --chown=app:app /app/_build/prod/rel/ga_personal ./

# Switch to app user
USER app

# Expose port
EXPOSE 4000

# Set environment
ENV HOME=/app
ENV MIX_ENV=prod
ENV PORT=4000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD ["/app/bin/ga_personal", "rpc", "1 + 1"]

# Start application
CMD ["/app/bin/ga_personal", "start"]
```

**Step 3: Test local Docker build**

```bash
docker build -t ga-personal-backend:test .
```

Expected: "Successfully built..." and "Successfully tagged ga-personal-backend:test"

**Step 4: Test container locally**

```bash
docker run --rm -p 4000:4000 \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
  -e REDIS_URL="redis://host:6379/0" \
  -e SECRET_KEY_BASE="test" \
  -e JWT_SECRET="test" \
  ga-personal-backend:test
```

Expected: Container starts (may fail on DB connection, that's ok)

**Step 5: Stop test container**

```bash
docker ps
docker stop <container_id>
```

**Step 6: Commit Docker configuration**

```bash
git add Dockerfile .dockerignore
git commit -m "infra: Add Dockerfile for Phoenix backend"
```

---

### Task 10: Build and Push Backend Image

**Files:**
- Modify: `infrastructure/gcp/09-build-backend.sh`

**Step 1: Build Docker image with Cloud Build**

```bash
gcloud builds submit \
  --tag southamerica-east1-docker.pkg.dev/guialmeidapersonal/ga-personal/backend:latest \
  --project=guialmeidapersonal \
  .
```

Expected: "Creating temporary tarball..." then build output (takes 5-10 minutes)

**Step 2: Verify image was pushed**

```bash
gcloud artifacts docker images list \
  southamerica-east1-docker.pkg.dev/guialmeidapersonal/ga-personal \
  --project=guialmeidapersonal
```

Expected: Shows backend:latest image

**Step 3: Create build script for future use**

Create file: `infrastructure/gcp/09-build-backend.sh`

```bash
#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
REPO="ga-personal"
IMAGE_NAME="backend"
TAG="${1:-latest}"

echo "Building and pushing backend Docker image..."
echo "Tag: $TAG"

gcloud builds submit \
  --tag $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE_NAME:$TAG \
  --project=$PROJECT_ID \
  .

echo ""
echo "Image built and pushed successfully!"
echo "Image: $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE_NAME:$TAG"
```

```bash
chmod +x infrastructure/gcp/09-build-backend.sh
```

**Step 4: Commit build script**

```bash
git add infrastructure/gcp/09-build-backend.sh
git commit -m "infra: Add backend Docker build and push script"
```

---

## Phase 6: Cloud Run Deployment

### Task 11: Deploy Backend to Cloud Run

**Files:**
- Create: `infrastructure/gcp/10-deploy-backend.sh`

**Step 1: Deploy Cloud Run service**

```bash
gcloud run deploy ga-personal-api \
  --image=southamerica-east1-docker.pkg.dev/guialmeidapersonal/ga-personal/backend:latest \
  --region=southamerica-east1 \
  --platform=managed \
  --service-account=backend-sa@guialmeidapersonal.iam.gserviceaccount.com \
  --vpc-connector=ga-personal-vpc-connector \
  --vpc-egress=private-ranges-only \
  --min-instances=0 \
  --max-instances=10 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=300s \
  --concurrency=80 \
  --ingress=internal-and-cloud-load-balancing \
  --set-secrets=DATABASE_URL=database-url:latest,REDIS_URL=redis-url:latest,JWT_SECRET=jwt-secret:latest,SECRET_KEY_BASE=secret-key-base:latest \
  --port=4000 \
  --allow-unauthenticated \
  --project=guialmeidapersonal
```

Expected: "Deploying container to Cloud Run..." (takes 2-3 minutes)

**Step 2: Get Cloud Run service URL**

```bash
gcloud run services describe ga-personal-api \
  --region=southamerica-east1 \
  --project=guialmeidapersonal \
  --format="value(status.url)"
```

Expected: URL like `https://ga-personal-api-xxx-ue.a.run.app`

**Step 3: Test Cloud Run service health endpoint**

```bash
SERVICE_URL=$(gcloud run services describe ga-personal-api --region=southamerica-east1 --project=guialmeidapersonal --format="value(status.url)")

curl -v $SERVICE_URL/api/v1/health
```

Expected: May fail if migrations not run yet, that's ok

**Step 4: Run database migrations**

```bash
# Get Cloud SQL connection name
SQL_CONNECTION=$(gcloud sql instances describe ga-personal-db --project=guialmeidapersonal --format="value(connectionName)")

# Run migrations via Cloud Run job
gcloud run jobs create ga-personal-migrate \
  --image=southamerica-east1-docker.pkg.dev/guialmeidapersonal/ga-personal/backend:latest \
  --region=southamerica-east1 \
  --service-account=backend-sa@guialmeidapersonal.iam.gserviceaccount.com \
  --vpc-connector=ga-personal-vpc-connector \
  --set-secrets=DATABASE_URL=database-url:latest \
  --command="/app/bin/ga_personal" \
  --args="eval,GaPersonal.Release.migrate" \
  --project=guialmeidapersonal

# Execute migration job
gcloud run jobs execute ga-personal-migrate \
  --region=southamerica-east1 \
  --project=guialmeidapersonal \
  --wait
```

Expected: "Finished execution successfully"

**Step 5: Test API again after migrations**

```bash
curl $SERVICE_URL/api/v1/health
```

Expected: `{"status":"ok"}` or similar

**Step 6: Create deployment script**

Create file: `infrastructure/gcp/10-deploy-backend.sh`

```bash
#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
SERVICE_NAME="ga-personal-api"
IMAGE_TAG="${1:-latest}"

IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/ga-personal/backend:$IMAGE_TAG"

echo "Deploying backend to Cloud Run..."
echo "Image: $IMAGE"

gcloud run deploy $SERVICE_NAME \
  --image=$IMAGE \
  --region=$REGION \
  --platform=managed \
  --service-account=backend-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --vpc-connector=ga-personal-vpc-connector \
  --vpc-egress=private-ranges-only \
  --min-instances=0 \
  --max-instances=10 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=300s \
  --concurrency=80 \
  --ingress=internal-and-cloud-load-balancing \
  --set-secrets=DATABASE_URL=database-url:latest,REDIS_URL=redis-url:latest,JWT_SECRET=jwt-secret:latest,SECRET_KEY_BASE=secret-key-base:latest \
  --port=4000 \
  --allow-unauthenticated \
  --project=$PROJECT_ID

echo ""
echo "Running database migrations..."
gcloud run jobs execute ga-personal-migrate \
  --region=$REGION \
  --project=$PROJECT_ID \
  --wait || echo "Migration job may not exist yet, create it first"

SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --project=$PROJECT_ID --format="value(status.url)")

echo ""
echo "Deployment complete!"
echo "Service URL: $SERVICE_URL"
echo "Health check: curl $SERVICE_URL/api/v1/health"
```

```bash
chmod +x infrastructure/gcp/10-deploy-backend.sh
```

**Step 7: Commit deployment script**

```bash
git add infrastructure/gcp/10-deploy-backend.sh
git commit -m "infra: Add Cloud Run backend deployment script"
```

---

## Phase 7: Load Balancer & SSL Setup

### Task 12: Reserve Static IP and Create Backend Services

**Files:**
- Create: `infrastructure/gcp/11-load-balancer.sh`

**Step 1: Reserve global static IP**

```bash
gcloud compute addresses create ga-personal-ip \
  --global \
  --ip-version=IPV4 \
  --project=guialmeidapersonal
```

Expected: "Created address [ga-personal-ip]"

**Step 2: Get reserved IP address**

```bash
gcloud compute addresses describe ga-personal-ip \
  --global \
  --project=guialmeidapersonal \
  --format="value(address)"
```

Expected: Shows IP address (e.g., 35.x.x.x)

**Step 3: Create backend bucket for admin frontend**

```bash
gcloud compute backend-buckets create admin-backend \
  --gcs-bucket-name=admin-guialmeidapersonal \
  --enable-cdn \
  --cache-mode=CACHE_ALL_STATIC \
  --default-ttl=3600 \
  --max-ttl=86400 \
  --client-ttl=3600 \
  --project=guialmeidapersonal
```

Expected: "Created backend bucket [admin-backend]"

**Step 4: Create backend bucket for app frontend**

```bash
gcloud compute backend-buckets create app-backend \
  --gcs-bucket-name=app-guialmeidapersonal \
  --enable-cdn \
  --cache-mode=CACHE_ALL_STATIC \
  --default-ttl=3600 \
  --max-ttl=86400 \
  --client-ttl=3600 \
  --project=guialmeidapersonal
```

**Step 5: Create backend bucket for site frontend**

```bash
gcloud compute backend-buckets create site-backend \
  --gcs-bucket-name=site-guialmeidapersonal \
  --enable-cdn \
  --cache-mode=CACHE_ALL_STATIC \
  --default-ttl=3600 \
  --max-ttl=86400 \
  --client-ttl=3600 \
  --project=guialmeidapersonal
```

**Step 6: Create NEG (Network Endpoint Group) for Cloud Run**

```bash
gcloud compute network-endpoint-groups create api-neg \
  --region=southamerica-east1 \
  --network-endpoint-type=serverless \
  --cloud-run-service=ga-personal-api \
  --project=guialmeidapersonal
```

Expected: "Created network endpoint group [api-neg]"

**Step 7: Create backend service for API**

```bash
gcloud compute backend-services create api-backend \
  --global \
  --load-balancing-scheme=EXTERNAL_MANAGED \
  --protocol=HTTP \
  --enable-cdn \
  --project=guialmeidapersonal

gcloud compute backend-services add-backend api-backend \
  --global \
  --network-endpoint-group=api-neg \
  --network-endpoint-group-region=southamerica-east1 \
  --project=guialmeidapersonal
```

Expected: "Created backend service [api-backend]" and "Updated backend service [api-backend]"

**Step 8: Commit load balancer setup (partial)**

```bash
git add -A
git commit -m "infra: Add static IP and backend services for load balancer"
```

---

### Task 13: Create URL Map and HTTP(S) Target Proxies

**Files:**
- Modify: `infrastructure/gcp/11-load-balancer.sh` (continued)

**Step 1: Create URL map with path routing**

```bash
gcloud compute url-maps create ga-personal-lb \
  --default-backend-bucket=site-backend \
  --project=guialmeidapersonal
```

Expected: "Created URL map [ga-personal-lb]"

**Step 2: Add path matchers for different subdomains**

```bash
# Add API path matcher
gcloud compute url-maps add-path-matcher ga-personal-lb \
  --path-matcher-name=api-matcher \
  --default-service=api-backend \
  --new-hosts=api.guialmeidapersonal.esp.br \
  --project=guialmeidapersonal

# Add admin path matcher
gcloud compute url-maps add-path-matcher ga-personal-lb \
  --path-matcher-name=admin-matcher \
  --default-backend-bucket=admin-backend \
  --new-hosts=admin.guialmeidapersonal.esp.br \
  --project=guialmeidapersonal

# Add app path matcher
gcloud compute url-maps add-path-matcher ga-personal-lb \
  --path-matcher-name=app-matcher \
  --default-backend-bucket=app-backend \
  --new-hosts=app.guialmeidapersonal.esp.br \
  --project=guialmeidapersonal
```

Expected: "Updated URL map [ga-personal-lb]" for each

**Step 3: Create HTTP target proxy for redirect**

```bash
gcloud compute target-http-proxies create ga-personal-http-proxy \
  --url-map=ga-personal-lb \
  --project=guialmeidapersonal
```

Expected: "Created target HTTP proxy [ga-personal-http-proxy]"

**Step 4: Create forwarding rule for HTTP (port 80)**

```bash
gcloud compute forwarding-rules create ga-personal-http-rule \
  --global \
  --target-http-proxy=ga-personal-http-proxy \
  --address=ga-personal-ip \
  --ports=80 \
  --project=guialmeidapersonal
```

Expected: "Created forwarding rule [ga-personal-http-rule]"

**Step 5: Verify HTTP setup**

```bash
LB_IP=$(gcloud compute addresses describe ga-personal-ip --global --project=guialmeidapersonal --format="value(address)")
curl -H "Host: api.guialmeidapersonal.esp.br" http://$LB_IP/api/v1/health
```

Expected: Response from API (may be slow on first request)

**Step 6: Commit URL map configuration**

```bash
git add -A
git commit -m "infra: Add URL map and HTTP target proxy for load balancer"
```

---

### Task 14: Configure SSL Certificate and HTTPS

**Files:**
- Modify: `infrastructure/gcp/11-load-balancer.sh` (continued)

**Step 1: Wait for DNS to be ready (if not already)**

```bash
echo "Waiting for DNS name servers to be functional..."
echo "Name servers should be ready in a few minutes"
echo "Check with: dig guialmeidapersonal.esp.br"
```

**Step 2: Create SSL certificate with Certificate Manager**

```bash
gcloud certificate-manager certificates create ga-personal-cert \
  --domains="guialmeidapersonal.esp.br,*.guialmeidapersonal.esp.br" \
  --project=guialmeidapersonal
```

Expected: "Created certificate [ga-personal-cert]"

Note: Certificate provisioning takes 15-60 minutes after DNS is configured

**Step 3: Create certificate map**

```bash
gcloud certificate-manager maps create ga-personal-cert-map \
  --project=guialmeidapersonal
```

**Step 4: Create certificate map entries**

```bash
gcloud certificate-manager maps entries create ga-personal-cert-entry \
  --map=ga-personal-cert-map \
  --certificates=ga-personal-cert \
  --hostname="guialmeidapersonal.esp.br" \
  --project=guialmeidapersonal

gcloud certificate-manager maps entries create ga-personal-wildcard-entry \
  --map=ga-personal-cert-map \
  --certificates=ga-personal-cert \
  --hostname="*.guialmeidapersonal.esp.br" \
  --project=guialmeidapersonal
```

Expected: "Created certificate map entry [...]" for each

**Step 5: Create HTTPS target proxy**

```bash
gcloud compute target-https-proxies create ga-personal-https-proxy \
  --url-map=ga-personal-lb \
  --certificate-map=ga-personal-cert-map \
  --project=guialmeidapersonal
```

Expected: "Created target HTTPS proxy [ga-personal-https-proxy]"

**Step 6: Create forwarding rule for HTTPS (port 443)**

```bash
gcloud compute forwarding-rules create ga-personal-https-rule \
  --global \
  --target-https-proxy=ga-personal-https-proxy \
  --address=ga-personal-ip \
  --ports=443 \
  --project=guialmeidapersonal
```

Expected: "Created forwarding rule [ga-personal-https-rule]"

**Step 7: Update HTTP proxy to redirect to HTTPS**

```bash
gcloud compute url-maps import ga-personal-lb \
  --source=/dev/stdin \
  --project=guialmeidapersonal <<'EOF'
name: ga-personal-lb
defaultService: https://www.googleapis.com/compute/v1/projects/guialmeidapersonal/global/backendBuckets/site-backend
hostRules:
- hosts:
  - api.guialmeidapersonal.esp.br
  pathMatcher: api-matcher
- hosts:
  - admin.guialmeidapersonal.esp.br
  pathMatcher: admin-matcher
- hosts:
  - app.guialmeidapersonal.esp.br
  pathMatcher: app-matcher
pathMatchers:
- name: api-matcher
  defaultService: https://www.googleapis.com/compute/v1/projects/guialmeidapersonal/global/backendServices/api-backend
- name: admin-matcher
  defaultService: https://www.googleapis.com/compute/v1/projects/guialmeidapersonal/global/backendBuckets/admin-backend
- name: app-matcher
  defaultService: https://www.googleapis.com/compute/v1/projects/guialmeidapersonal/global/backendBuckets/app-backend
EOF
```

**Step 8: Check certificate status**

```bash
gcloud certificate-manager certificates describe ga-personal-cert \
  --project=guialmeidapersonal
```

Expected: Status shows "PROVISIONING" or "ACTIVE" (ACTIVE means ready)

**Step 9: Create complete load balancer setup script**

Create file: `infrastructure/gcp/11-load-balancer.sh`

```bash
#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"

echo "Step 1: Reserve static IP..."
gcloud compute addresses create ga-personal-ip \
  --global \
  --ip-version=IPV4 \
  --project=$PROJECT_ID || echo "IP already exists"

LB_IP=$(gcloud compute addresses describe ga-personal-ip --global --project=$PROJECT_ID --format="value(address)")
echo "Load Balancer IP: $LB_IP"

echo ""
echo "Step 2: Create backend buckets..."
for bucket in admin app site; do
  gcloud compute backend-buckets create ${bucket}-backend \
    --gcs-bucket-name=${bucket}-guialmeidapersonal \
    --enable-cdn \
    --cache-mode=CACHE_ALL_STATIC \
    --default-ttl=3600 \
    --max-ttl=86400 \
    --client-ttl=3600 \
    --project=$PROJECT_ID || echo "${bucket}-backend already exists"
done

echo ""
echo "Step 3: Create NEG for Cloud Run..."
gcloud compute network-endpoint-groups create api-neg \
  --region=$REGION \
  --network-endpoint-type=serverless \
  --cloud-run-service=ga-personal-api \
  --project=$PROJECT_ID || echo "api-neg already exists"

echo ""
echo "Step 4: Create backend service for API..."
gcloud compute backend-services create api-backend \
  --global \
  --load-balancing-scheme=EXTERNAL_MANAGED \
  --protocol=HTTP \
  --enable-cdn \
  --project=$PROJECT_ID || echo "api-backend already exists"

gcloud compute backend-services add-backend api-backend \
  --global \
  --network-endpoint-group=api-neg \
  --network-endpoint-group-region=$REGION \
  --project=$PROJECT_ID || echo "Backend already added"

echo ""
echo "Step 5: Create URL map..."
gcloud compute url-maps create ga-personal-lb \
  --default-backend-bucket=site-backend \
  --project=$PROJECT_ID || echo "URL map already exists"

echo ""
echo "Step 6: Add path matchers..."
gcloud compute url-maps add-path-matcher ga-personal-lb \
  --path-matcher-name=api-matcher \
  --default-service=api-backend \
  --new-hosts=api.guialmeidapersonal.esp.br \
  --project=$PROJECT_ID || echo "api-matcher exists"

gcloud compute url-maps add-path-matcher ga-personal-lb \
  --path-matcher-name=admin-matcher \
  --default-backend-bucket=admin-backend \
  --new-hosts=admin.guialmeidapersonal.esp.br \
  --project=$PROJECT_ID || echo "admin-matcher exists"

gcloud compute url-maps add-path-matcher ga-personal-lb \
  --path-matcher-name=app-matcher \
  --default-backend-bucket=app-backend \
  --new-hosts=app.guialmeidapersonal.esp.br \
  --project=$PROJECT_ID || echo "app-matcher exists"

echo ""
echo "Step 7: Create HTTP proxy and forwarding rule..."
gcloud compute target-http-proxies create ga-personal-http-proxy \
  --url-map=ga-personal-lb \
  --project=$PROJECT_ID || echo "HTTP proxy exists"

gcloud compute forwarding-rules create ga-personal-http-rule \
  --global \
  --target-http-proxy=ga-personal-http-proxy \
  --address=ga-personal-ip \
  --ports=80 \
  --project=$PROJECT_ID || echo "HTTP rule exists"

echo ""
echo "Step 8: Create SSL certificate (DNS must be configured first)..."
gcloud certificate-manager certificates create ga-personal-cert \
  --domains="guialmeidapersonal.esp.br,*.guialmeidapersonal.esp.br" \
  --project=$PROJECT_ID || echo "Certificate exists"

echo ""
echo "Step 9: Create certificate map..."
gcloud certificate-manager maps create ga-personal-cert-map \
  --project=$PROJECT_ID || echo "Certificate map exists"

gcloud certificate-manager maps entries create ga-personal-cert-entry \
  --map=ga-personal-cert-map \
  --certificates=ga-personal-cert \
  --hostname="guialmeidapersonal.esp.br" \
  --project=$PROJECT_ID || echo "Cert entry exists"

gcloud certificate-manager maps entries create ga-personal-wildcard-entry \
  --map=ga-personal-cert-map \
  --certificates=ga-personal-cert \
  --hostname="*.guialmeidapersonal.esp.br" \
  --project=$PROJECT_ID || echo "Wildcard entry exists"

echo ""
echo "Step 10: Create HTTPS proxy and forwarding rule..."
gcloud compute target-https-proxies create ga-personal-https-proxy \
  --url-map=ga-personal-lb \
  --certificate-map=ga-personal-cert-map \
  --project=$PROJECT_ID || echo "HTTPS proxy exists"

gcloud compute forwarding-rules create ga-personal-https-rule \
  --global \
  --target-https-proxy=ga-personal-https-proxy \
  --address=ga-personal-ip \
  --ports=443 \
  --project=$PROJECT_ID || echo "HTTPS rule exists"

echo ""
echo "Load Balancer setup complete!"
echo ""
echo "Load Balancer IP: $LB_IP"
echo ""
echo "Next steps:"
echo "1. Configure DNS to point all domains to $LB_IP"
echo "2. Wait for SSL certificate to provision (15-60 minutes)"
echo "3. Check certificate status:"
echo "   gcloud certificate-manager certificates describe ga-personal-cert --project=$PROJECT_ID"
```

```bash
chmod +x infrastructure/gcp/11-load-balancer.sh
```

**Step 10: Commit complete load balancer configuration**

```bash
git add infrastructure/gcp/11-load-balancer.sh
git commit -m "infra: Add complete load balancer with SSL certificate configuration"
```

---

## Phase 8: DNS Configuration

### Task 15: Configure Cloud DNS Records

**Files:**
- Create: `infrastructure/gcp/12-dns.sh`

**Step 1: Get load balancer IP**

```bash
LB_IP=$(gcloud compute addresses describe ga-personal-ip --global --project=guialmeidapersonal --format="value(address)")
echo "Load Balancer IP: $LB_IP"
```

**Step 2: Check if hosted zone exists**

```bash
gcloud dns managed-zones list --project=guialmeidapersonal
```

Expected: Shows existing zone for guialmeidapersonal.esp.br (or empty if not created yet)

**Step 3: Create hosted zone if it doesn't exist**

```bash
gcloud dns managed-zones create guialmeidapersonal-zone \
  --dns-name="guialmeidapersonal.esp.br." \
  --description="DNS zone for GA Personal" \
  --project=guialmeidapersonal || echo "Zone already exists"
```

**Step 4: Get name servers**

```bash
gcloud dns managed-zones describe guialmeidapersonal-zone \
  --project=guialmeidapersonal \
  --format="value(nameServers)"
```

Expected: Shows 4 name servers (these should match the ones configured for the domain)

**Step 5: Start DNS transaction**

```bash
gcloud dns record-sets transaction start \
  --zone=guialmeidapersonal-zone \
  --project=guialmeidapersonal
```

**Step 6: Add A records for all subdomains**

```bash
# Root domain
gcloud dns record-sets transaction add $LB_IP \
  --name="guialmeidapersonal.esp.br." \
  --ttl=300 \
  --type=A \
  --zone=guialmeidapersonal-zone \
  --project=guialmeidapersonal

# API subdomain
gcloud dns record-sets transaction add $LB_IP \
  --name="api.guialmeidapersonal.esp.br." \
  --ttl=300 \
  --type=A \
  --zone=guialmeidapersonal-zone \
  --project=guialmeidapersonal

# Admin subdomain
gcloud dns record-sets transaction add $LB_IP \
  --name="admin.guialmeidapersonal.esp.br." \
  --ttl=300 \
  --type=A \
  --zone=guialmeidapersonal-zone \
  --project=guialmeidapersonal

# App subdomain
gcloud dns record-sets transaction add $LB_IP \
  --name="app.guialmeidapersonal.esp.br." \
  --ttl=300 \
  --type=A \
  --zone=guialmeidapersonal-zone \
  --project=guialmeidapersonal

# WWW subdomain
gcloud dns record-sets transaction add $LB_IP \
  --name="www.guialmeidapersonal.esp.br." \
  --ttl=300 \
  --type=A \
  --zone=guialmeidapersonal-zone \
  --project=guialmeidapersonal
```

**Step 7: Execute DNS transaction**

```bash
gcloud dns record-sets transaction execute \
  --zone=guialmeidapersonal-zone \
  --project=guialmeidapersonal
```

Expected: "Executed transaction"

**Step 8: Verify DNS records**

```bash
gcloud dns record-sets list \
  --zone=guialmeidapersonal-zone \
  --project=guialmeidapersonal
```

Expected: Shows all A records pointing to load balancer IP

**Step 9: Test DNS resolution**

```bash
dig api.guialmeidapersonal.esp.br
dig admin.guialmeidapersonal.esp.br
dig app.guialmeidapersonal.esp.br
```

Expected: Shows A records pointing to load balancer IP (may take a few minutes to propagate)

**Step 10: Create DNS configuration script**

Create file: `infrastructure/gcp/12-dns.sh`

```bash
#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
ZONE_NAME="guialmeidapersonal-zone"
DNS_NAME="guialmeidapersonal.esp.br."

echo "Getting load balancer IP..."
LB_IP=$(gcloud compute addresses describe ga-personal-ip --global --project=$PROJECT_ID --format="value(address)")
echo "Load Balancer IP: $LB_IP"

echo ""
echo "Creating DNS zone (if not exists)..."
gcloud dns managed-zones create $ZONE_NAME \
  --dns-name="$DNS_NAME" \
  --description="DNS zone for GA Personal" \
  --project=$PROJECT_ID || echo "Zone already exists"

echo ""
echo "Getting name servers..."
NAME_SERVERS=$(gcloud dns managed-zones describe $ZONE_NAME --project=$PROJECT_ID --format="value(nameServers)")
echo "Name servers (configure these at your domain registrar):"
echo "$NAME_SERVERS"

echo ""
echo "Starting DNS transaction..."
gcloud dns record-sets transaction start \
  --zone=$ZONE_NAME \
  --project=$PROJECT_ID

echo "Adding A records..."
for subdomain in "" "api" "admin" "app" "www"; do
  if [ -z "$subdomain" ]; then
    FQDN="$DNS_NAME"
  else
    FQDN="${subdomain}.${DNS_NAME}"
  fi

  gcloud dns record-sets transaction add $LB_IP \
    --name="$FQDN" \
    --ttl=300 \
    --type=A \
    --zone=$ZONE_NAME \
    --project=$PROJECT_ID || echo "Record for $FQDN already exists"
done

echo ""
echo "Executing transaction..."
gcloud dns record-sets transaction execute \
  --zone=$ZONE_NAME \
  --project=$PROJECT_ID || gcloud dns record-sets transaction abort --zone=$ZONE_NAME --project=$PROJECT_ID

echo ""
echo "DNS configuration complete!"
echo ""
echo "Verify records:"
gcloud dns record-sets list --zone=$ZONE_NAME --project=$PROJECT_ID
echo ""
echo "Test DNS resolution (may take a few minutes to propagate):"
echo "  dig api.guialmeidapersonal.esp.br"
echo "  dig admin.guialmeidapersonal.esp.br"
echo "  dig app.guialmeidapersonal.esp.br"
```

```bash
chmod +x infrastructure/gcp/12-dns.sh
```

**Step 11: Commit DNS configuration**

```bash
git add infrastructure/gcp/12-dns.sh
git commit -m "infra: Add DNS configuration for all subdomains"
```

---

## Phase 9: Frontend Deployment

### Task 16: Build and Deploy Frontend Applications

**Files:**
- Create: `infrastructure/gcp/13-deploy-frontends.sh`

**Step 1: Build trainer-app (admin)**

```bash
cd /Users/luizpenha/guipersonal/frontend/trainer-app

# Install dependencies
npm install

# Build for production
VITE_API_URL=https://api.guialmeidapersonal.esp.br npm run build
```

Expected: "dist/" directory created with build artifacts

**Step 2: Upload trainer-app to Cloud Storage**

```bash
gsutil -m rsync -r -d dist/ gs://admin-guialmeidapersonal/
```

Expected: "Copying file://..." for each file

**Step 3: Set cache control headers**

```bash
# Set long cache for static assets
gsutil -m setmeta -h "Cache-Control:public, max-age=31536000, immutable" \
  'gs://admin-guialmeidapersonal/assets/**'

# Set short cache for HTML
gsutil -m setmeta -h "Cache-Control:public, max-age=300" \
  'gs://admin-guialmeidapersonal/*.html'
```

**Step 4: Build student-app**

```bash
cd /Users/luizpenha/guipersonal/frontend/student-app

npm install
VITE_API_URL=https://api.guialmeidapersonal.esp.br npm run build
```

**Step 5: Upload student-app to Cloud Storage**

```bash
gsutil -m rsync -r -d dist/ gs://app-guialmeidapersonal/

gsutil -m setmeta -h "Cache-Control:public, max-age=31536000, immutable" \
  'gs://app-guialmeidapersonal/assets/**'

gsutil -m setmeta -h "Cache-Control:public, max-age=300" \
  'gs://app-guialmeidapersonal/*.html'
```

**Step 6: Build site (VitePress)**

```bash
cd /Users/luizpenha/guipersonal/frontend/site

npm install
npm run build
```

Expected: "docs/.vitepress/dist/" directory created

**Step 7: Upload site to Cloud Storage**

```bash
gsutil -m rsync -r -d docs/.vitepress/dist/ gs://site-guialmeidapersonal/

gsutil -m setmeta -h "Cache-Control:public, max-age=31536000, immutable" \
  'gs://site-guialmeidapersonal/assets/**'

gsutil -m setmeta -h "Cache-Control:public, max-age=300" \
  'gs://site-guialmeidapersonal/*.html'
```

**Step 8: Invalidate CDN cache**

```bash
gcloud compute url-maps invalidate-cdn-cache ga-personal-lb \
  --path="/*" \
  --async \
  --project=guialmeidapersonal
```

Expected: "Invalidation pending"

**Step 9: Create frontend deployment script**

Create file: `infrastructure/gcp/13-deploy-frontends.sh`

```bash
#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
API_URL="https://api.guialmeidapersonal.esp.br"
PROJECT_ROOT="/Users/luizpenha/guipersonal"

echo "Building and deploying frontends..."
echo "API URL: $API_URL"

# Build and deploy trainer-app
echo ""
echo "=== Trainer App (Admin) ==="
cd $PROJECT_ROOT/frontend/trainer-app
npm install
VITE_API_URL=$API_URL npm run build

echo "Uploading to Cloud Storage..."
gsutil -m rsync -r -d dist/ gs://admin-guialmeidapersonal/

echo "Setting cache headers..."
gsutil -m setmeta -h "Cache-Control:public, max-age=31536000, immutable" \
  'gs://admin-guialmeidapersonal/assets/**' || true
gsutil -m setmeta -h "Cache-Control:public, max-age=300" \
  'gs://admin-guialmeidapersonal/*.html' || true

# Build and deploy student-app
echo ""
echo "=== Student App ==="
cd $PROJECT_ROOT/frontend/student-app
npm install
VITE_API_URL=$API_URL npm run build

echo "Uploading to Cloud Storage..."
gsutil -m rsync -r -d dist/ gs://app-guialmeidapersonal/

echo "Setting cache headers..."
gsutil -m setmeta -h "Cache-Control:public, max-age=31536000, immutable" \
  'gs://app-guialmeidapersonal/assets/**' || true
gsutil -m setmeta -h "Cache-Control:public, max-age=300" \
  'gs://app-guialmeidapersonal/*.html' || true

# Build and deploy site
echo ""
echo "=== Marketing Site ==="
cd $PROJECT_ROOT/frontend/site
npm install
npm run build

echo "Uploading to Cloud Storage..."
gsutil -m rsync -r -d docs/.vitepress/dist/ gs://site-guialmeidapersonal/

echo "Setting cache headers..."
gsutil -m setmeta -h "Cache-Control:public, max-age=31536000, immutable" \
  'gs://site-guialmeidapersonal/assets/**' || true
gsutil -m setmeta -h "Cache-Control:public, max-age=300" \
  'gs://site-guialmeidapersonal/*.html' || true

# Invalidate CDN cache
echo ""
echo "Invalidating CDN cache..."
gcloud compute url-maps invalidate-cdn-cache ga-personal-lb \
  --path="/*" \
  --async \
  --project=$PROJECT_ID

cd $PROJECT_ROOT

echo ""
echo "Frontend deployment complete!"
echo "Admin: https://admin.guialmeidapersonal.esp.br"
echo "App: https://app.guialmeidapersonal.esp.br"
echo "Site: https://guialmeidapersonal.esp.br"
```

```bash
chmod +x infrastructure/gcp/13-deploy-frontends.sh
```

**Step 10: Test frontend applications**

```bash
# Test admin
curl -I https://admin.guialmeidapersonal.esp.br

# Test app
curl -I https://app.guialmeidapersonal.esp.br

# Test site
curl -I https://guialmeidapersonal.esp.br
```

Expected: 200 OK responses (may show certificate errors until SSL is fully provisioned)

**Step 11: Commit frontend deployment script**

```bash
cd /Users/luizpenha/guipersonal
git add infrastructure/gcp/13-deploy-frontends.sh
git commit -m "infra: Add frontend build and deployment script"
```

---

## Phase 10: CI/CD Setup

### Task 17: Configure GitHub Actions Workflows

**Files:**
- Create: `.github/workflows/deploy-backend.yml`
- Create: `.github/workflows/deploy-frontend.yml`

**Step 1: Create Workload Identity Federation pool**

```bash
gcloud iam workload-identity-pools create github-pool \
  --location="global" \
  --display-name="GitHub Actions Pool" \
  --project=guialmeidapersonal
```

Expected: "Created workload identity pool [github-pool]"

**Step 2: Create Workload Identity provider**

```bash
gcloud iam workload-identity-pools providers create-oidc github-provider \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.actor=assertion.actor" \
  --attribute-condition="assertion.repository=='luizavanter/guialmeidapersonal'" \
  --project=guialmeidapersonal
```

Expected: "Created workload identity pool provider [github-provider]"

**Step 3: Grant CI/CD service account permissions to Workload Identity**

```bash
gcloud iam service-accounts add-iam-policy-binding cicd-sa@guialmeidapersonal.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$(gcloud projects describe guialmeidapersonal --format='value(projectNumber)')/locations/global/workloadIdentityPools/github-pool/attribute.repository/luizavanter/guialmeidapersonal" \
  --project=guialmeidapersonal
```

Expected: "Updated IAM policy for service account [cicd-sa]"

**Step 4: Get Workload Identity Provider resource name**

```bash
gcloud iam workload-identity-pools providers describe github-provider \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --project=guialmeidapersonal \
  --format="value(name)"
```

Expected: Resource name like `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider`

**Step 5: Create backend deployment workflow**

Create file: `.github/workflows/deploy-backend.yml`

```yaml
name: Deploy Backend to Cloud Run

on:
  push:
    branches:
      - main
    paths:
      - 'apps/**'
      - 'config/**'
      - 'mix.exs'
      - 'mix.lock'
      - 'Dockerfile'
      - '.github/workflows/deploy-backend.yml'

env:
  PROJECT_ID: guialmeidapersonal
  REGION: southamerica-east1
  SERVICE_NAME: ga-personal-api
  REGISTRY: southamerica-east1-docker.pkg.dev
  REPOSITORY: ga-personal
  IMAGE_NAME: backend

permissions:
  contents: read
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: 'projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider'
          service_account: 'cicd-sa@guialmeidapersonal.iam.gserviceaccount.com'

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Configure Docker for Artifact Registry
        run: |
          gcloud auth configure-docker ${{ env.REGISTRY }}

      - name: Build Docker image
        run: |
          docker build -t ${{ env.REGISTRY }}/${{ env.PROJECT_ID }}/${{ env.REPOSITORY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} .
          docker tag ${{ env.REGISTRY }}/${{ env.PROJECT_ID }}/${{ env.REPOSITORY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} \
                     ${{ env.REGISTRY }}/${{ env.PROJECT_ID }}/${{ env.REPOSITORY }}/${{ env.IMAGE_NAME }}:latest

      - name: Push Docker image
        run: |
          docker push ${{ env.REGISTRY }}/${{ env.PROJECT_ID }}/${{ env.REPOSITORY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          docker push ${{ env.REGISTRY }}/${{ env.PROJECT_ID }}/${{ env.REPOSITORY }}/${{ env.IMAGE_NAME }}:latest

      - name: Run database migrations
        run: |
          gcloud run jobs execute ga-personal-migrate \
            --region=${{ env.REGION }} \
            --project=${{ env.PROJECT_ID }} \
            --wait || echo "Migration job failed or doesn't exist"

      - name: Deploy to Cloud Run
        run: |
          gcloud run deploy ${{ env.SERVICE_NAME }} \
            --image=${{ env.REGISTRY }}/${{ env.PROJECT_ID }}/${{ env.REPOSITORY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} \
            --region=${{ env.REGION }} \
            --platform=managed \
            --service-account=backend-sa@${{ env.PROJECT_ID }}.iam.gserviceaccount.com \
            --vpc-connector=ga-personal-vpc-connector \
            --vpc-egress=private-ranges-only \
            --min-instances=0 \
            --max-instances=10 \
            --cpu=1 \
            --memory=512Mi \
            --timeout=300s \
            --concurrency=80 \
            --ingress=internal-and-cloud-load-balancing \
            --set-secrets=DATABASE_URL=database-url:latest,REDIS_URL=redis-url:latest,JWT_SECRET=jwt-secret:latest,SECRET_KEY_BASE=secret-key-base:latest \
            --port=4000 \
            --allow-unauthenticated \
            --project=${{ env.PROJECT_ID }}

      - name: Verify deployment
        run: |
          SERVICE_URL=$(gcloud run services describe ${{ env.SERVICE_NAME }} \
            --region=${{ env.REGION }} \
            --project=${{ env.PROJECT_ID }} \
            --format="value(status.url)")

          echo "Service deployed to: $SERVICE_URL"
          curl -f $SERVICE_URL/api/v1/health || exit 1
```

**Step 6: Create frontend deployment workflow**

Create file: `.github/workflows/deploy-frontend.yml`

```yaml
name: Deploy Frontends to Cloud Storage

on:
  push:
    branches:
      - main
    paths:
      - 'frontend/**'
      - '.github/workflows/deploy-frontend.yml'

env:
  PROJECT_ID: guialmeidapersonal
  API_URL: https://api.guialmeidapersonal.esp.br

permissions:
  contents: read
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: |
            frontend/trainer-app/package-lock.json
            frontend/student-app/package-lock.json
            frontend/site/package-lock.json

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: 'projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider'
          service_account: 'cicd-sa@guialmeidapersonal.iam.gserviceaccount.com'

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Build Trainer App
        working-directory: ./frontend/trainer-app
        run: |
          npm ci
          VITE_API_URL=${{ env.API_URL }} npm run build

      - name: Deploy Trainer App
        run: |
          gsutil -m rsync -r -d frontend/trainer-app/dist/ gs://admin-guialmeidapersonal/
          gsutil -m setmeta -h "Cache-Control:public, max-age=31536000, immutable" \
            'gs://admin-guialmeidapersonal/assets/**' || true
          gsutil -m setmeta -h "Cache-Control:public, max-age=300" \
            'gs://admin-guialmeidapersonal/*.html' || true

      - name: Build Student App
        working-directory: ./frontend/student-app
        run: |
          npm ci
          VITE_API_URL=${{ env.API_URL }} npm run build

      - name: Deploy Student App
        run: |
          gsutil -m rsync -r -d frontend/student-app/dist/ gs://app-guialmeidapersonal/
          gsutil -m setmeta -h "Cache-Control:public, max-age=31536000, immutable" \
            'gs://app-guialmeidapersonal/assets/**' || true
          gsutil -m setmeta -h "Cache-Control:public, max-age=300" \
            'gs://app-guialmeidapersonal/*.html' || true

      - name: Build Marketing Site
        working-directory: ./frontend/site
        run: |
          npm ci
          npm run build

      - name: Deploy Marketing Site
        run: |
          gsutil -m rsync -r -d frontend/site/docs/.vitepress/dist/ gs://site-guialmeidapersonal/
          gsutil -m setmeta -h "Cache-Control:public, max-age=31536000, immutable" \
            'gs://site-guialmeidapersonal/assets/**' || true
          gsutil -m setmeta -h "Cache-Control:public, max-age=300" \
            'gs://site-guialmeidapersonal/*.html' || true

      - name: Invalidate CDN Cache
        run: |
          gcloud compute url-maps invalidate-cdn-cache ga-personal-lb \
            --path="/*" \
            --async \
            --project=${{ env.PROJECT_ID }}

      - name: Verify deployments
        run: |
          echo "✅ Admin: https://admin.guialmeidapersonal.esp.br"
          echo "✅ App: https://app.guialmeidapersonal.esp.br"
          echo "✅ Site: https://guialmeidapersonal.esp.br"
```

**Step 7: Update workflows with actual PROJECT_NUMBER**

```bash
PROJECT_NUMBER=$(gcloud projects describe guialmeidapersonal --format='value(projectNumber)')
echo "Project Number: $PROJECT_NUMBER"

# Update in both workflow files
sed -i '' "s/PROJECT_NUMBER/$PROJECT_NUMBER/g" .github/workflows/deploy-backend.yml
sed -i '' "s/PROJECT_NUMBER/$PROJECT_NUMBER/g" .github/workflows/deploy-frontend.yml
```

**Step 8: Commit CI/CD workflows**

```bash
git add .github/workflows/
git commit -m "ci: Add GitHub Actions workflows for automated deployment"
```

**Step 9: Push to GitHub and test CI/CD**

```bash
# Add GitHub remote (using SSH as specified)
git remote add origin git@github.com:luizavanter/guialmeidapersonal.git

# Push to GitHub
git push -u origin main
```

Expected: GitHub Actions workflows trigger automatically

**Step 10: Monitor workflow execution**

```bash
# Check in GitHub Actions UI
open https://github.com/luizavanter/guialmeidapersonal/actions
```

Expected: Both workflows run successfully

---

## Phase 11: Monitoring & Verification

### Task 18: Set Up Cloud Monitoring

**Files:**
- Create: `infrastructure/gcp/14-monitoring.sh`

**Step 1: Create uptime check for API**

```bash
gcloud monitoring uptime create ga-personal-api-health \
  --display-name="GA Personal API Health Check" \
  --resource-type=uptime-url \
  --host=api.guialmeidapersonal.esp.br \
  --path=/api/v1/health \
  --port=443 \
  --protocol=https \
  --period=60 \
  --timeout=10s \
  --project=guialmeidapersonal
```

Expected: "Created uptime check [ga-personal-api-health]"

**Step 2: Create alert policy for high error rate**

```bash
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="High Error Rate Alert" \
  --condition-display-name="5xx errors > 5%" \
  --condition-expression='
    resource.type = "cloud_run_revision"
    AND resource.labels.service_name = "ga-personal-api"
    AND metric.type = "run.googleapis.com/request_count"
    AND metric.labels.response_code_class = "5xx"' \
  --condition-threshold-value=0.05 \
  --condition-threshold-duration=300s \
  --project=guialmeidapersonal
```

Note: Create notification channels first in Cloud Console

**Step 3: Create monitoring dashboard**

Create file: `infrastructure/gcp/dashboard-config.json`

```json
{
  "displayName": "GA Personal Monitoring",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Cloud Run Request Count",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"ga-personal-api\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_RATE"
                  }
                }
              }
            }]
          }
        }
      }
    ]
  }
}
```

```bash
gcloud monitoring dashboards create --config-from-file=infrastructure/gcp/dashboard-config.json --project=guialmeidapersonal
```

**Step 4: Create monitoring setup script**

Create file: `infrastructure/gcp/14-monitoring.sh`

```bash
#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"

echo "Setting up monitoring..."

echo "Creating uptime checks..."
gcloud monitoring uptime create ga-personal-api-health \
  --display-name="GA Personal API Health Check" \
  --resource-type=uptime-url \
  --host=api.guialmeidapersonal.esp.br \
  --path=/api/v1/health \
  --port=443 \
  --protocol=https \
  --period=60 \
  --timeout=10s \
  --project=$PROJECT_ID || echo "Uptime check exists"

echo ""
echo "Monitoring setup complete!"
echo ""
echo "View dashboards:"
echo "  https://console.cloud.google.com/monitoring/dashboards?project=$PROJECT_ID"
echo ""
echo "Set up alert notifications:"
echo "  https://console.cloud.google.com/monitoring/alerting?project=$PROJECT_ID"
```

```bash
chmod +x infrastructure/gcp/14-monitoring.sh
```

**Step 5: Commit monitoring configuration**

```bash
git add infrastructure/gcp/14-monitoring.sh infrastructure/gcp/dashboard-config.json
git commit -m "infra: Add Cloud Monitoring configuration"
```

---

### Task 19: Final Verification and Documentation

**Files:**
- Create: `infrastructure/gcp/DEPLOYMENT.md`

**Step 1: Test all endpoints**

```bash
# Test API health
curl https://api.guialmeidapersonal.esp.br/api/v1/health

# Test admin frontend
curl -I https://admin.guialmeidapersonal.esp.br

# Test app frontend
curl -I https://app.guialmeidapersonal.esp.br

# Test marketing site
curl -I https://guialmeidapersonal.esp.br

# Test SSL certificate
openssl s_client -connect api.guialmeidapersonal.esp.br:443 -servername api.guialmeidapersonal.esp.br < /dev/null
```

Expected: All return 200 OK, SSL certificate valid

**Step 2: Test authentication flow**

```bash
# Try to login (should work after frontend deployment)
curl -X POST https://api.guialmeidapersonal.esp.br/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"guilherme@gapersonal.com","password":"trainer123"}'
```

Expected: Returns access token and user info

**Step 3: Verify database connectivity**

```bash
# Check Cloud Run logs for database connections
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=ga-personal-api" \
  --limit=50 \
  --format=json \
  --project=guialmeidapersonal | grep -i "database\|postgres"
```

Expected: Shows successful database connections

**Step 4: Check SSL certificate status**

```bash
gcloud certificate-manager certificates describe ga-personal-cert \
  --project=guialmeidapersonal \
  --format="value(managed.state)"
```

Expected: "ACTIVE"

**Step 5: Create deployment documentation**

Create file: `infrastructure/gcp/DEPLOYMENT.md`

```markdown
# GA Personal - GCP Deployment Documentation

## Infrastructure Overview

**Project:** guialmeidapersonal
**Region:** southamerica-east1 (São Paulo)
**Domain:** guialmeidapersonal.esp.br

## Deployed Components

### Backend
- **Cloud Run Service:** ga-personal-api
- **Image:** southamerica-east1-docker.pkg.dev/guialmeidapersonal/ga-personal/backend:latest
- **URL:** https://api.guialmeidapersonal.esp.br
- **Service Account:** backend-sa@guialmeidapersonal.iam.gserviceaccount.com

### Databases
- **Cloud SQL:** ga-personal-db (PostgreSQL 16)
  - Private IP only
  - Automated backups: Daily at 3 AM BRT
- **Memorystore:** ga-personal-redis (Redis 7.0)
  - 1GB Basic tier
  - Private IP only

### Frontends
- **Admin:** https://admin.guialmeidapersonal.esp.br (gs://admin-guialmeidapersonal)
- **App:** https://app.guialmeidapersonal.esp.br (gs://app-guialmeidapersonal)
- **Site:** https://guialmeidapersonal.esp.br (gs://site-guialmeidapersonal)

### Load Balancer
- **IP:** $(gcloud compute addresses describe ga-personal-ip --global --format="value(address)")
- **SSL Certificate:** ga-personal-cert (Google-managed)
- **Backends:** Cloud Run (API) + Cloud Storage (frontends)

## Deployment Scripts

All scripts are in `infrastructure/gcp/`:

1. `01-network.sh` - VPC and subnets
2. `02-vpc-connector.sh` - VPC connector for Cloud Run
3. `03-cloudsql.sh` - PostgreSQL instance
4. `04-redis.sh` - Redis instance
5. `05-service-accounts.sh` - IAM service accounts
6. `06-secrets.sh` - Secret Manager configuration
7. `07-storage.sh` - Cloud Storage buckets
8. `08-artifact-registry.sh` - Docker repository
9. `09-build-backend.sh` - Build and push backend image
10. `10-deploy-backend.sh` - Deploy to Cloud Run
11. `11-load-balancer.sh` - Load balancer and SSL
12. `12-dns.sh` - DNS configuration
13. `13-deploy-frontends.sh` - Build and deploy frontends
14. `14-monitoring.sh` - Monitoring setup

## CI/CD Pipelines

### Backend Pipeline
- **Workflow:** `.github/workflows/deploy-backend.yml`
- **Trigger:** Push to main branch (apps/, config/, Dockerfile changes)
- **Steps:** Build image → Push to Artifact Registry → Run migrations → Deploy to Cloud Run

### Frontend Pipeline
- **Workflow:** `.github/workflows/deploy-frontend.yml`
- **Trigger:** Push to main branch (frontend/ changes)
- **Steps:** Build all frontends → Upload to Cloud Storage → Invalidate CDN cache

## Manual Deployment

### Backend
\`\`\`bash
cd /Users/luizpenha/guipersonal
./infrastructure/gcp/09-build-backend.sh
./infrastructure/gcp/10-deploy-backend.sh
\`\`\`

### Frontend
\`\`\`bash
cd /Users/luizpenha/guipersonal
./infrastructure/gcp/13-deploy-frontends.sh
\`\`\`

## Monitoring

### Dashboards
- **Cloud Console:** https://console.cloud.google.com/monitoring/dashboards?project=guialmeidapersonal
- **Cloud Run:** https://console.cloud.google.com/run?project=guialmeidapersonal

### Logs
\`\`\`bash
# Backend logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=ga-personal-api" --limit=50 --project=guialmeidapersonal

# Load balancer logs
gcloud logging read "resource.type=http_load_balancer" --limit=50 --project=guialmeidapersonal
\`\`\`

### Health Checks
- **API:** curl https://api.guialmeidapersonal.esp.br/api/v1/health
- **Admin:** https://admin.guialmeidapersonal.esp.br
- **App:** https://app.guialmeidapersonal.esp.br
- **Site:** https://guialmeidapersonal.esp.br

## Secrets Management

All secrets stored in Secret Manager:
- `database-url` - PostgreSQL connection string
- `redis-url` - Redis connection string
- `jwt-secret` - JWT signing key
- `secret-key-base` - Phoenix secret

Access secrets:
\`\`\`bash
gcloud secrets versions access latest --secret=database-url --project=guialmeidapersonal
\`\`\`

## Rollback Procedures

### Backend Rollback
\`\`\`bash
# List revisions
gcloud run revisions list --service=ga-personal-api --region=southamerica-east1 --project=guialmeidapersonal

# Rollback to previous revision
gcloud run services update-traffic ga-personal-api \
  --to-revisions=PREVIOUS_REVISION=100 \
  --region=southamerica-east1 \
  --project=guialmeidapersonal
\`\`\`

### Frontend Rollback
\`\`\`bash
# List versions
gsutil ls -a gs://admin-guialmeidapersonal/

# Restore previous version
gsutil cp gs://admin-guialmeidapersonal/index.html#VERSION ./
gsutil cp ./index.html gs://admin-guialmeidapersonal/
\`\`\`

## Cost Monitoring

### Current Estimate
- ~$110-130/month (see design document for breakdown)

### View costs
\`\`\`bash
gcloud billing accounts list
gcloud billing projects describe guialmeidapersonal
\`\`\`

Console: https://console.cloud.google.com/billing?project=guialmeidapersonal

## Troubleshooting

### Backend not responding
1. Check Cloud Run logs
2. Verify database connectivity
3. Check secrets are accessible
4. Verify VPC connector is healthy

### Frontend not loading
1. Check Cloud Storage bucket contents
2. Verify load balancer backend health
3. Check SSL certificate status
4. Invalidate CDN cache

### SSL certificate not provisioning
1. Verify DNS records are correct
2. Wait 15-60 minutes for provisioning
3. Check certificate status: `gcloud certificate-manager certificates describe ga-personal-cert`

### Database connection issues
1. Verify Cloud SQL instance is running
2. Check VPC connector status
3. Verify backend service account has cloudsql.client role
4. Check database credentials in Secret Manager

## Support Contacts

- **GCP Project:** guialmeidapersonal
- **GitHub Repo:** git@github.com:luizavanter/guialmeidapersonal.git
- **Documentation:** `/Users/luizpenha/guipersonal/docs/plans/`
```

**Step 6: Get load balancer IP and update documentation**

```bash
LB_IP=$(gcloud compute addresses describe ga-personal-ip --global --project=guialmeidapersonal --format="value(address)")
sed -i '' "s/\$(gcloud compute addresses describe ga-personal-ip --global --format=\"value(address)\")/$LB_IP/g" infrastructure/gcp/DEPLOYMENT.md
```

**Step 7: Create master deployment script**

Create file: `infrastructure/gcp/deploy-all.sh`

```bash
#!/bin/bash
set -e

PROJECT_ROOT="/Users/luizpenha/guipersonal"
cd $PROJECT_ROOT

echo "========================================="
echo "GA Personal - Complete GCP Deployment"
echo "========================================="
echo ""

# Run all setup scripts in order
for script in infrastructure/gcp/0{1..14}*.sh; do
  if [ -f "$script" ]; then
    echo "Running: $script"
    bash "$script"
    echo ""
    echo "----------------------------------------"
    echo ""
  fi
done

echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "URLs:"
echo "  API: https://api.guialmeidapersonal.esp.br/api/v1/health"
echo "  Admin: https://admin.guialmeidapersonal.esp.br"
echo "  App: https://app.guialmeidapersonal.esp.br"
echo "  Site: https://guialmeidapersonal.esp.br"
echo ""
echo "Next steps:"
echo "  1. Verify all URLs are accessible"
echo "  2. Test login flow"
echo "  3. Set up monitoring alerts"
echo "  4. Configure budget alerts"
echo ""
```

```bash
chmod +x infrastructure/gcp/deploy-all.sh
```

**Step 8: Commit final documentation**

```bash
git add infrastructure/gcp/DEPLOYMENT.md infrastructure/gcp/deploy-all.sh
git commit -m "docs: Add complete deployment documentation and master script"
```

**Step 9: Push to trigger CI/CD**

```bash
git push origin main
```

**Step 10: Verify everything is working**

```bash
echo "Verifying deployment..."
echo ""

# API health
echo "API Health:"
curl -s https://api.guialmeidapersonal.esp.br/api/v1/health | jq

# Frontend status codes
echo ""
echo "Admin frontend:"
curl -I -s https://admin.guialmeidapersonal.esp.br | head -n 1

echo "App frontend:"
curl -I -s https://app.guialmeidapersonal.esp.br | head -n 1

echo "Site:"
curl -I -s https://guialmeidapersonal.esp.br | head -n 1

echo ""
echo "✅ Deployment verification complete!"
```

Expected: All endpoints return 200 OK

---

## Completion Checklist

- [ ] All GCP APIs enabled
- [ ] VPC network and subnets created
- [ ] VPC connector provisioned
- [ ] Cloud SQL PostgreSQL instance running
- [ ] Memorystore Redis instance running
- [ ] Service accounts created with proper IAM roles
- [ ] Secrets stored in Secret Manager
- [ ] Cloud Storage buckets created
- [ ] Artifact Registry repository created
- [ ] Backend Docker image built and pushed
- [ ] Backend deployed to Cloud Run
- [ ] Database migrations completed
- [ ] Load balancer configured with backends
- [ ] SSL certificate provisioned (ACTIVE)
- [ ] DNS records configured
- [ ] Frontends built and deployed
- [ ] GitHub Actions workflows configured
- [ ] Workload Identity Federation set up
- [ ] CI/CD pipelines tested and working
- [ ] Monitoring and alerts configured
- [ ] All URLs accessible via HTTPS
- [ ] HTTP redirects to HTTPS working
- [ ] Complete documentation committed

---

## Success Criteria

✅ **Infrastructure:**
- All GCP resources provisioned in southamerica-east1
- No public IPs on databases (private only)
- SSL certificates ACTIVE and auto-renewing
- Load balancer routing to correct backends

✅ **Application:**
- Backend API responding on api.guialmeidapersonal.esp.br
- Trainer dashboard on admin.guialmeidapersonal.esp.br
- Student portal on app.guialmeidapersonal.esp.br
- Marketing site on guialmeidapersonal.esp.br
- Authentication flow working
- Database migrations applied

✅ **CI/CD:**
- GitHub Actions workflows operational
- Push to main triggers automatic deployment
- Workload Identity Federation working
- No long-lived service account keys

✅ **Monitoring:**
- Uptime checks configured
- Dashboards created
- Logs aggregated in Cloud Logging
- Health checks passing

✅ **Security:**
- All secrets in Secret Manager
- Private networking for databases
- Service accounts with least privilege
- HTTPS enforced everywhere

---

*Implementation plan created: 2026-02-03*
*Estimated time: 4-6 hours (including wait times for DNS/SSL)*
