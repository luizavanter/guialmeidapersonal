#!/bin/bash
#
# Tasks 12-14: Complete Load Balancer with SSL and CDN Configuration
# Project: guialmeidapersonal
# Region: southamerica-east1
# Domain: guialmeidapersonal.com.br
#
# This script creates:
# - Global static IP address
# - Backend buckets with CDN for static hosting
# - Serverless NEG and backend service for Cloud Run API
# - URL map with host-based routing
# - HTTP and HTTPS proxies and forwarding rules
# - SSL certificate with Certificate Manager (wildcard)
#
# It is idempotent - safe to run multiple times.
#
# Prerequisites:
# - gcloud CLI authenticated with appropriate permissions
# - Compute Engine API enabled
# - Certificate Manager API enabled
# - Cloud Storage buckets created (admin, app, site)
# - Cloud Run service deployed (ga-personal-api)
#
# Usage:
#   ./11-load-balancer.sh
#
# Environment Variables:
#   DRY_RUN=true   # Show what would be created without creating
#

set -e

# Configuration
PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
DOMAIN="guialmeidapersonal.com.br"

# Resource names
STATIC_IP_NAME="ga-personal-ip"
CLOUD_RUN_SERVICE="ga-personal-api"

# Backend buckets
BUCKET_ADMIN="admin-guialmeidapersonal"
BUCKET_APP="app-guialmeidapersonal"
BUCKET_SITE="site-guialmeidapersonal"

BACKEND_ADMIN="admin-backend"
BACKEND_APP="app-backend"
BACKEND_SITE="site-backend"

# API backend
NEG_NAME="api-neg"
BACKEND_API="api-backend"
HEALTH_CHECK_NAME="api-health-check"

# URL Map and Proxies
URL_MAP_NAME="ga-personal-lb"
HTTP_PROXY_NAME="ga-personal-http-proxy"
HTTPS_PROXY_NAME="ga-personal-https-proxy"
HTTP_RULE_NAME="ga-personal-http-rule"
HTTPS_RULE_NAME="ga-personal-https-rule"

# SSL Certificate
CERT_NAME="ga-personal-cert"
CERT_MAP_NAME="ga-personal-cert-map"

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

    # Enable required APIs
    local apis=("compute.googleapis.com" "certificatemanager.googleapis.com")
    for api in "${apis[@]}"; do
        if ! gcloud services list --project=$PROJECT_ID --enabled --filter="name:$api" --format="value(name)" | grep -q "$api"; then
            log_warn "Enabling API: $api"
            gcloud services enable "$api" --project=$PROJECT_ID
        fi
    done

    log_info "Prerequisites check passed"
}

# Verify required infrastructure exists
verify_infrastructure() {
    log_info "Verifying required infrastructure..."

    # Check storage buckets exist
    local buckets=("$BUCKET_ADMIN" "$BUCKET_APP" "$BUCKET_SITE")
    for bucket in "${buckets[@]}"; do
        if ! gsutil ls -b "gs://${bucket}" &>/dev/null; then
            log_error "Bucket 'gs://${bucket}' not found"
            log_error "Please run 07-storage.sh first"
            exit 1
        fi
    done
    log_info "Storage buckets verified"

    # Check Cloud Run service exists
    if ! gcloud run services describe $CLOUD_RUN_SERVICE \
        --region=$REGION \
        --project=$PROJECT_ID &>/dev/null; then
        log_warn "Cloud Run service '$CLOUD_RUN_SERVICE' not found"
        log_warn "API backend will be configured but may not work until service is deployed"
    else
        log_info "Cloud Run service verified"
    fi

    log_info "Infrastructure verification complete"
}

#============================================================================
# TASK 12: Static IP and Backend Services
#============================================================================

# Reserve global static IP
create_static_ip() {
    log_step "Creating global static IP..."

    if gcloud compute addresses describe $STATIC_IP_NAME \
        --global \
        --project=$PROJECT_ID &>/dev/null; then
        log_warn "Static IP '$STATIC_IP_NAME' already exists"
    else
        if [ "$DRY_RUN" = "true" ]; then
            log_warn "DRY RUN: Would create static IP: $STATIC_IP_NAME"
        else
            gcloud compute addresses create $STATIC_IP_NAME \
                --global \
                --ip-version=IPV4 \
                --project=$PROJECT_ID
            log_info "Static IP '$STATIC_IP_NAME' created"
        fi
    fi

    # Get and display the IP address
    if [ "$DRY_RUN" != "true" ]; then
        STATIC_IP=$(gcloud compute addresses describe $STATIC_IP_NAME \
            --global \
            --project=$PROJECT_ID \
            --format="value(address)")
        log_info "Static IP Address: $STATIC_IP"
    fi
}

# Create backend bucket with CDN
create_backend_bucket() {
    local backend_name=$1
    local bucket_name=$2

    log_info "Creating backend bucket: $backend_name -> gs://$bucket_name"

    if gcloud compute backend-buckets describe $backend_name \
        --project=$PROJECT_ID &>/dev/null; then
        log_warn "Backend bucket '$backend_name' already exists, updating..."
        if [ "$DRY_RUN" != "true" ]; then
            gcloud compute backend-buckets update $backend_name \
                --gcs-bucket-name=$bucket_name \
                --enable-cdn \
                --project=$PROJECT_ID
        fi
    else
        if [ "$DRY_RUN" = "true" ]; then
            log_warn "DRY RUN: Would create backend bucket: $backend_name"
        else
            gcloud compute backend-buckets create $backend_name \
                --gcs-bucket-name=$bucket_name \
                --enable-cdn \
                --project=$PROJECT_ID
            log_info "Backend bucket '$backend_name' created with CDN enabled"
        fi
    fi
}

# Create all backend buckets
create_backend_buckets() {
    log_step "Creating backend buckets with CDN..."

    create_backend_bucket "$BACKEND_SITE" "$BUCKET_SITE"
    create_backend_bucket "$BACKEND_ADMIN" "$BUCKET_ADMIN"
    create_backend_bucket "$BACKEND_APP" "$BUCKET_APP"

    log_info "All backend buckets configured"
}

# Create health check for API backend
create_health_check() {
    log_step "Creating health check for API..."

    if gcloud compute health-checks describe $HEALTH_CHECK_NAME \
        --project=$PROJECT_ID &>/dev/null; then
        log_warn "Health check '$HEALTH_CHECK_NAME' already exists"
    else
        if [ "$DRY_RUN" = "true" ]; then
            log_warn "DRY RUN: Would create health check: $HEALTH_CHECK_NAME"
        else
            gcloud compute health-checks create http $HEALTH_CHECK_NAME \
                --port=80 \
                --request-path="/api/health" \
                --check-interval=30s \
                --timeout=10s \
                --healthy-threshold=2 \
                --unhealthy-threshold=3 \
                --project=$PROJECT_ID
            log_info "Health check '$HEALTH_CHECK_NAME' created"
        fi
    fi
}

# Create serverless NEG for Cloud Run
create_api_neg() {
    log_step "Creating serverless NEG for Cloud Run API..."

    if gcloud compute network-endpoint-groups describe $NEG_NAME \
        --region=$REGION \
        --project=$PROJECT_ID &>/dev/null; then
        log_warn "NEG '$NEG_NAME' already exists"
    else
        if [ "$DRY_RUN" = "true" ]; then
            log_warn "DRY RUN: Would create NEG: $NEG_NAME"
        else
            gcloud compute network-endpoint-groups create $NEG_NAME \
                --region=$REGION \
                --network-endpoint-type=serverless \
                --cloud-run-service=$CLOUD_RUN_SERVICE \
                --project=$PROJECT_ID
            log_info "NEG '$NEG_NAME' created"
        fi
    fi
}

# Create backend service for API
create_api_backend() {
    log_step "Creating backend service for API..."

    if gcloud compute backend-services describe $BACKEND_API \
        --global \
        --project=$PROJECT_ID &>/dev/null; then
        log_warn "Backend service '$BACKEND_API' already exists"
    else
        if [ "$DRY_RUN" = "true" ]; then
            log_warn "DRY RUN: Would create backend service: $BACKEND_API"
        else
            gcloud compute backend-services create $BACKEND_API \
                --global \
                --load-balancing-scheme=EXTERNAL_MANAGED \
                --project=$PROJECT_ID
            log_info "Backend service '$BACKEND_API' created"
        fi
    fi

    # Add NEG to backend service
    if [ "$DRY_RUN" != "true" ]; then
        log_info "Adding NEG to backend service..."
        gcloud compute backend-services add-backend $BACKEND_API \
            --global \
            --network-endpoint-group=$NEG_NAME \
            --network-endpoint-group-region=$REGION \
            --project=$PROJECT_ID 2>/dev/null || log_warn "NEG may already be attached to backend"
    fi
}

#============================================================================
# TASK 13: URL Map and HTTP Proxy
#============================================================================

# Create URL map with host-based routing
create_url_map() {
    log_step "Creating URL map with host-based routing..."

    if gcloud compute url-maps describe $URL_MAP_NAME \
        --project=$PROJECT_ID &>/dev/null; then
        log_warn "URL map '$URL_MAP_NAME' already exists"
    else
        if [ "$DRY_RUN" = "true" ]; then
            log_warn "DRY RUN: Would create URL map: $URL_MAP_NAME"
        else
            # Create URL map with default backend (site)
            gcloud compute url-maps create $URL_MAP_NAME \
                --default-backend-bucket=$BACKEND_SITE \
                --project=$PROJECT_ID
            log_info "URL map '$URL_MAP_NAME' created with default backend: $BACKEND_SITE"
        fi
    fi

    # Add host rules
    if [ "$DRY_RUN" != "true" ]; then
        log_info "Configuring host-based routing rules..."

        # Create URL map configuration file
        cat > /tmp/url-map-config.yaml << EOF
name: $URL_MAP_NAME
defaultService: https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/global/backendBuckets/$BACKEND_SITE
hostRules:
  - hosts:
      - 'api.$DOMAIN'
      - 'api.guialmeidapersonal.esp.br'
    pathMatcher: api-paths
  - hosts:
      - 'admin.$DOMAIN'
      - 'admin.guialmeidapersonal.esp.br'
    pathMatcher: admin-paths
  - hosts:
      - 'app.$DOMAIN'
      - 'app.guialmeidapersonal.esp.br'
    pathMatcher: app-paths
  - hosts:
      - '$DOMAIN'
      - 'www.$DOMAIN'
      - 'guialmeidapersonal.esp.br'
      - 'www.guialmeidapersonal.esp.br'
    pathMatcher: site-paths
pathMatchers:
  - name: api-paths
    defaultService: https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/global/backendServices/$BACKEND_API
  - name: admin-paths
    defaultService: https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/global/backendBuckets/$BACKEND_ADMIN
  - name: app-paths
    defaultService: https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/global/backendBuckets/$BACKEND_APP
  - name: site-paths
    defaultService: https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/global/backendBuckets/$BACKEND_SITE
EOF

        gcloud compute url-maps import $URL_MAP_NAME \
            --source=/tmp/url-map-config.yaml \
            --global \
            --project=$PROJECT_ID \
            --quiet

        rm /tmp/url-map-config.yaml
        log_info "URL map host rules configured"
    fi
}

# Create HTTP target proxy
create_http_proxy() {
    log_step "Creating HTTP target proxy..."

    if gcloud compute target-http-proxies describe $HTTP_PROXY_NAME \
        --project=$PROJECT_ID &>/dev/null; then
        log_warn "HTTP proxy '$HTTP_PROXY_NAME' already exists"
    else
        if [ "$DRY_RUN" = "true" ]; then
            log_warn "DRY RUN: Would create HTTP proxy: $HTTP_PROXY_NAME"
        else
            gcloud compute target-http-proxies create $HTTP_PROXY_NAME \
                --url-map=$URL_MAP_NAME \
                --project=$PROJECT_ID
            log_info "HTTP proxy '$HTTP_PROXY_NAME' created"
        fi
    fi
}

# Create HTTP forwarding rule
create_http_forwarding_rule() {
    log_step "Creating HTTP forwarding rule (port 80)..."

    if gcloud compute forwarding-rules describe $HTTP_RULE_NAME \
        --global \
        --project=$PROJECT_ID &>/dev/null; then
        log_warn "HTTP forwarding rule '$HTTP_RULE_NAME' already exists"
    else
        if [ "$DRY_RUN" = "true" ]; then
            log_warn "DRY RUN: Would create HTTP forwarding rule: $HTTP_RULE_NAME"
        else
            gcloud compute forwarding-rules create $HTTP_RULE_NAME \
                --global \
                --load-balancing-scheme=EXTERNAL_MANAGED \
                --target-http-proxy=$HTTP_PROXY_NAME \
                --ports=80 \
                --address=$STATIC_IP_NAME \
                --project=$PROJECT_ID
            log_info "HTTP forwarding rule '$HTTP_RULE_NAME' created"
        fi
    fi
}

#============================================================================
# TASK 14: SSL Certificate and HTTPS
#============================================================================

# Create SSL certificate with Certificate Manager
create_ssl_certificate() {
    log_step "Creating SSL certificate with Certificate Manager..."

    # Check if certificate exists
    if gcloud certificate-manager certificates describe $CERT_NAME \
        --project=$PROJECT_ID &>/dev/null; then
        log_warn "Certificate '$CERT_NAME' already exists"
    else
        if [ "$DRY_RUN" = "true" ]; then
            log_warn "DRY RUN: Would create certificate: $CERT_NAME"
        else
            # Create Google-managed certificate with multiple domains
            gcloud certificate-manager certificates create $CERT_NAME \
                --domains="$DOMAIN,*.$DOMAIN,guialmeidapersonal.esp.br,*.guialmeidapersonal.esp.br" \
                --project=$PROJECT_ID
            log_info "Certificate '$CERT_NAME' created (provisioning may take 15-60 minutes)"
        fi
    fi
}

# Create certificate map
create_certificate_map() {
    log_step "Creating certificate map..."

    # Check if certificate map exists
    if gcloud certificate-manager maps describe $CERT_MAP_NAME \
        --project=$PROJECT_ID &>/dev/null; then
        log_warn "Certificate map '$CERT_MAP_NAME' already exists"
    else
        if [ "$DRY_RUN" = "true" ]; then
            log_warn "DRY RUN: Would create certificate map: $CERT_MAP_NAME"
        else
            gcloud certificate-manager maps create $CERT_MAP_NAME \
                --project=$PROJECT_ID
            log_info "Certificate map '$CERT_MAP_NAME' created"
        fi
    fi
}

# Create certificate map entries
create_certificate_map_entries() {
    log_step "Creating certificate map entries..."

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "DRY RUN: Would create certificate map entries"
        return
    fi

    # Primary domain entry
    local entry_name="${CERT_MAP_NAME}-entry-primary"
    if ! gcloud certificate-manager maps entries describe $entry_name \
        --map=$CERT_MAP_NAME \
        --project=$PROJECT_ID &>/dev/null; then
        gcloud certificate-manager maps entries create $entry_name \
            --map=$CERT_MAP_NAME \
            --certificates=$CERT_NAME \
            --hostname="$DOMAIN" \
            --project=$PROJECT_ID
        log_info "Certificate map entry for $DOMAIN created"
    else
        log_warn "Certificate map entry '$entry_name' already exists"
    fi

    # Wildcard entry for primary domain
    entry_name="${CERT_MAP_NAME}-entry-wildcard"
    if ! gcloud certificate-manager maps entries describe $entry_name \
        --map=$CERT_MAP_NAME \
        --project=$PROJECT_ID &>/dev/null; then
        gcloud certificate-manager maps entries create $entry_name \
            --map=$CERT_MAP_NAME \
            --certificates=$CERT_NAME \
            --hostname="*.$DOMAIN" \
            --project=$PROJECT_ID
        log_info "Certificate map entry for *.$DOMAIN created"
    else
        log_warn "Certificate map entry '$entry_name' already exists"
    fi

    # ESP.BR domain entry
    entry_name="${CERT_MAP_NAME}-entry-esp"
    if ! gcloud certificate-manager maps entries describe $entry_name \
        --map=$CERT_MAP_NAME \
        --project=$PROJECT_ID &>/dev/null; then
        gcloud certificate-manager maps entries create $entry_name \
            --map=$CERT_MAP_NAME \
            --certificates=$CERT_NAME \
            --hostname="guialmeidapersonal.esp.br" \
            --project=$PROJECT_ID
        log_info "Certificate map entry for guialmeidapersonal.esp.br created"
    else
        log_warn "Certificate map entry '$entry_name' already exists"
    fi

    # Wildcard entry for ESP.BR domain
    entry_name="${CERT_MAP_NAME}-entry-esp-wildcard"
    if ! gcloud certificate-manager maps entries describe $entry_name \
        --map=$CERT_MAP_NAME \
        --project=$PROJECT_ID &>/dev/null; then
        gcloud certificate-manager maps entries create $entry_name \
            --map=$CERT_MAP_NAME \
            --certificates=$CERT_NAME \
            --hostname="*.guialmeidapersonal.esp.br" \
            --project=$PROJECT_ID
        log_info "Certificate map entry for *.guialmeidapersonal.esp.br created"
    else
        log_warn "Certificate map entry '$entry_name' already exists"
    fi
}

# Create HTTPS target proxy
create_https_proxy() {
    log_step "Creating HTTPS target proxy..."

    if gcloud compute target-https-proxies describe $HTTPS_PROXY_NAME \
        --project=$PROJECT_ID &>/dev/null; then
        log_warn "HTTPS proxy '$HTTPS_PROXY_NAME' already exists"
    else
        if [ "$DRY_RUN" = "true" ]; then
            log_warn "DRY RUN: Would create HTTPS proxy: $HTTPS_PROXY_NAME"
        else
            gcloud compute target-https-proxies create $HTTPS_PROXY_NAME \
                --url-map=$URL_MAP_NAME \
                --certificate-map=$CERT_MAP_NAME \
                --project=$PROJECT_ID
            log_info "HTTPS proxy '$HTTPS_PROXY_NAME' created"
        fi
    fi
}

# Create HTTPS forwarding rule
create_https_forwarding_rule() {
    log_step "Creating HTTPS forwarding rule (port 443)..."

    if gcloud compute forwarding-rules describe $HTTPS_RULE_NAME \
        --global \
        --project=$PROJECT_ID &>/dev/null; then
        log_warn "HTTPS forwarding rule '$HTTPS_RULE_NAME' already exists"
    else
        if [ "$DRY_RUN" = "true" ]; then
            log_warn "DRY RUN: Would create HTTPS forwarding rule: $HTTPS_RULE_NAME"
        else
            gcloud compute forwarding-rules create $HTTPS_RULE_NAME \
                --global \
                --load-balancing-scheme=EXTERNAL_MANAGED \
                --target-https-proxy=$HTTPS_PROXY_NAME \
                --ports=443 \
                --address=$STATIC_IP_NAME \
                --project=$PROJECT_ID
            log_info "HTTPS forwarding rule '$HTTPS_RULE_NAME' created"
        fi
    fi
}

#============================================================================
# Summary and Status
#============================================================================

# Get certificate status
get_certificate_status() {
    if [ "$DRY_RUN" = "true" ]; then
        echo "  Status: DRY RUN (certificate would be created)"
        return
    fi

    local status
    status=$(gcloud certificate-manager certificates describe $CERT_NAME \
        --project=$PROJECT_ID \
        --format="value(managed.state)" 2>/dev/null) || status="UNKNOWN"

    echo "  Status: $status"

    if [ "$status" != "ACTIVE" ]; then
        log_warn "Certificate is not yet active. This is normal and can take 15-60 minutes."
        log_warn "Check status with: gcloud certificate-manager certificates describe $CERT_NAME --project=$PROJECT_ID"
    fi
}

# Print summary
print_summary() {
    echo ""
    log_info "========================================"
    log_info "Load Balancer Configuration Summary"
    log_info "========================================"
    echo ""

    # Get static IP
    if [ "$DRY_RUN" != "true" ]; then
        STATIC_IP=$(gcloud compute addresses describe $STATIC_IP_NAME \
            --global \
            --project=$PROJECT_ID \
            --format="value(address)" 2>/dev/null) || STATIC_IP="NOT_FOUND"
    else
        STATIC_IP="DRY_RUN"
    fi

    log_info "Static IP Address:"
    echo "  Name: $STATIC_IP_NAME"
    echo "  IP:   $STATIC_IP"
    echo ""

    log_info "Backend Buckets (with CDN):"
    echo "  - $BACKEND_SITE -> gs://$BUCKET_SITE (default)"
    echo "  - $BACKEND_ADMIN -> gs://$BUCKET_ADMIN"
    echo "  - $BACKEND_APP -> gs://$BUCKET_APP"
    echo ""

    log_info "API Backend:"
    echo "  - NEG: $NEG_NAME (Cloud Run: $CLOUD_RUN_SERVICE)"
    echo "  - Backend Service: $BACKEND_API"
    echo ""

    log_info "URL Map Routing ($URL_MAP_NAME):"
    echo "  - $DOMAIN, www.$DOMAIN -> $BACKEND_SITE"
    echo "  - api.$DOMAIN -> $BACKEND_API (Cloud Run)"
    echo "  - admin.$DOMAIN -> $BACKEND_ADMIN"
    echo "  - app.$DOMAIN -> $BACKEND_APP"
    echo "  - guialmeidapersonal.esp.br subdomains -> same routing"
    echo ""

    log_info "Proxies and Forwarding Rules:"
    echo "  HTTP:"
    echo "    - Proxy: $HTTP_PROXY_NAME"
    echo "    - Rule:  $HTTP_RULE_NAME (port 80)"
    echo "  HTTPS:"
    echo "    - Proxy: $HTTPS_PROXY_NAME"
    echo "    - Rule:  $HTTPS_RULE_NAME (port 443)"
    echo ""

    log_info "SSL Certificate ($CERT_NAME):"
    get_certificate_status
    echo "  Domains:"
    echo "    - $DOMAIN"
    echo "    - *.$DOMAIN"
    echo "    - guialmeidapersonal.esp.br"
    echo "    - *.guialmeidapersonal.esp.br"
    echo ""

    log_info "========================================"
    log_info "DNS Configuration Required"
    log_info "========================================"
    echo ""
    echo "Add the following DNS records to your domain registrar:"
    echo ""
    echo "  Type  Name                              Value"
    echo "  ----  --------------------------------  ----------------"
    echo "  A     @                                 $STATIC_IP"
    echo "  A     www                               $STATIC_IP"
    echo "  A     api                               $STATIC_IP"
    echo "  A     admin                             $STATIC_IP"
    echo "  A     app                               $STATIC_IP"
    echo ""
    echo "For guialmeidapersonal.esp.br domain:"
    echo "  A     @                                 $STATIC_IP"
    echo "  A     api                               $STATIC_IP"
    echo "  A     admin                             $STATIC_IP"
    echo "  A     app                               $STATIC_IP"
    echo ""

    log_info "========================================"
    log_info "Useful Commands"
    log_info "========================================"
    echo ""
    echo "  # Check certificate status"
    echo "  gcloud certificate-manager certificates describe $CERT_NAME --project=$PROJECT_ID"
    echo ""
    echo "  # List all backends"
    echo "  gcloud compute backend-buckets list --project=$PROJECT_ID"
    echo "  gcloud compute backend-services list --project=$PROJECT_ID"
    echo ""
    echo "  # View URL map configuration"
    echo "  gcloud compute url-maps describe $URL_MAP_NAME --project=$PROJECT_ID"
    echo ""
    echo "  # Check load balancer health"
    echo "  gcloud compute backend-services get-health $BACKEND_API --global --project=$PROJECT_ID"
    echo ""
    echo "  # View forwarding rules"
    echo "  gcloud compute forwarding-rules list --global --project=$PROJECT_ID"
    echo ""
}

# Main execution
main() {
    echo "========================================"
    echo "Tasks 12-14: Load Balancer Configuration"
    echo "========================================"
    echo ""

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "Running in DRY RUN mode - no changes will be made"
        echo ""
    fi

    check_prerequisites
    verify_infrastructure

    echo ""
    log_info "Starting load balancer configuration..."
    echo ""

    # Task 12: Static IP and Backend Services
    echo "========================================"
    echo "Task 12: Static IP and Backend Services"
    echo "========================================"
    echo ""
    create_static_ip
    create_backend_buckets
    create_health_check
    create_api_neg
    create_api_backend

    # Task 13: URL Map and HTTP Proxy
    echo ""
    echo "========================================"
    echo "Task 13: URL Map and HTTP Proxy"
    echo "========================================"
    echo ""
    create_url_map
    create_http_proxy
    create_http_forwarding_rule

    # Task 14: SSL Certificate and HTTPS
    echo ""
    echo "========================================"
    echo "Task 14: SSL Certificate and HTTPS"
    echo "========================================"
    echo ""
    create_ssl_certificate
    create_certificate_map
    create_certificate_map_entries
    create_https_proxy
    create_https_forwarding_rule

    # Print summary
    print_summary

    log_info "========================================"
    log_info "Load balancer configuration complete!"
    log_info "========================================"
    echo ""
    log_warn "IMPORTANT: SSL certificate provisioning may take 15-60 minutes."
    log_warn "           DNS records must be configured for certificate validation."
}

# Run main function
main "$@"
