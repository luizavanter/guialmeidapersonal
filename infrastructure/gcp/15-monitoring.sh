#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"

echo "Creating uptime checks for GA Personal..."

# Create uptime check for API
gcloud monitoring uptime-check-configs create api-health-check \
  --display-name="API Health Check" \
  --monitored-resource-type="uptime-url" \
  --host="api.guialmeidapersonal.esp.br" \
  --path="/api/v1/health" \
  --protocol="https" \
  --period=60 \
  --timeout=10s \
  --project=$PROJECT_ID || echo "API health check already exists"

# Create uptime check for Admin
gcloud monitoring uptime-check-configs create admin-uptime-check \
  --display-name="Admin Dashboard Uptime" \
  --monitored-resource-type="uptime-url" \
  --host="admin.guialmeidapersonal.esp.br" \
  --path="/" \
  --protocol="https" \
  --period=300 \
  --timeout=10s \
  --project=$PROJECT_ID || echo "Admin uptime check already exists"

# Create uptime check for App
gcloud monitoring uptime-check-configs create app-uptime-check \
  --display-name="Student App Uptime" \
  --monitored-resource-type="uptime-url" \
  --host="app.guialmeidapersonal.esp.br" \
  --path="/" \
  --protocol="https" \
  --period=300 \
  --timeout=10s \
  --project=$PROJECT_ID || echo "App uptime check already exists"

# Create uptime check for Site
gcloud monitoring uptime-check-configs create site-uptime-check \
  --display-name="Marketing Site Uptime" \
  --monitored-resource-type="uptime-url" \
  --host="guialmeidapersonal.esp.br" \
  --path="/" \
  --protocol="https" \
  --period=300 \
  --timeout=10s \
  --project=$PROJECT_ID || echo "Site uptime check already exists"

echo ""
echo "Monitoring setup complete!"
echo "View in console: https://console.cloud.google.com/monitoring/uptime?project=$PROJECT_ID"
