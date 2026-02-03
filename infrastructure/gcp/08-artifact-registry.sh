#!/bin/bash
#
# Task 8: Create Artifact Registry Repository
# Project: guialmeidapersonal
# Region: southamerica-east1
#
# This script creates a Docker repository in Artifact Registry for
# storing container images used by the GA Personal application.
#
# It is idempotent - safe to run multiple times.
#
# Prerequisites:
# - gcloud CLI authenticated with appropriate permissions
# - Artifact Registry API enabled
#
# Usage:
#   ./08-artifact-registry.sh
#

set -e

# Configuration
PROJECT="guialmeidapersonal"
REGION="southamerica-east1"
REPOSITORY_NAME="ga-personal"
REPOSITORY_FORMAT="docker"
REPOSITORY_DESCRIPTION="Docker images for GA Personal application"

# Full repository path
REPOSITORY_PATH="${REGION}-docker.pkg.dev/${PROJECT}/${REPOSITORY_NAME}"

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

# Check required tools and permissions
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed"
        exit 1
    fi

    # Verify project access
    if ! gcloud projects describe $PROJECT &> /dev/null; then
        log_error "Cannot access project: $PROJECT"
        exit 1
    fi

    # Check if Artifact Registry API is enabled
    if ! gcloud services list --project=$PROJECT --enabled --filter="name:artifactregistry.googleapis.com" --format="value(name)" | grep -q "artifactregistry"; then
        log_warn "Artifact Registry API may not be enabled. Enabling now..."
        gcloud services enable artifactregistry.googleapis.com --project=$PROJECT
        log_info "Artifact Registry API enabled"
    fi

    log_info "Prerequisites check passed"
}

# Check if repository exists
repository_exists() {
    gcloud artifacts repositories describe "$REPOSITORY_NAME" \
        --location="$REGION" \
        --project="$PROJECT" &>/dev/null
}

# Create Artifact Registry repository
create_repository() {
    if repository_exists; then
        log_warn "Repository '$REPOSITORY_NAME' already exists, skipping creation"
        return 0
    fi

    log_info "Creating Artifact Registry repository '$REPOSITORY_NAME'..."
    gcloud artifacts repositories create "$REPOSITORY_NAME" \
        --repository-format="$REPOSITORY_FORMAT" \
        --location="$REGION" \
        --description="$REPOSITORY_DESCRIPTION" \
        --project="$PROJECT"

    log_info "Repository '$REPOSITORY_NAME' created successfully"
}

# Configure Docker authentication
configure_docker_auth() {
    log_info "Configuring Docker authentication for ${REGION}-docker.pkg.dev..."

    # This command updates Docker config to use gcloud as credential helper
    gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

    log_info "Docker authentication configured"
}

# Verify repository configuration
verify_repository() {
    log_info "Verifying repository configuration..."

    echo ""
    gcloud artifacts repositories describe "$REPOSITORY_NAME" \
        --location="$REGION" \
        --project="$PROJECT"
    echo ""

    log_info "Repository verification complete"
}

# Print summary
print_summary() {
    echo ""
    log_info "========================================"
    log_info "Artifact Registry Summary"
    log_info "========================================"
    echo ""

    log_info "Repository Details:"
    echo "  Name:        $REPOSITORY_NAME"
    echo "  Format:      $REPOSITORY_FORMAT"
    echo "  Region:      $REGION"
    echo "  Project:     $PROJECT"
    echo ""

    log_info "Repository Path:"
    echo "  ${REPOSITORY_PATH}"
    echo ""

    log_info "Docker Push Example:"
    echo "  docker tag my-image:latest ${REPOSITORY_PATH}/my-image:latest"
    echo "  docker push ${REPOSITORY_PATH}/my-image:latest"
    echo ""

    log_info "Docker Pull Example:"
    echo "  docker pull ${REPOSITORY_PATH}/my-image:latest"
    echo ""
}

# Main execution
main() {
    echo "========================================"
    echo "Task 8: Create Artifact Registry Repository"
    echo "========================================"
    echo ""

    check_prerequisites

    echo ""
    log_info "Creating Artifact Registry repository..."
    echo ""

    # Create the repository
    create_repository

    # Configure Docker authentication
    configure_docker_auth

    # Verify the repository
    verify_repository

    # Print summary
    print_summary

    log_info "========================================"
    log_info "Artifact Registry setup complete!"
    log_info "========================================"
    echo ""
    log_warn "NOTE: Cloud Run service accounts will need"
    log_warn "      'artifactregistry.reader' role to pull images."
}

# Run main function
main "$@"
