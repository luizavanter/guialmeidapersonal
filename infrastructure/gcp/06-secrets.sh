#!/bin/bash
#
# Task 6: Create Secrets in Secret Manager
# Project: guialmeidapersonal
# Region: southamerica-east1
#
# This script creates and manages secrets in Google Cloud Secret Manager.
# It is idempotent - safe to run multiple times.
#
# Prerequisites:
# - gcloud CLI authenticated with appropriate permissions
# - Cloud SQL instance (ga-personal-db) exists
# - Redis instance (ga-personal-redis) exists
# - Service account (backend-sa) exists
#
# Usage:
#   ./06-secrets.sh                    # Interactive mode (prompts for DB password)
#   DB_PASSWORD="xxx" ./06-secrets.sh  # Non-interactive mode
#

set -e

# Configuration
PROJECT="guialmeidapersonal"
REGION="southamerica-east1"
SERVICE_ACCOUNT="backend-sa@guialmeidapersonal.iam.gserviceaccount.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check required tools
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed"
        exit 1
    fi

    if ! command -v openssl &> /dev/null; then
        log_error "openssl is not installed"
        exit 1
    fi

    # Verify project access
    if ! gcloud projects describe $PROJECT &> /dev/null; then
        log_error "Cannot access project: $PROJECT"
        exit 1
    fi

    log_info "Prerequisites check passed"
}

# Enable Secret Manager API if not already enabled
enable_api() {
    log_info "Ensuring Secret Manager API is enabled..."
    gcloud services enable secretmanager.googleapis.com --project=$PROJECT --quiet
}

# Get database password
get_db_password() {
    if [ -z "$DB_PASSWORD" ]; then
        log_info "DB_PASSWORD environment variable not set"
        echo -n "Enter database password: "
        read -rs DB_PASSWORD
        echo ""

        if [ -z "$DB_PASSWORD" ]; then
            log_error "Database password is required"
            exit 1
        fi
    fi
}

# Get infrastructure values
get_infrastructure_values() {
    log_info "Fetching infrastructure values..."

    # Get Cloud SQL private IP
    DB_PRIVATE_IP=$(gcloud sql instances describe ga-personal-db \
        --project=$PROJECT \
        --format="value(ipAddresses[0].ipAddress)" 2>/dev/null) || {
        log_error "Failed to get Cloud SQL instance IP. Is ga-personal-db running?"
        exit 1
    }

    # Get Redis host
    REDIS_HOST=$(gcloud redis instances describe ga-personal-redis \
        --region=$REGION \
        --project=$PROJECT \
        --format="value(host)" 2>/dev/null) || {
        log_error "Failed to get Redis host. Is ga-personal-redis running?"
        exit 1
    }

    log_info "Cloud SQL IP: $DB_PRIVATE_IP"
    log_info "Redis host: $REDIS_HOST"
}

# Build connection strings (values not printed for security)
build_connection_strings() {
    log_info "Building connection strings..."

    DATABASE_URL="postgresql://ga_personal_user:${DB_PASSWORD}@${DB_PRIVATE_IP}:5432/ga_personal_prod"
    REDIS_URL="redis://${REDIS_HOST}:6379/0"

    log_info "Connection strings built successfully"
}

# Generate new secrets
generate_secrets() {
    log_info "Generating cryptographic secrets..."

    # JWT secret: 64-byte hex (128 characters)
    JWT_SECRET=$(openssl rand -hex 64)

    # Phoenix secret key base: base64 encoded
    SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d '\n')

    log_info "Secrets generated successfully"
}

# Create or update a secret
# Usage: create_or_update_secret <secret_name> <secret_value>
create_or_update_secret() {
    local secret_name=$1
    local secret_value=$2

    if gcloud secrets describe "$secret_name" --project=$PROJECT &>/dev/null; then
        log_warn "Secret '$secret_name' already exists, adding new version..."
        echo -n "$secret_value" | gcloud secrets versions add "$secret_name" \
            --data-file=- \
            --project=$PROJECT
        log_info "Added new version to secret '$secret_name'"
    else
        log_info "Creating secret '$secret_name'..."
        echo -n "$secret_value" | gcloud secrets create "$secret_name" \
            --data-file=- \
            --replication-policy="user-managed" \
            --locations="$REGION" \
            --project=$PROJECT
        log_info "Created secret '$secret_name'"
    fi
}

# Grant service account access to secrets
grant_access() {
    local secret_name=$1

    log_info "Granting $SERVICE_ACCOUNT access to '$secret_name'..."

    gcloud secrets add-iam-policy-binding "$secret_name" \
        --member="serviceAccount:$SERVICE_ACCOUNT" \
        --role="roles/secretmanager.secretAccessor" \
        --project=$PROJECT \
        --quiet > /dev/null
}

# Main execution
main() {
    echo "========================================"
    echo "Task 6: Create Secrets in Secret Manager"
    echo "========================================"
    echo ""

    check_prerequisites
    enable_api
    get_db_password
    get_infrastructure_values
    build_connection_strings
    generate_secrets

    echo ""
    log_info "Creating secrets in Secret Manager..."
    echo ""

    # Create all secrets
    create_or_update_secret "database-url" "$DATABASE_URL"
    create_or_update_secret "redis-url" "$REDIS_URL"
    create_or_update_secret "jwt-secret" "$JWT_SECRET"
    create_or_update_secret "secret-key-base" "$SECRET_KEY_BASE"

    echo ""
    log_info "Granting IAM access to backend service account..."
    echo ""

    # Grant access to all secrets
    for secret in database-url redis-url jwt-secret secret-key-base; do
        grant_access "$secret"
    done

    echo ""
    log_info "========================================"
    log_info "Secret Manager setup complete!"
    log_info "========================================"
    echo ""
    log_info "Secrets created:"
    gcloud secrets list --project=$PROJECT \
        --format="table(name,createTime)" \
        --filter="name:(database-url OR redis-url OR jwt-secret OR secret-key-base)"
    echo ""
    log_info "IAM bindings: backend-sa has secretAccessor role on all secrets"
    echo ""
    log_warn "SECURITY NOTE: Do not print or log secret values!"
    log_warn "Access secrets via: gcloud secrets versions access latest --secret=<name>"
}

# Run main function
main "$@"
