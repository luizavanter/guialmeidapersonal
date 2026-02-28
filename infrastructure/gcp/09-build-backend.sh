#!/bin/bash
#
# Task 10: Build and Push Backend Docker Image
# Project: guialmeidapersonal
# Region: southamerica-east1
#
# This script builds the backend Docker image using Google Cloud Build
# and pushes it to Artifact Registry.
#
# It is idempotent - safe to run multiple times.
# Each run will create a new image with the specified tag.
#
# Prerequisites:
# - gcloud CLI authenticated with appropriate permissions
# - Cloud Build API enabled
# - Artifact Registry repository created (run 08-artifact-registry.sh first)
# - Valid Dockerfile in project root
#
# Usage:
#   ./09-build-backend.sh [TAG]
#
# Arguments:
#   TAG - Image tag (default: latest)
#
# Examples:
#   ./09-build-backend.sh           # Builds with tag 'latest'
#   ./09-build-backend.sh v1.0.0    # Builds with tag 'v1.0.0'
#   ./09-build-backend.sh $(git rev-parse --short HEAD)  # Use git commit hash
#

set -e

# Configuration
PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
REPO="ga-personal"
IMAGE_NAME="backend"
TAG="${1:-latest}"

# Full image path
FULL_IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE_NAME}:${TAG}"

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
    if ! gcloud projects describe $PROJECT_ID &> /dev/null; then
        log_error "Cannot access project: $PROJECT_ID"
        exit 1
    fi

    # Check if Cloud Build API is enabled
    if ! gcloud services list --project=$PROJECT_ID --enabled --filter="name:cloudbuild.googleapis.com" --format="value(name)" | grep -q "cloudbuild"; then
        log_warn "Cloud Build API may not be enabled. Enabling now..."
        gcloud services enable cloudbuild.googleapis.com --project=$PROJECT_ID
        log_info "Cloud Build API enabled"
    fi

    # Check if Dockerfile exists
    if [[ ! -f "Dockerfile" ]]; then
        log_error "Dockerfile not found in current directory"
        log_error "Please run this script from the project root directory"
        exit 1
    fi

    log_info "Prerequisites check passed"
}

# Check if Artifact Registry repository exists
check_repository() {
    log_info "Verifying Artifact Registry repository exists..."

    if ! gcloud artifacts repositories describe "$REPO" \
        --location="$REGION" \
        --project="$PROJECT_ID" &>/dev/null; then
        log_error "Artifact Registry repository '$REPO' does not exist"
        log_error "Please run 08-artifact-registry.sh first"
        exit 1
    fi

    log_info "Repository '$REPO' verified"
}

# Build and push the Docker image
build_and_push() {
    log_info "Building and pushing backend Docker image..."
    log_info "Tag: $TAG"
    log_info "Full image path: $FULL_IMAGE_PATH"
    echo ""

    gcloud builds submit \
        --tag "$FULL_IMAGE_PATH" \
        --project="$PROJECT_ID" \
        .

    log_info "Image built and pushed successfully!"
}

# Verify the image was pushed
verify_image() {
    log_info "Verifying image in Artifact Registry..."

    gcloud artifacts docker images list \
        "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}" \
        --project="$PROJECT_ID" \
        --filter="package=${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE_NAME}" \
        --limit=5

    echo ""
    log_info "Image verification complete"
}

# Print summary
print_summary() {
    echo ""
    log_info "========================================"
    log_info "Build Summary"
    log_info "========================================"
    echo ""

    log_info "Image Details:"
    echo "  Name:        $IMAGE_NAME"
    echo "  Tag:         $TAG"
    echo "  Repository:  $REPO"
    echo "  Region:      $REGION"
    echo "  Project:     $PROJECT_ID"
    echo ""

    log_info "Full Image Path:"
    echo "  $FULL_IMAGE_PATH"
    echo ""

    log_info "Deploy to Cloud Run:"
    echo "  gcloud run deploy ga-personal-backend \\"
    echo "    --image=$FULL_IMAGE_PATH \\"
    echo "    --region=$REGION \\"
    echo "    --project=$PROJECT_ID"
    echo ""
}

# Main execution
main() {
    echo "========================================"
    echo "Task 10: Build and Push Backend Image"
    echo "========================================"
    echo ""

    check_prerequisites
    check_repository

    echo ""
    log_info "Starting build process..."
    echo ""

    # Build and push the image
    build_and_push

    # Verify the image
    verify_image

    # Print summary
    print_summary

    log_info "========================================"
    log_info "Backend image build complete!"
    log_info "========================================"
}

# Run main function
main "$@"
