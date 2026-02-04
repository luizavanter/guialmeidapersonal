#!/bin/bash
#
# Deploy Cal.com Self-Hosted to GCP Cloud Run
# Project: guialmeidapersonal
# Region: southamerica-east1
#
# This script deploys Cal.com to Cloud Run with PostgreSQL on Cloud SQL.
# It is idempotent - safe to run multiple times.
#
# Prerequisites:
# - gcloud CLI authenticated with appropriate permissions
# - Cloud Run API enabled
# - VPC connector (ga-personal-vpc-connector) created
# - Cloud SQL instance (ga-personal-db) running
# - Service account (backend-sa) with proper roles
#
# Usage:
#   ./deploy-calcom.sh
#
# Environment Variables:
#   DRY_RUN=true          # Show what would be deployed without deploying
#   CALCOM_VERSION=v4.7.1 # Cal.com version to deploy (default: v4.7.1)
#

set -e

# Configuration
PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
SERVICE_NAME="ga-calcom"
VPC_CONNECTOR="ga-personal-vpc-connector"
SERVICE_ACCOUNT="backend-sa@guialmeidapersonal.iam.gserviceaccount.com"

# Cal.com Configuration
CALCOM_VERSION="${CALCOM_VERSION:-v4.7.1}"
CALCOM_IMAGE="calcom/cal.com:${CALCOM_VERSION}"

# Cloud SQL Configuration
SQL_INSTANCE_NAME="ga-personal-db"
CALCOM_DB_NAME="calcom"
CALCOM_DB_USER="calcom_user"

# Cloud Run Configuration
MIN_INSTANCES=0
MAX_INSTANCES=4
CPU="2"
MEMORY="2Gi"
PORT=3000
CONCURRENCY=50
TIMEOUT="300s"

# Domain Configuration
CALCOM_DOMAIN="cal.guialmeidapersonal.esp.br"
NEXTAUTH_URL="https://${CALCOM_DOMAIN}"

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

    # Check Cloud SQL instance
    if ! gcloud sql instances describe $SQL_INSTANCE_NAME \
        --project=$PROJECT_ID &>/dev/null; then
        log_error "Cloud SQL instance '$SQL_INSTANCE_NAME' not found"
        log_error "Please run 03-cloudsql.sh first"
        exit 1
    fi
    log_info "Cloud SQL instance verified"
}

# Create Cal.com database in Cloud SQL
create_calcom_database() {
    log_step "Setting up Cal.com database..."

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "DRY RUN: Would create database: $CALCOM_DB_NAME"
        return 0
    fi

    # Check if database already exists
    if gcloud sql databases describe $CALCOM_DB_NAME --instance=$SQL_INSTANCE_NAME --project=$PROJECT_ID &>/dev/null; then
        log_info "Database '$CALCOM_DB_NAME' already exists"
    else
        log_info "Creating Cal.com database..."
        gcloud sql databases create $CALCOM_DB_NAME \
            --instance=$SQL_INSTANCE_NAME \
            --project=$PROJECT_ID
        log_info "Database created"
    fi

    # Generate or retrieve password for Cal.com user
    PASSWORD_FILE="/tmp/.calcom-db-password"
    if [ -f "$PASSWORD_FILE" ]; then
        log_info "Using existing Cal.com database password from previous run..."
        CALCOM_DB_PASSWORD=$(cat "$PASSWORD_FILE")
    else
        log_info "Generating Cal.com database password..."
        CALCOM_DB_PASSWORD=$(openssl rand -base64 32)
        echo "$CALCOM_DB_PASSWORD" > "$PASSWORD_FILE"
        chmod 600 "$PASSWORD_FILE"
    fi

    # Check if user already exists
    if gcloud sql users list --instance=$SQL_INSTANCE_NAME --project=$PROJECT_ID --format="value(name)" | grep -q "^$CALCOM_DB_USER$"; then
        log_info "User '$CALCOM_DB_USER' already exists, updating password..."
        gcloud sql users set-password $CALCOM_DB_USER \
            --instance=$SQL_INSTANCE_NAME \
            --password="$CALCOM_DB_PASSWORD" \
            --project=$PROJECT_ID
    else
        log_info "Creating Cal.com database user..."
        gcloud sql users create $CALCOM_DB_USER \
            --instance=$SQL_INSTANCE_NAME \
            --password="$CALCOM_DB_PASSWORD" \
            --project=$PROJECT_ID
    fi

    log_info "Database setup complete"
}

# Create secrets in Secret Manager
create_secrets() {
    log_step "Setting up Cal.com secrets..."

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "DRY RUN: Would create Cal.com secrets"
        return 0
    fi

    # Get Cloud SQL private IP
    SQL_PRIVATE_IP=$(gcloud sql instances describe $SQL_INSTANCE_NAME \
        --project=$PROJECT_ID \
        --format="value(ipAddresses[0].ipAddress)")

    # Read password
    PASSWORD_FILE="/tmp/.calcom-db-password"
    if [ ! -f "$PASSWORD_FILE" ]; then
        log_error "Cal.com database password file not found. Run create_calcom_database first."
        exit 1
    fi
    CALCOM_DB_PASSWORD=$(cat "$PASSWORD_FILE")

    # Cal.com DATABASE_URL
    CALCOM_DATABASE_URL="postgresql://${CALCOM_DB_USER}:${CALCOM_DB_PASSWORD}@${SQL_PRIVATE_IP}:5432/${CALCOM_DB_NAME}"

    # Create or update calcom-database-url secret
    if gcloud secrets describe "calcom-database-url" --project=$PROJECT_ID &>/dev/null; then
        log_info "Updating calcom-database-url secret..."
        echo -n "$CALCOM_DATABASE_URL" | gcloud secrets versions add "calcom-database-url" \
            --data-file=- \
            --project=$PROJECT_ID
    else
        log_info "Creating calcom-database-url secret..."
        echo -n "$CALCOM_DATABASE_URL" | gcloud secrets create "calcom-database-url" \
            --data-file=- \
            --replication-policy="automatic" \
            --project=$PROJECT_ID
    fi

    # Generate NEXTAUTH_SECRET
    NEXTAUTH_SECRET=$(openssl rand -base64 32)
    if gcloud secrets describe "calcom-nextauth-secret" --project=$PROJECT_ID &>/dev/null; then
        log_info "calcom-nextauth-secret already exists"
    else
        log_info "Creating calcom-nextauth-secret..."
        echo -n "$NEXTAUTH_SECRET" | gcloud secrets create "calcom-nextauth-secret" \
            --data-file=- \
            --replication-policy="automatic" \
            --project=$PROJECT_ID
    fi

    # Generate CALENDSO_ENCRYPTION_KEY (for Cal.com encryption)
    ENCRYPTION_KEY=$(openssl rand -hex 16)
    if gcloud secrets describe "calcom-encryption-key" --project=$PROJECT_ID &>/dev/null; then
        log_info "calcom-encryption-key already exists"
    else
        log_info "Creating calcom-encryption-key..."
        echo -n "$ENCRYPTION_KEY" | gcloud secrets create "calcom-encryption-key" \
            --data-file=- \
            --replication-policy="automatic" \
            --project=$PROJECT_ID
    fi

    # Cal.com Webhook Secret (for GA Personal integration)
    WEBHOOK_SECRET=$(openssl rand -base64 32)
    if gcloud secrets describe "calcom-webhook-secret" --project=$PROJECT_ID &>/dev/null; then
        log_info "calcom-webhook-secret already exists"
    else
        log_info "Creating calcom-webhook-secret..."
        echo -n "$WEBHOOK_SECRET" | gcloud secrets create "calcom-webhook-secret" \
            --data-file=- \
            --replication-policy="automatic" \
            --project=$PROJECT_ID
    fi

    # Grant service account access to secrets
    log_info "Granting service account access to secrets..."
    local secrets=("calcom-database-url" "calcom-nextauth-secret" "calcom-encryption-key" "calcom-webhook-secret")
    for secret in "${secrets[@]}"; do
        gcloud secrets add-iam-policy-binding "$secret" \
            --member="serviceAccount:$SERVICE_ACCOUNT" \
            --role="roles/secretmanager.secretAccessor" \
            --project=$PROJECT_ID \
            --quiet 2>/dev/null || true
    done

    log_info "Secrets setup complete"
}

# Deploy Cal.com to Cloud Run
deploy_service() {
    log_step "Deploying Cal.com to Cloud Run..."

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "DRY RUN: Would deploy with the following configuration:"
        echo "  Service:       $SERVICE_NAME"
        echo "  Image:         $CALCOM_IMAGE"
        echo "  Region:        $REGION"
        echo "  CPU:           $CPU"
        echo "  Memory:        $MEMORY"
        echo "  Min instances: $MIN_INSTANCES"
        echo "  Max instances: $MAX_INSTANCES"
        echo "  Port:          $PORT"
        echo "  VPC connector: $VPC_CONNECTOR"
        echo "  Domain:        $CALCOM_DOMAIN"
        return 0
    fi

    # Environment variables for Cal.com
    ENV_VARS="NODE_ENV=production"
    ENV_VARS="${ENV_VARS},NEXT_PUBLIC_WEBAPP_URL=https://${CALCOM_DOMAIN}"
    ENV_VARS="${ENV_VARS},NEXTAUTH_URL=https://${CALCOM_DOMAIN}"
    ENV_VARS="${ENV_VARS},NEXT_PUBLIC_LICENSE_CONSENT=agree"
    ENV_VARS="${ENV_VARS},CALCOM_TELEMETRY_DISABLED=1"
    ENV_VARS="${ENV_VARS},PORT=${PORT}"

    # GA Personal API integration
    ENV_VARS="${ENV_VARS},GA_PERSONAL_API_URL=https://api.guialmeidapersonal.esp.br"
    ENV_VARS="${ENV_VARS},GA_PERSONAL_WEBHOOK_URL=https://api.guialmeidapersonal.esp.br/api/v1/webhooks/calcom"

    gcloud run deploy $SERVICE_NAME \
        --image="$CALCOM_IMAGE" \
        --platform=managed \
        --region=$REGION \
        --project=$PROJECT_ID \
        --service-account=$SERVICE_ACCOUNT \
        --vpc-connector=$VPC_CONNECTOR \
        --vpc-egress=private-ranges-only \
        --ingress=all \
        --min-instances=$MIN_INSTANCES \
        --max-instances=$MAX_INSTANCES \
        --cpu=$CPU \
        --memory=$MEMORY \
        --port=$PORT \
        --concurrency=$CONCURRENCY \
        --timeout=$TIMEOUT \
        --set-env-vars="$ENV_VARS" \
        --set-secrets="DATABASE_URL=calcom-database-url:latest,NEXTAUTH_SECRET=calcom-nextauth-secret:latest,CALENDSO_ENCRYPTION_KEY=calcom-encryption-key:latest" \
        --allow-unauthenticated \
        --quiet

    log_info "Cal.com deployed successfully"
}

# Configure domain mapping
configure_domain() {
    log_step "Configuring domain mapping..."

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "DRY RUN: Would configure domain: $CALCOM_DOMAIN"
        return 0
    fi

    # Check if domain mapping already exists
    if gcloud run domain-mappings describe --domain=$CALCOM_DOMAIN --region=$REGION --project=$PROJECT_ID &>/dev/null; then
        log_info "Domain mapping already exists for $CALCOM_DOMAIN"
    else
        log_info "Creating domain mapping..."
        gcloud run domain-mappings create \
            --service=$SERVICE_NAME \
            --domain=$CALCOM_DOMAIN \
            --region=$REGION \
            --project=$PROJECT_ID \
            --quiet || {
            log_warn "Domain mapping creation failed. You may need to verify domain ownership first."
            log_info "To verify domain:"
            echo "  gcloud domains verify $CALCOM_DOMAIN --project=$PROJECT_ID"
        }
    fi
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
    log_info "Custom Domain: https://$CALCOM_DOMAIN (after DNS configuration)"
}

# Print deployment summary
print_summary() {
    echo ""
    log_info "========================================"
    log_info "Cal.com Deployment Summary"
    log_info "========================================"
    echo ""

    log_info "Service Configuration:"
    echo "  Service Name:  $SERVICE_NAME"
    echo "  Image:         $CALCOM_IMAGE"
    echo "  Region:        $REGION"
    echo "  Custom Domain: $CALCOM_DOMAIN"
    echo ""

    log_info "Resources:"
    echo "  CPU:           $CPU"
    echo "  Memory:        $MEMORY"
    echo "  Min instances: $MIN_INSTANCES"
    echo "  Max instances: $MAX_INSTANCES"
    echo "  Port:          $PORT"
    echo ""

    log_info "Database:"
    echo "  Instance:      $SQL_INSTANCE_NAME"
    echo "  Database:      $CALCOM_DB_NAME"
    echo "  User:          $CALCOM_DB_USER"
    echo ""

    log_info "Integration with GA Personal:"
    echo "  Webhook URL:   https://api.guialmeidapersonal.esp.br/api/v1/webhooks/calcom"
    echo "  Webhook Secret: Stored in Secret Manager as 'calcom-webhook-secret'"
    echo ""

    log_info "Next Steps:"
    echo ""
    echo "  1. Add DNS record for Cal.com:"
    echo "     - Type: CNAME"
    echo "     - Name: cal"
    echo "     - Value: ghs.googlehosted.com"
    echo ""
    echo "  2. Configure webhook in Cal.com Admin:"
    echo "     - Go to https://$CALCOM_DOMAIN/settings/developer/webhooks"
    echo "     - Add webhook URL: https://api.guialmeidapersonal.esp.br/api/v1/webhooks/calcom"
    echo "     - Select events: BOOKING_CREATED, BOOKING_CANCELLED, BOOKING_RESCHEDULED"
    echo "     - Set secret from: gcloud secrets versions access latest --secret=calcom-webhook-secret --project=$PROJECT_ID"
    echo ""
    echo "  3. Create admin user in Cal.com (first signup)"
    echo ""
    echo "  4. Update Load Balancer to route cal.guialmeidapersonal.esp.br"
    echo ""

    log_info "Useful Commands:"
    echo ""
    echo "  # View service details"
    echo "  gcloud run services describe $SERVICE_NAME --region=$REGION --project=$PROJECT_ID"
    echo ""
    echo "  # View service logs"
    echo "  gcloud run services logs read $SERVICE_NAME --region=$REGION --project=$PROJECT_ID --limit=50"
    echo ""
    echo "  # Get webhook secret"
    echo "  gcloud secrets versions access latest --secret=calcom-webhook-secret --project=$PROJECT_ID"
    echo ""
    echo "  # Restart service"
    echo "  gcloud run services update $SERVICE_NAME --region=$REGION --project=$PROJECT_ID"
    echo ""
}

# Main execution
main() {
    echo "========================================"
    echo "Deploy Cal.com Self-Hosted to GCP"
    echo "========================================"
    echo ""

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "Running in DRY RUN mode - no changes will be made"
        echo ""
    fi

    log_info "Deployment Configuration:"
    echo "  Cal.com Version: $CALCOM_VERSION"
    echo "  Domain: $CALCOM_DOMAIN"
    echo ""

    check_prerequisites
    verify_infrastructure

    echo ""
    log_info "Starting Cal.com deployment..."
    echo ""

    # Setup database
    create_calcom_database

    # Setup secrets
    create_secrets

    # Deploy the service
    deploy_service

    # Configure domain
    configure_domain

    # Get service URL
    get_service_url

    # Print summary
    print_summary

    log_info "========================================"
    log_info "Cal.com deployment complete!"
    log_info "========================================"
}

# Run main function
main "$@"
