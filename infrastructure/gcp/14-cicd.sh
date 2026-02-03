#!/bin/bash
#
# Task 17: Configure Workload Identity Federation for GitHub Actions
# Project: guialmeidapersonal
# Region: southamerica-east1
#
# This script sets up Workload Identity Federation to allow GitHub Actions
# to authenticate with GCP without using service account keys.
#
# Prerequisites:
# - gcloud CLI authenticated with appropriate permissions
# - IAM Credentials API enabled
# - CI/CD service account (cicd-sa) created
#
# Usage:
#   ./14-cicd.sh
#
# This script is idempotent - safe to run multiple times.
#

set -e

# Configuration
PROJECT_ID="guialmeidapersonal"
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
REGION="southamerica-east1"

# Workload Identity Pool Configuration
POOL_ID="github-actions-pool"
POOL_DISPLAY_NAME="GitHub Actions Pool"
POOL_DESCRIPTION="Workload Identity Pool for GitHub Actions CI/CD"

# Provider Configuration
PROVIDER_ID="github-actions-provider"
GITHUB_REPO="luizavanter/guialmeidapersonal"

# Service Account
CICD_SA="cicd-sa"
CICD_SA_EMAIL="${CICD_SA}@${PROJECT_ID}.iam.gserviceaccount.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "======================================"
echo "Workload Identity Federation Setup"
echo "======================================"
echo ""
echo "Project ID:     $PROJECT_ID"
echo "Project Number: $PROJECT_NUMBER"
echo "GitHub Repo:    $GITHUB_REPO"
echo ""

# ----------------------------------------------
# Step 1: Enable Required APIs
# ----------------------------------------------
log_step "Step 1: Enabling required APIs..."

REQUIRED_APIS=(
    "iamcredentials.googleapis.com"
    "iam.googleapis.com"
    "cloudresourcemanager.googleapis.com"
)

for api in "${REQUIRED_APIS[@]}"; do
    if gcloud services list --project=$PROJECT_ID --enabled --filter="name:$api" --format="value(name)" | grep -q "$api"; then
        log_info "  $api is already enabled"
    else
        log_info "  Enabling $api..."
        gcloud services enable $api --project=$PROJECT_ID
    fi
done
echo ""

# ----------------------------------------------
# Step 2: Create Workload Identity Pool
# ----------------------------------------------
log_step "Step 2: Creating Workload Identity Pool..."

if gcloud iam workload-identity-pools describe $POOL_ID \
    --project=$PROJECT_ID \
    --location="global" &>/dev/null; then
    log_info "  Workload Identity Pool '$POOL_ID' already exists"
else
    log_info "  Creating Workload Identity Pool..."
    gcloud iam workload-identity-pools create $POOL_ID \
        --project=$PROJECT_ID \
        --location="global" \
        --display-name="$POOL_DISPLAY_NAME" \
        --description="$POOL_DESCRIPTION"
    log_info "  Workload Identity Pool created!"
fi
echo ""

# ----------------------------------------------
# Step 3: Create OIDC Provider
# ----------------------------------------------
log_step "Step 3: Creating OIDC Provider for GitHub Actions..."

if gcloud iam workload-identity-pools providers describe $PROVIDER_ID \
    --project=$PROJECT_ID \
    --location="global" \
    --workload-identity-pool=$POOL_ID &>/dev/null; then
    log_info "  OIDC Provider '$PROVIDER_ID' already exists"
else
    log_info "  Creating OIDC Provider..."
    gcloud iam workload-identity-pools providers create-oidc $PROVIDER_ID \
        --project=$PROJECT_ID \
        --location="global" \
        --workload-identity-pool=$POOL_ID \
        --display-name="GitHub Actions Provider" \
        --issuer-uri="https://token.actions.githubusercontent.com" \
        --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
        --attribute-condition="assertion.repository=='${GITHUB_REPO}'"
    log_info "  OIDC Provider created!"
fi
echo ""

# ----------------------------------------------
# Step 4: Grant Service Account Impersonation
# ----------------------------------------------
log_step "Step 4: Granting Workload Identity User role to CI/CD service account..."

# Construct the principal set for the GitHub repo
PRINCIPAL_SET="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository/${GITHUB_REPO}"

log_info "  Principal: $PRINCIPAL_SET"
log_info "  Service Account: $CICD_SA_EMAIL"

# Grant Workload Identity User role
gcloud iam service-accounts add-iam-policy-binding $CICD_SA_EMAIL \
    --project=$PROJECT_ID \
    --role="roles/iam.workloadIdentityUser" \
    --member="$PRINCIPAL_SET" \
    --quiet

log_info "  Workload Identity User role granted!"
echo ""

# ----------------------------------------------
# Step 5: Verify CI/CD SA has required permissions
# ----------------------------------------------
log_step "Step 5: Verifying CI/CD service account permissions..."

REQUIRED_ROLES=(
    "roles/run.admin"
    "roles/storage.admin"
    "roles/artifactregistry.writer"
    "roles/iam.serviceAccountUser"
    "roles/cloudsql.admin"
)

for role in "${REQUIRED_ROLES[@]}"; do
    log_info "  Ensuring $role is granted..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$CICD_SA_EMAIL" \
        --role="$role" \
        --quiet >/dev/null
done

log_info "  All required roles verified!"
echo ""

# ----------------------------------------------
# Summary
# ----------------------------------------------
echo "======================================"
echo "Workload Identity Federation Complete!"
echo "======================================"
echo ""
echo "Workload Identity Pool:"
echo "  Name: $POOL_ID"
echo "  Full Name: projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}"
echo ""
echo "Provider:"
echo "  Name: $PROVIDER_ID"
echo "  Full Name: projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}"
echo ""
echo "Service Account:"
echo "  Email: $CICD_SA_EMAIL"
echo ""
echo "GitHub Repository:"
echo "  $GITHUB_REPO"
echo ""
echo "======================================"
echo "GitHub Actions Configuration"
echo "======================================"
echo ""
echo "Add these secrets to your GitHub repository:"
echo ""
echo "  GCP_PROJECT_ID: $PROJECT_ID"
echo "  GCP_WORKLOAD_IDENTITY_PROVIDER: projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}"
echo "  GCP_SERVICE_ACCOUNT: $CICD_SA_EMAIL"
echo ""
echo "Example workflow step:"
echo ""
echo "  - uses: google-github-actions/auth@v2"
echo "    with:"
echo "      workload_identity_provider: '\${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}'"
echo "      service_account: '\${{ secrets.GCP_SERVICE_ACCOUNT }}'"
echo ""
echo "======================================"
