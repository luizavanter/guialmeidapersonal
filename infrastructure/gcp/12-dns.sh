#!/bin/bash
#
# Task 15: Configure Cloud DNS Records
# Project: guialmeidapersonal
# Domain: guialmeidapersonal.esp.br
#
# This script creates:
# - Cloud DNS managed zone (if not exists)
# - A records for @, www, api, admin, app subdomains
# - All records point to the load balancer static IP
#
# It is idempotent - safe to run multiple times.
#
# Prerequisites:
# - gcloud CLI authenticated with appropriate permissions
# - Cloud DNS API enabled
# - Static IP created (from 11-load-balancer.sh)
#
# Usage:
#   ./12-dns.sh
#
# Environment Variables:
#   DRY_RUN=true   # Show what would be created without creating
#

set -e

# Configuration
PROJECT_ID="guialmeidapersonal"
DOMAIN="guialmeidapersonal.esp.br"
DNS_ZONE_NAME="guialmeidapersonal-zone"
STATIC_IP_NAME="ga-personal-ip"
TTL=300

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

    # Enable Cloud DNS API
    if ! gcloud services list --project=$PROJECT_ID --enabled --filter="name:dns.googleapis.com" --format="value(name)" | grep -q "dns.googleapis.com"; then
        log_warn "Enabling Cloud DNS API..."
        gcloud services enable dns.googleapis.com --project=$PROJECT_ID
    fi

    log_info "Prerequisites check passed"
}

# Get load balancer IP address
get_load_balancer_ip() {
    log_step "Getting load balancer IP address..."

    if ! gcloud compute addresses describe $STATIC_IP_NAME \
        --global \
        --project=$PROJECT_ID &>/dev/null; then
        log_error "Static IP '$STATIC_IP_NAME' not found"
        log_error "Please run 11-load-balancer.sh first"
        exit 1
    fi

    LB_IP=$(gcloud compute addresses describe $STATIC_IP_NAME \
        --global \
        --project=$PROJECT_ID \
        --format="value(address)")

    log_info "Load balancer IP: $LB_IP"
}

# Create DNS managed zone
create_dns_zone() {
    log_step "Creating DNS managed zone..."

    if gcloud dns managed-zones describe $DNS_ZONE_NAME \
        --project=$PROJECT_ID &>/dev/null; then
        log_warn "DNS zone '$DNS_ZONE_NAME' already exists"
    else
        if [ "$DRY_RUN" = "true" ]; then
            log_warn "DRY RUN: Would create DNS zone: $DNS_ZONE_NAME"
        else
            gcloud dns managed-zones create $DNS_ZONE_NAME \
                --dns-name="${DOMAIN}." \
                --description="DNS zone for GA Personal Trainer" \
                --project=$PROJECT_ID
            log_info "DNS zone '$DNS_ZONE_NAME' created"
        fi
    fi
}

# Create or update an A record
create_a_record() {
    local name=$1
    local ip=$2
    local full_name

    if [ "$name" = "@" ]; then
        full_name="${DOMAIN}."
    else
        full_name="${name}.${DOMAIN}."
    fi

    log_info "Creating A record: $full_name -> $ip (TTL: ${TTL}s)"

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "DRY RUN: Would create A record: $full_name -> $ip"
        return
    fi

    # Check if record exists
    local existing_record
    existing_record=$(gcloud dns record-sets list \
        --zone=$DNS_ZONE_NAME \
        --name="$full_name" \
        --type=A \
        --project=$PROJECT_ID \
        --format="value(rrdatas)" 2>/dev/null) || existing_record=""

    if [ -n "$existing_record" ]; then
        # Record exists, check if IP matches
        if [ "$existing_record" = "$ip" ]; then
            log_warn "A record '$full_name' already exists with correct IP"
            return
        else
            # Delete existing record
            log_info "Updating existing A record '$full_name' (old IP: $existing_record)"
            gcloud dns record-sets delete "$full_name" \
                --zone=$DNS_ZONE_NAME \
                --type=A \
                --project=$PROJECT_ID
        fi
    fi

    # Create the A record
    gcloud dns record-sets create "$full_name" \
        --zone=$DNS_ZONE_NAME \
        --type=A \
        --ttl=$TTL \
        --rrdatas="$ip" \
        --project=$PROJECT_ID

    log_info "A record '$full_name' created successfully"
}

# Create all DNS records
create_dns_records() {
    log_step "Creating DNS records..."

    # Create A records for all subdomains
    create_a_record "@" "$LB_IP"      # Root domain
    create_a_record "www" "$LB_IP"    # www subdomain
    create_a_record "api" "$LB_IP"    # api subdomain
    create_a_record "admin" "$LB_IP"  # admin subdomain
    create_a_record "app" "$LB_IP"    # app subdomain

    log_info "All DNS records configured"
}

# Show name servers for domain registrar configuration
show_name_servers() {
    log_step "Getting name servers..."

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "DRY RUN: Would show name servers"
        return
    fi

    echo ""
    log_info "========================================"
    log_info "Name Servers Configuration"
    log_info "========================================"
    echo ""
    echo "Configure the following name servers at your domain registrar:"
    echo ""

    gcloud dns managed-zones describe $DNS_ZONE_NAME \
        --project=$PROJECT_ID \
        --format="table[box,no-heading](nameServers)"

    echo ""
    log_warn "IMPORTANT: DNS propagation can take up to 48 hours"
    log_warn "           SSL certificate will provision after DNS propagates"
}

# Print summary
print_summary() {
    echo ""
    log_info "========================================"
    log_info "DNS Configuration Summary"
    log_info "========================================"
    echo ""

    log_info "DNS Zone: $DNS_ZONE_NAME"
    echo "  Domain: $DOMAIN"
    echo ""

    log_info "DNS Records:"
    echo "  Type  Name                              Value           TTL"
    echo "  ----  --------------------------------  --------------  ----"
    echo "  A     ${DOMAIN}.                        $LB_IP          $TTL"
    echo "  A     www.${DOMAIN}.                    $LB_IP          $TTL"
    echo "  A     api.${DOMAIN}.                    $LB_IP          $TTL"
    echo "  A     admin.${DOMAIN}.                  $LB_IP          $TTL"
    echo "  A     app.${DOMAIN}.                    $LB_IP          $TTL"
    echo ""

    if [ "$DRY_RUN" != "true" ]; then
        log_info "Current DNS Records:"
        gcloud dns record-sets list \
            --zone=$DNS_ZONE_NAME \
            --project=$PROJECT_ID \
            --format="table(name, type, ttl, rrdatas)"
    fi

    echo ""
    log_info "========================================"
    log_info "Useful Commands"
    log_info "========================================"
    echo ""
    echo "  # List all DNS records"
    echo "  gcloud dns record-sets list --zone=$DNS_ZONE_NAME --project=$PROJECT_ID"
    echo ""
    echo "  # Check DNS propagation"
    echo "  dig @8.8.8.8 $DOMAIN A"
    echo "  dig @8.8.8.8 api.$DOMAIN A"
    echo ""
    echo "  # Test endpoints (after DNS propagates)"
    echo "  curl -I https://$DOMAIN"
    echo "  curl -I https://api.$DOMAIN/api/health"
    echo ""
}

# Main execution
main() {
    echo "========================================"
    echo "Task 15: Configure Cloud DNS Records"
    echo "========================================"
    echo ""

    if [ "$DRY_RUN" = "true" ]; then
        log_warn "Running in DRY RUN mode - no changes will be made"
        echo ""
    fi

    check_prerequisites
    get_load_balancer_ip
    create_dns_zone
    create_dns_records
    show_name_servers
    print_summary

    log_info "========================================"
    log_info "DNS configuration complete!"
    log_info "========================================"
    echo ""
    log_warn "NEXT STEPS:"
    log_warn "1. Update name servers at your domain registrar"
    log_warn "2. Wait for DNS propagation (up to 48 hours)"
    log_warn "3. SSL certificate will auto-provision once DNS is active"
}

# Run main function
main "$@"
