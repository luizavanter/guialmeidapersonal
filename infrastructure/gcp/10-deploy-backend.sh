#!/bin/bash
#
# Task 11: Deploy Backend to Cloud Run
# Project: guialmeidapersonal
# Region: southamerica-east1
#
# This script deploys the backend API to Cloud Run and manages database migrations.
# It is idempotent - safe to run multiple times.
#
# Prerequisites:
# - gcloud CLI authenticated with appropriate permissions
# - Cloud Run API enabled
# - VPC connector (ga-personal-vpc-connector) created
# - Secrets in Secret Manager (database-url, redis-url, jwt-secret, secret-key-base)
# - Docker image built and pushed to Artifact Registry
# - Service account (backend-sa) with proper roles
#
# Usage:
#   ./10-deploy-backend.sh [TAG]
#
# Arguments:
#   TAG - Image tag to deploy (default: latest)
#
# Examples:
#   ./10-deploy-backend.sh           # Deploys 'latest' tag
#   ./10-deploy-backend.sh v1.0.0    # Deploys 'v1.0.0' tag
#   ./10-deploy-backend.sh abc123    # Deploys specific commit
#
# Environment Variables:
#   SKIP_MIGRATIONS=true   # Skip migration job execution
#   DRY_RUN=true          # Show what would be deployed without deploying
#

set -e

# Configuration
PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
SERVICE_NAME="ga-personal-api"
MIGRATION_JOB_NAME="ga-personal-migrations"
VPC_CONNECTOR="ga-personal-vpc-connector"
SERVICE_ACCOUNT="backend-sa@guialmeidapersonal.iam.gserviceaccount.com"

# Image configuration
REPO="ga-personal"
IMAGE_NAME="backend"
TAG="${1:-latest}"
FULL_IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE_NAME}:${TAG}"

# Cloud Run configuration
MIN_INSTANCES=0
MAX_INSTANCES=10
CPU="1"
MEMORY="512Mi"
PORT=4000
CONCURRENCY=80
TIMEOUT="300s"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check required tools and permissions
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed"
        exit 1
    fi

    # Verify project access
    if ! gcloud projects describe $PROJECT_ID &> /dev/null; then
        log_error "Cannot access project: $PROJECT_ID"
        exit 1
    fi

    # Check if Cloud Run API is enabled
    if ! gcloud services list --project=$PROJECT_ID --enabled --filter="name:run.googleapis.com" --format="value(name)" | grep -q "run"; then
        log_warn "Cloud Run API may not be enabled. Enabling now..."
        gcloud services enable run.googleapis.com --project=$PROJECT_ID
        log_info "Cloud Run API enabled"
    fi

    log_info "Prerequisites check passed"
}

# Verify required infrastructure exists
verify_infrastructure() {
    log_info "Verifying required infrastructure..."

    # Check VPC connector
    if ! gcloud compute networks vpc-access connectors describe $VPC_CONNECTOR \
        --region=$REGION \
        --project=$PROJECT_ID &>/dev/null; then
        log_error "VPC connector '$VPC_CONNECTOR' not found"
        log_error "Please run 02-vpc-connector.sh first"
        exit 1
    fi
    log_info "VPC connector verified"

    # Check service account
    if ! gcloud iam service-accounts describe $SERVICE_ACCOUNT \
        --project=$PROJECT_ID &>/dev/null; then
        log_error "Service account '$SERVICE_ACCOUNT' not found"
        log_error "Please run 05-service-accounts.sh first"
        exit 1
    fi
    log_info "Service account verified"

    # Check required secrets
    local required_secrets=("database-url" "redis-url" "jwt-secret" "secret-key-base")
    for secret in "${required_secrets[@]}"; do
        if ! gcloud secrets describe "$secret" --project=$PROJECT_ID &>/dev/null; then
            log_error "Secret '$secret' not found in Secret Manager"
            log_error "Please run 06-secrets.sh first"
            exit 1
        fi
    done
    log_info "All required secrets verified"

    # Check if image exists in Artifact Registry
    if ! gcloud artifacts docker images describe "$FULL_IMAGE_PATH" \
        --project=$PROJECT_ID &>/dev/null; then
        log_error "Docker image not found: $FULL_IMAGE_PATH"
        log_error "Please run 09-build-backend.sh first"
        exit 1
    fi
    log_info "Docker image verified: $FULL_IMAGE_PATH"
}

# Deploy Cloud Run service
deploy_service() {
    log_step "Deploying Cloud Run service..."

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "DRY RUN: Would deploy with the following configuration:"
        echo "  Service:       $SERVICE_NAME"
        echo "  Image:         $FULL_IMAGE_PATH"
        echo "  Region:        $REGION"
        echo "  CPU:           $CPU"
        echo "  Memory:        $MEMORY"
        echo "  Min instances: $MIN_INSTANCES"
        echo "  Max instances: $MAX_INSTANCES"
        echo "  Port:          $PORT"
        echo "  VPC connector: $VPC_CONNECTOR"
        return 0
    fi

    gcloud run deploy $SERVICE_NAME \
        --image="$FULL_IMAGE_PATH" \
        --platform=managed \
        --region=$REGION \
        --project=$PROJECT_ID \
        --service-account=$SERVICE_ACCOUNT \
        --vpc-connector=$VPC_CONNECTOR \
        --vpc-egress=private-ranges-only \
        --ingress=internal-and-cloud-load-balancing \
        --min-instances=$MIN_INSTANCES \
        --max-instances=$MAX_INSTANCES \
        --cpu=$CPU \
        --memory=$MEMORY \
        --port=$PORT \
        --concurrency=$CONCURRENCY \
        --timeout=$TIMEOUT \
        --set-env-vars="MIX_ENV=prod,PHX_SERVER=true,PHX_HOST=api.guialmeidapersonal.com.br" \
        --set-secrets="DATABASE_URL=database-url:latest,REDIS_URL=redis-url:latest,JWT_SECRET=jwt-secret:latest,SECRET_KEY_BASE=secret-key-base:latest" \
        --allow-unauthenticated \
        --quiet

    log_info "Cloud Run service deployed successfully"
}

# Create migration Cloud Run job (if not exists)
create_migration_job() {
    log_step "Setting up migration job..."

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "DRY RUN: Would create/update migration job: $MIGRATION_JOB_NAME"
        return 0
    fi

    # Check if job already exists
    if gcloud run jobs describe $MIGRATION_JOB_NAME \
        --region=$REGION \
        --project=$PROJECT_ID &>/dev/null; then
        log_info "Migration job exists, updating..."

        gcloud run jobs update $MIGRATION_JOB_NAME \
            --image="$FULL_IMAGE_PATH" \
            --region=$REGION \
            --project=$PROJECT_ID \
            --service-account=$SERVICE_ACCOUNT \
            --vpc-connector=$VPC_CONNECTOR \
            --vpc-egress=private-ranges-only \
            --cpu=$CPU \
            --memory=$MEMORY \
            --max-retries=1 \
            --task-timeout="600s" \
            --set-env-vars="MIX_ENV=prod" \
            --set-secrets="DATABASE_URL=database-url:latest" \
            --command="/app/bin/backend" \
            --args="eval","Backend.Release.migrate" \
            --quiet
    else
        log_info "Creating migration job..."

        gcloud run jobs create $MIGRATION_JOB_NAME \
            --image="$FULL_IMAGE_PATH" \
            --region=$REGION \
            --project=$PROJECT_ID \
            --service-account=$SERVICE_ACCOUNT \
            --vpc-connector=$VPC_CONNECTOR \
            --vpc-egress=private-ranges-only \
            --cpu=$CPU \
            --memory=$MEMORY \
            --max-retries=1 \
            --task-timeout="600s" \
            --set-env-vars="MIX_ENV=prod" \
            --set-secrets="DATABASE_URL=database-url:latest" \
            --command="/app/bin/backend" \
            --args="eval","Backend.Release.migrate" \
            --quiet
    fi

    log_info "Migration job configured"
}

# Execute database migrations
run_migrations() {
    if [ "$SKIP_MIGRATIONS" = "true" ]; then
        log_warn "SKIP_MIGRATIONS is set, skipping migration execution"
        return 0
    fi

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "DRY RUN: Would execute migration job: $MIGRATION_JOB_NAME"
        return 0
    fi

    log_step "Running database migrations..."

    # Execute the migration job
    gcloud run jobs execute $MIGRATION_JOB_NAME \
        --region=$REGION \
        --project=$PROJECT_ID \
        --wait \
        --quiet

    log_info "Database migrations completed successfully"
}

# Get service URL
get_service_url() {
    log_info "Fetching service URL..."

    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
        --region=$REGION \
        --project=$PROJECT_ID \
        --format="value(status.url)" 2>/dev/null) || {
        log_warn "Could not fetch service URL (service may not be deployed yet)"
        return 0
    }

    echo ""
    log_info "Service URL: $SERVICE_URL"
}

# Perform health check
health_check() {
    log_step "Performing health check..."

    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
        --region=$REGION \
        --project=$PROJECT_ID \
        --format="value(status.url)" 2>/dev/null) || {
        log_warn "Could not fetch service URL for health check"
        return 0
    }

    if [ -z "$SERVICE_URL" ]; then
        log_warn "Service URL is empty, skipping health check"
        return 0
    fi

    # Note: Internal-only services may not be accessible directly
    # This health check is informational
    log_info "Service is configured with ingress=internal-and-cloud-load-balancing"
    log_info "Direct health check may fail. Use the load balancer URL instead."
    echo ""
    log_info "To check health via Cloud Run internal URL (from VPC):"
    echo "  curl ${SERVICE_URL}/api/health"
    echo ""
    log_info "To check service status:"
    echo "  gcloud run services describe $SERVICE_NAME --region=$REGION --project=$PROJECT_ID"
}

# Print deployment summary
print_summary() {
    echo ""
    log_info "========================================"
    log_info "Deployment Summary"
    log_info "========================================"
    echo ""

    log_info "Service Configuration:"
    echo "  Service Name:  $SERVICE_NAME"
    echo "  Image:         $FULL_IMAGE_PATH"
    echo "  Region:        $REGION"
    echo "  Platform:      managed"
    echo ""

    log_info "Resources:"
    echo "  CPU:           $CPU"
    echo "  Memory:        $MEMORY"
    echo "  Min instances: $MIN_INSTANCES (scale to zero)"
    echo "  Max instances: $MAX_INSTANCES"
    echo "  Port:          $PORT"
    echo ""

    log_info "Networking:"
    echo "  VPC connector: $VPC_CONNECTOR"
    echo "  Ingress:       internal-and-cloud-load-balancing"
    echo "  VPC egress:    private-ranges-only"
    echo ""

    log_info "Security:"
    echo "  Service Account: $SERVICE_ACCOUNT"
    echo "  Authentication:  unauthenticated (app handles auth)"
    echo "  Secrets:         Mounted from Secret Manager"
    echo ""

    log_info "Migration Job:"
    echo "  Job Name:      $MIGRATION_JOB_NAME"
    echo "  Command:       Backend.Release.migrate"
    echo ""

    log_info "Useful Commands:"
    echo ""
    echo "  # View service details"
    echo "  gcloud run services describe $SERVICE_NAME --region=$REGION --project=$PROJECT_ID"
    echo ""
    echo "  # View service logs"
    echo "  gcloud run services logs read $SERVICE_NAME --region=$REGION --project=$PROJECT_ID --limit=50"
    echo ""
    echo "  # Run migrations manually"
    echo "  gcloud run jobs execute $MIGRATION_JOB_NAME --region=$REGION --project=$PROJECT_ID --wait"
    echo ""
    echo "  # View migration job logs"
    echo "  gcloud run jobs executions list --job=$MIGRATION_JOB_NAME --region=$REGION --project=$PROJECT_ID"
    echo ""
    echo "  # Update service to new image"
    echo "  gcloud run services update $SERVICE_NAME --image=<new-image> --region=$REGION --project=$PROJECT_ID"
    echo ""
    echo "  # Scale service manually"
    echo "  gcloud run services update $SERVICE_NAME --min-instances=1 --region=$REGION --project=$PROJECT_ID"
    echo ""
}

# Main execution
main() {
    echo "========================================"
    echo "Task 11: Deploy Backend to Cloud Run"
    echo "========================================"
    echo ""

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "Running in DRY RUN mode - no changes will be made"
        echo ""
    fi

    log_info "Deployment Configuration:"
    echo "  Image tag: $TAG"
    echo "  Full image: $FULL_IMAGE_PATH"
    echo ""

    check_prerequisites
    verify_infrastructure

    echo ""
    log_info "Starting deployment..."
    echo ""

    # Create/update migration job first
    create_migration_job

    # Run migrations before deploying new service version
    run_migrations

    # Deploy the Cloud Run service
    deploy_service

    # Get and display service URL
    get_service_url

    # Perform health check
    health_check

    # Print summary
    print_summary

    log_info "========================================"
    log_info "Backend deployment complete!"
    log_info "========================================"
}

# Run main function
main "$@"
