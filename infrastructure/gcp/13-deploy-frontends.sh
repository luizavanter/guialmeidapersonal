#!/bin/bash
#
# Task 16: Build and Deploy Frontend Applications
# Project: guialmeidapersonal
# Domain: guialmeidapersonal.esp.br
#
# This script:
# - Builds all 3 frontend applications
# - Sets VITE_API_URL for API communication
# - Uploads built files to Cloud Storage buckets
# - Sets appropriate cache headers
#
# It is idempotent - safe to run multiple times.
#
# Prerequisites:
# - Node.js and npm/pnpm installed
# - gcloud CLI authenticated with appropriate permissions
# - Cloud Storage buckets created (from 07-storage.sh)
#
# Usage:
#   ./13-deploy-frontends.sh
#   ./13-deploy-frontends.sh trainer-app    # Deploy only trainer-app
#   ./13-deploy-frontends.sh student-app    # Deploy only student-app
#   ./13-deploy-frontends.sh site           # Deploy only site
#
# Environment Variables:
#   DRY_RUN=true         # Show what would be done without doing it
#   SKIP_BUILD=true      # Skip build step, only upload
#   API_URL=<url>        # Override API URL (default: https://api.guialmeidapersonal.esp.br)
#

set -e

# Configuration
PROJECT_ID="guialmeidapersonal"
API_URL="${API_URL:-https://api.guialmeidapersonal.esp.br}"

# Paths (relative to repo root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FRONTEND_DIR="$REPO_ROOT/frontend"

# Bucket mapping
declare -A BUCKET_MAP=(
    ["trainer-app"]="admin-guialmeidapersonal"
    ["student-app"]="app-guialmeidapersonal"
    ["site"]="site-guialmeidapersonal"
)

# Build output directories
declare -A BUILD_OUTPUT=(
    ["trainer-app"]="dist"
    ["student-app"]="dist"
    ["site"]="docs/.vitepress/dist"
)

# Cache control headers
CACHE_LONG="max-age=31536000,immutable"    # 1 year for hashed assets
CACHE_SHORT="max-age=300,must-revalidate"  # 5 minutes for HTML files

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

# Check required tools
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check for gcloud
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed"
        exit 1
    fi

    # Check for gsutil
    if ! command -v gsutil &> /dev/null; then
        log_error "gsutil is not installed"
        exit 1
    fi

    # Check for Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        exit 1
    fi

    # Check for pnpm (preferred) or npm
    if command -v pnpm &> /dev/null; then
        PKG_MANAGER="pnpm"
    elif command -v npm &> /dev/null; then
        PKG_MANAGER="npm"
    else
        log_error "Neither pnpm nor npm is installed"
        exit 1
    fi

    log_info "Using package manager: $PKG_MANAGER"

    # Verify project access
    if ! gcloud projects describe $PROJECT_ID &> /dev/null; then
        log_error "Cannot access project: $PROJECT_ID"
        exit 1
    fi

    # Verify buckets exist
    for app in "${!BUCKET_MAP[@]}"; do
        local bucket="${BUCKET_MAP[$app]}"
        if ! gsutil ls -b "gs://${bucket}" &>/dev/null; then
            log_error "Bucket 'gs://${bucket}' not found"
            log_error "Please run 07-storage.sh first"
            exit 1
        fi
    done

    log_info "Prerequisites check passed"
}

# Install dependencies for an app
install_dependencies() {
    local app=$1
    local app_dir="$FRONTEND_DIR/$app"

    log_info "Installing dependencies for $app..."

    if [ ! -d "$app_dir" ]; then
        log_error "App directory not found: $app_dir"
        return 1
    fi

    cd "$app_dir"

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "DRY RUN: Would install dependencies in $app_dir"
        return 0
    fi

    # Install dependencies
    if [ "$PKG_MANAGER" = "pnpm" ]; then
        pnpm install --frozen-lockfile 2>/dev/null || pnpm install
    else
        npm ci 2>/dev/null || npm install
    fi

    log_info "Dependencies installed for $app"
}

# Build a frontend application
build_app() {
    local app=$1
    local app_dir="$FRONTEND_DIR/$app"

    log_step "Building $app..."

    if [ ! -d "$app_dir" ]; then
        log_error "App directory not found: $app_dir"
        return 1
    fi

    cd "$app_dir"

    # Create .env file with API URL for Vite apps
    if [ "$app" != "site" ]; then
        log_info "Setting VITE_API_URL=$API_URL"
        if [ "$DRY_RUN" != "true" ]; then
            echo "VITE_API_URL=$API_URL" > .env.production.local
        fi
    fi

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "DRY RUN: Would build $app"
        return 0
    fi

    # Install dependencies first
    install_dependencies "$app"

    # Build the app
    if [ "$PKG_MANAGER" = "pnpm" ]; then
        pnpm run build
    else
        npm run build
    fi

    # Verify build output exists
    local output_dir="${BUILD_OUTPUT[$app]}"
    if [ ! -d "$app_dir/$output_dir" ]; then
        log_error "Build output not found: $app_dir/$output_dir"
        return 1
    fi

    log_info "$app built successfully"
}

# Upload files to Cloud Storage with proper cache headers
upload_to_bucket() {
    local app=$1
    local app_dir="$FRONTEND_DIR/$app"
    local output_dir="${BUILD_OUTPUT[$app]}"
    local bucket="${BUCKET_MAP[$app]}"
    local source_dir="$app_dir/$output_dir"

    log_step "Uploading $app to gs://$bucket..."

    if [ ! -d "$source_dir" ]; then
        log_error "Build output not found: $source_dir"
        log_error "Please build the app first"
        return 1
    fi

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "DRY RUN: Would upload $source_dir to gs://$bucket"
        return 0
    fi

    # Upload all files first with default cache headers
    log_info "Uploading files..."
    gsutil -m rsync -r -d "$source_dir" "gs://$bucket"

    # Set cache headers for different file types
    log_info "Setting cache headers..."

    # Long cache for hashed assets (JS, CSS with hash in filename)
    log_info "Setting long cache for hashed assets..."
    gsutil -m setmeta -h "Cache-Control:$CACHE_LONG" \
        "gs://$bucket/assets/**" 2>/dev/null || true

    # Long cache for static assets in _astro, chunks, etc.
    gsutil -m setmeta -h "Cache-Control:$CACHE_LONG" \
        "gs://$bucket/_astro/**" 2>/dev/null || true
    gsutil -m setmeta -h "Cache-Control:$CACHE_LONG" \
        "gs://$bucket/chunks/**" 2>/dev/null || true

    # Long cache for images, fonts, and other static assets
    gsutil -m setmeta -h "Cache-Control:$CACHE_LONG" \
        "gs://$bucket/**/*.js" 2>/dev/null || true
    gsutil -m setmeta -h "Cache-Control:$CACHE_LONG" \
        "gs://$bucket/**/*.css" 2>/dev/null || true
    gsutil -m setmeta -h "Cache-Control:$CACHE_LONG" \
        "gs://$bucket/**/*.woff2" 2>/dev/null || true
    gsutil -m setmeta -h "Cache-Control:$CACHE_LONG" \
        "gs://$bucket/**/*.woff" 2>/dev/null || true
    gsutil -m setmeta -h "Cache-Control:$CACHE_LONG" \
        "gs://$bucket/**/*.png" 2>/dev/null || true
    gsutil -m setmeta -h "Cache-Control:$CACHE_LONG" \
        "gs://$bucket/**/*.jpg" 2>/dev/null || true
    gsutil -m setmeta -h "Cache-Control:$CACHE_LONG" \
        "gs://$bucket/**/*.svg" 2>/dev/null || true
    gsutil -m setmeta -h "Cache-Control:$CACHE_LONG" \
        "gs://$bucket/**/*.ico" 2>/dev/null || true

    # Short cache for HTML files (must revalidate)
    log_info "Setting short cache for HTML files..."
    gsutil -m setmeta -h "Cache-Control:$CACHE_SHORT" \
        "gs://$bucket/**/*.html" 2>/dev/null || true
    gsutil -m setmeta -h "Cache-Control:$CACHE_SHORT" \
        "gs://$bucket/index.html" 2>/dev/null || true

    # Set correct content types
    log_info "Verifying content types..."
    gsutil -m setmeta -h "Content-Type:text/html; charset=utf-8" \
        "gs://$bucket/**/*.html" 2>/dev/null || true
    gsutil -m setmeta -h "Content-Type:application/javascript" \
        "gs://$bucket/**/*.js" 2>/dev/null || true
    gsutil -m setmeta -h "Content-Type:text/css" \
        "gs://$bucket/**/*.css" 2>/dev/null || true

    log_info "$app uploaded to gs://$bucket successfully"
}

# Deploy a single frontend application
deploy_app() {
    local app=$1

    echo ""
    log_info "========================================"
    log_info "Deploying: $app"
    log_info "========================================"
    echo ""

    if [ "$SKIP_BUILD" != "true" ]; then
        build_app "$app"
    else
        log_warn "Skipping build (SKIP_BUILD=true)"
    fi

    upload_to_bucket "$app"
}

# Print summary
print_summary() {
    echo ""
    log_info "========================================"
    log_info "Frontend Deployment Summary"
    log_info "========================================"
    echo ""

    log_info "API URL: $API_URL"
    echo ""

    log_info "Deployments:"
    for app in "${!BUCKET_MAP[@]}"; do
        local bucket="${BUCKET_MAP[$app]}"
        echo "  - $app -> gs://$bucket"
    done
    echo ""

    log_info "URLs (after DNS propagates):"
    echo "  - Admin:   https://admin.guialmeidapersonal.esp.br"
    echo "  - App:     https://app.guialmeidapersonal.esp.br"
    echo "  - Site:    https://guialmeidapersonal.esp.br"
    echo "  - Site:    https://www.guialmeidapersonal.esp.br"
    echo ""

    log_info "Cache Headers:"
    echo "  - HTML files: $CACHE_SHORT"
    echo "  - Assets:     $CACHE_LONG"
    echo ""

    log_info "========================================"
    log_info "Useful Commands"
    log_info "========================================"
    echo ""
    echo "  # List bucket contents"
    echo "  gsutil ls -la gs://admin-guialmeidapersonal"
    echo "  gsutil ls -la gs://app-guialmeidapersonal"
    echo "  gsutil ls -la gs://site-guialmeidapersonal"
    echo ""
    echo "  # Invalidate CDN cache (after updates)"
    echo "  gcloud compute url-maps invalidate-cdn-cache ga-personal-lb --path='/*' --project=$PROJECT_ID"
    echo ""
    echo "  # Check file metadata"
    echo "  gsutil stat gs://admin-guialmeidapersonal/index.html"
    echo ""
}

# Main execution
main() {
    local target_app="${1:-all}"

    echo "========================================"
    echo "Task 16: Build and Deploy Frontends"
    echo "========================================"
    echo ""

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "Running in DRY RUN mode - no changes will be made"
        echo ""
    fi

    check_prerequisites

    echo ""
    log_info "Starting frontend deployment..."
    log_info "Target: $target_app"
    log_info "API URL: $API_URL"
    echo ""

    if [ "$target_app" = "all" ]; then
        # Deploy all frontends
        for app in "trainer-app" "student-app" "site"; do
            deploy_app "$app"
        done
    else
        # Deploy specific app
        if [[ -v "BUCKET_MAP[$target_app]" ]]; then
            deploy_app "$target_app"
        else
            log_error "Unknown app: $target_app"
            log_error "Available apps: trainer-app, student-app, site"
            exit 1
        fi
    fi

    print_summary

    log_info "========================================"
    log_info "Frontend deployment complete!"
    log_info "========================================"
}

# Run main function
main "$@"
