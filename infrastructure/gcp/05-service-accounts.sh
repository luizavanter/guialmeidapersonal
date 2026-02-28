#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
BACKEND_SA="backend-sa"
CICD_SA="cicd-sa"

BACKEND_SA_EMAIL="${BACKEND_SA}@${PROJECT_ID}.iam.gserviceaccount.com"
CICD_SA_EMAIL="${CICD_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "======================================"
echo "Service Accounts Setup"
echo "======================================"
echo ""

# ----------------------------------------------
# Step 1: Create Backend Service Account
# ----------------------------------------------
echo "Step 1: Creating Backend Service Account..."

if gcloud iam service-accounts describe $BACKEND_SA_EMAIL --project=$PROJECT_ID &>/dev/null; then
  echo "  Backend service account '$BACKEND_SA' already exists, skipping creation..."
else
  echo "  Creating backend service account..."
  gcloud iam service-accounts create $BACKEND_SA \
    --display-name="Backend Service Account" \
    --description="Service account for Cloud Run backend API" \
    --project=$PROJECT_ID
  echo "  Backend service account created!"
fi
echo ""

# ----------------------------------------------
# Step 2: Create CI/CD Service Account
# ----------------------------------------------
echo "Step 2: Creating CI/CD Service Account..."

if gcloud iam service-accounts describe $CICD_SA_EMAIL --project=$PROJECT_ID &>/dev/null; then
  echo "  CI/CD service account '$CICD_SA' already exists, skipping creation..."
else
  echo "  Creating CI/CD service account..."
  gcloud iam service-accounts create $CICD_SA \
    --display-name="CI/CD Service Account" \
    --description="Service account for GitHub Actions deployments" \
    --project=$PROJECT_ID
  echo "  CI/CD service account created!"
fi
echo ""

# ----------------------------------------------
# Step 3: Grant Backend SA Roles
# ----------------------------------------------
echo "Step 3: Granting Backend Service Account roles..."
echo "  (IAM policy bindings are naturally idempotent)"
echo ""

# Cloud SQL Client
echo "  Granting roles/cloudsql.client..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$BACKEND_SA_EMAIL" \
  --role="roles/cloudsql.client" \
  --quiet

# Redis Editor
echo "  Granting roles/redis.editor..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$BACKEND_SA_EMAIL" \
  --role="roles/redis.editor" \
  --quiet

# Storage Object Admin (for media bucket)
echo "  Granting roles/storage.objectAdmin..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$BACKEND_SA_EMAIL" \
  --role="roles/storage.objectAdmin" \
  --quiet

# Secret Manager Secret Accessor
echo "  Granting roles/secretmanager.secretAccessor..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$BACKEND_SA_EMAIL" \
  --role="roles/secretmanager.secretAccessor" \
  --quiet

echo "  Backend SA roles granted!"
echo ""

# ----------------------------------------------
# Step 4: Grant CI/CD SA Roles
# ----------------------------------------------
echo "Step 4: Granting CI/CD Service Account roles..."
echo ""

# Cloud Run Admin
echo "  Granting roles/run.admin..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$CICD_SA_EMAIL" \
  --role="roles/run.admin" \
  --quiet

# Storage Admin
echo "  Granting roles/storage.admin..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$CICD_SA_EMAIL" \
  --role="roles/storage.admin" \
  --quiet

# Artifact Registry Writer
echo "  Granting roles/artifactregistry.writer..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$CICD_SA_EMAIL" \
  --role="roles/artifactregistry.writer" \
  --quiet

# Service Account User (to act as backend-sa)
echo "  Granting roles/iam.serviceAccountUser..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$CICD_SA_EMAIL" \
  --role="roles/iam.serviceAccountUser" \
  --quiet

# Cloud SQL Admin (for migrations)
echo "  Granting roles/cloudsql.admin..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$CICD_SA_EMAIL" \
  --role="roles/cloudsql.admin" \
  --quiet

echo "  CI/CD SA roles granted!"
echo ""

# ----------------------------------------------
# Summary
# ----------------------------------------------
echo "======================================"
echo "Service Accounts Setup Complete!"
echo "======================================"
echo ""
echo "Service Accounts Created:"
echo "  Backend SA: $BACKEND_SA_EMAIL"
echo "  CI/CD SA:   $CICD_SA_EMAIL"
echo ""
echo "Backend Service Account Roles:"
echo "  - roles/cloudsql.client (Connect to Cloud SQL)"
echo "  - roles/redis.editor (Access Memorystore Redis)"
echo "  - roles/storage.objectAdmin (Manage storage objects)"
echo "  - roles/secretmanager.secretAccessor (Read secrets)"
echo ""
echo "CI/CD Service Account Roles:"
echo "  - roles/run.admin (Deploy Cloud Run services)"
echo "  - roles/storage.admin (Manage storage buckets)"
echo "  - roles/artifactregistry.writer (Push container images)"
echo "  - roles/iam.serviceAccountUser (Act as backend-sa)"
echo "  - roles/cloudsql.admin (Run database migrations)"
echo ""
echo "======================================"
echo ""
echo "NEXT STEPS:"
echo "1. Create Workload Identity Pool for GitHub Actions"
echo "2. Or generate key for CI/CD SA (less secure):"
echo "   gcloud iam service-accounts keys create key.json \\"
echo "     --iam-account=$CICD_SA_EMAIL"
echo ""
echo "======================================"
