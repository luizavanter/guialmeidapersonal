#!/bin/bash
#
# Task 7: Create Cloud Storage Buckets
# Project: guialmeidapersonal
# Region: southamerica-east1
#
# This script creates and configures Cloud Storage buckets for:
# - Frontend static hosting (admin, app, site)
# - Media uploads (private)
#
# It is idempotent - safe to run multiple times.
#
# Prerequisites:
# - gcloud CLI authenticated with appropriate permissions
# - gsutil available (included with gcloud SDK)
#
# Usage:
#   ./07-storage.sh
#

set -e

# Configuration
PROJECT="guialmeidapersonal"
REGION="southamerica-east1"

# Bucket names
BUCKET_ADMIN="admin-guialmeidapersonal"
BUCKET_APP="app-guialmeidapersonal"
BUCKET_SITE="site-guialmeidapersonal"
BUCKET_MEDIA="media-guialmeidapersonal"

# Policy files (relative to script directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIFECYCLE_POLICY="$SCRIPT_DIR/lifecycle-policy.json"
CORS_POLICY="$SCRIPT_DIR/cors-policy.json"
MEDIA_LIFECYCLE_POLICY="$SCRIPT_DIR/media-lifecycle-policy.json"

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

    if ! command -v gsutil &> /dev/null; then
        log_error "gsutil is not installed (should be part of gcloud SDK)"
        exit 1
    fi

    # Verify project access
    if ! gcloud projects describe $PROJECT &> /dev/null; then
        log_error "Cannot access project: $PROJECT"
        exit 1
    fi

    # Check policy files exist
    for policy_file in "$LIFECYCLE_POLICY" "$CORS_POLICY" "$MEDIA_LIFECYCLE_POLICY"; do
        if [ ! -f "$policy_file" ]; then
            log_error "Policy file not found: $policy_file"
            exit 1
        fi
    done

    log_info "Prerequisites check passed"
}

# Check if bucket exists
bucket_exists() {
    local bucket_name=$1
    gsutil ls -b "gs://${bucket_name}" &>/dev/null
}

# Create a bucket if it doesn't exist
create_bucket() {
    local bucket_name=$1
    local storage_class=${2:-STANDARD}

    if bucket_exists "$bucket_name"; then
        log_warn "Bucket 'gs://${bucket_name}' already exists, skipping creation"
        return 0
    fi

    log_info "Creating bucket 'gs://${bucket_name}'..."
    gsutil mb -p "$PROJECT" -c "$storage_class" -l "$REGION" "gs://${bucket_name}"
    log_info "Bucket 'gs://${bucket_name}' created successfully"
}

# Make bucket publicly readable
make_public() {
    local bucket_name=$1

    log_info "Making 'gs://${bucket_name}' publicly readable..."
    gsutil iam ch allUsers:objectViewer "gs://${bucket_name}"
}

# Enable versioning on bucket
enable_versioning() {
    local bucket_name=$1

    log_info "Enabling versioning on 'gs://${bucket_name}'..."
    gsutil versioning set on "gs://${bucket_name}"
}

# Set lifecycle policy on bucket
set_lifecycle() {
    local bucket_name=$1
    local policy_file=$2

    log_info "Setting lifecycle policy on 'gs://${bucket_name}'..."
    gsutil lifecycle set "$policy_file" "gs://${bucket_name}"
}

# Set CORS policy on bucket
set_cors() {
    local bucket_name=$1
    local policy_file=$2

    log_info "Setting CORS policy on 'gs://${bucket_name}'..."
    gsutil cors set "$policy_file" "gs://${bucket_name}"
}

# Set website configuration for static hosting
set_website_config() {
    local bucket_name=$1

    log_info "Setting website configuration on 'gs://${bucket_name}'..."
    gsutil web set -m index.html -e 404.html "gs://${bucket_name}"
}

# Configure frontend bucket (public, versioned, lifecycle)
configure_frontend_bucket() {
    local bucket_name=$1

    log_info "Configuring frontend bucket: $bucket_name"
    create_bucket "$bucket_name" "STANDARD"
    make_public "$bucket_name"
    enable_versioning "$bucket_name"
    set_lifecycle "$bucket_name" "$LIFECYCLE_POLICY"
    set_website_config "$bucket_name"
    log_info "Frontend bucket '$bucket_name' configured successfully"
    echo ""
}

# Configure media bucket (private, CORS, coldline lifecycle)
configure_media_bucket() {
    local bucket_name=$1

    log_info "Configuring media bucket: $bucket_name"
    create_bucket "$bucket_name" "STANDARD"
    # Media bucket stays private (no public access)
    set_cors "$bucket_name" "$CORS_POLICY"
    set_lifecycle "$bucket_name" "$MEDIA_LIFECYCLE_POLICY"
    log_info "Media bucket '$bucket_name' configured successfully"
    echo ""
}

# Print summary of bucket configurations
print_summary() {
    echo ""
    log_info "========================================"
    log_info "Cloud Storage Buckets Summary"
    log_info "========================================"
    echo ""

    log_info "Frontend Buckets (public, CDN-ready):"
    for bucket in "$BUCKET_ADMIN" "$BUCKET_APP" "$BUCKET_SITE"; do
        echo "  - gs://${bucket}/"
        echo "    Public: Yes (allUsers:objectViewer)"
        echo "    Versioning: Enabled"
        echo "    Lifecycle: Delete versions older than 3 newer versions"
        echo ""
    done

    log_info "Media Bucket (private):"
    echo "  - gs://${BUCKET_MEDIA}/"
    echo "    Public: No"
    echo "    CORS: Enabled for admin/app domains"
    echo "    Lifecycle: Move to Coldline after 90 days"
    echo ""

    log_info "Bucket URLs:"
    echo "  Admin:   https://storage.googleapis.com/${BUCKET_ADMIN}/index.html"
    echo "  App:     https://storage.googleapis.com/${BUCKET_APP}/index.html"
    echo "  Site:    https://storage.googleapis.com/${BUCKET_SITE}/index.html"
    echo "  Media:   gs://${BUCKET_MEDIA}/ (access via signed URLs)"
    echo ""
}

# Main execution
main() {
    echo "========================================"
    echo "Task 7: Create Cloud Storage Buckets"
    echo "========================================"
    echo ""

    check_prerequisites

    echo ""
    log_info "Creating and configuring buckets..."
    echo ""

    # Configure frontend buckets
    configure_frontend_bucket "$BUCKET_ADMIN"
    configure_frontend_bucket "$BUCKET_APP"
    configure_frontend_bucket "$BUCKET_SITE"

    # Configure media bucket
    configure_media_bucket "$BUCKET_MEDIA"

    # Print summary
    print_summary

    log_info "========================================"
    log_info "Cloud Storage setup complete!"
    log_info "========================================"
    echo ""
    log_warn "NOTE: For production, configure Cloud CDN and Load Balancer"
    log_warn "      to serve frontend buckets through your custom domain."
}

# Run main function
main "$@"
