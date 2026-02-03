#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
INSTANCE_NAME="ga-personal-redis"
NETWORK="ga-personal-vpc"

echo "======================================"
echo "Memorystore Redis Setup"
echo "======================================"
echo ""

# Check if Redis instance already exists
if gcloud redis instances describe $INSTANCE_NAME --region=$REGION --project=$PROJECT_ID &>/dev/null; then
  echo "Redis instance '$INSTANCE_NAME' already exists, skipping creation..."
else
  echo "Creating Memorystore Redis instance (takes 3-5 minutes)..."
  echo "This may occasionally fail due to zonal resource availability."
  echo "If it fails, wait a few minutes and retry."
  echo ""

  gcloud redis instances create $INSTANCE_NAME \
    --size=1 \
    --region=$REGION \
    --network=projects/$PROJECT_ID/global/networks/$NETWORK \
    --redis-version=redis_7_0 \
    --tier=basic \
    --project=$PROJECT_ID || {
      echo ""
      echo "================================================================"
      echo "ERROR: Redis instance creation failed!"
      echo "================================================================"
      echo "This is often due to temporary GCP resource availability issues."
      echo ""
      echo "Solutions:"
      echo "1. Wait 2-3 minutes and run this script again"
      echo "2. Try a different Redis version: --redis-version=redis_6_x"
      echo "3. Check GCP status: https://status.cloud.google.com/"
      echo "================================================================"
      exit 1
    }
fi

echo "Waiting for Redis instance to be ready..."
MAX_WAIT=600  # 10 minutes max
WAITED=0
INTERVAL=10

while [ "$(gcloud redis instances describe $INSTANCE_NAME --region=$REGION --project=$PROJECT_ID --format='value(state)')" != "READY" ]; do
  if [ $WAITED -ge $MAX_WAIT ]; then
    echo ""
    echo "ERROR: Timeout waiting for Redis to be ready after ${MAX_WAIT}s"
    exit 1
  fi
  echo "Waiting for Redis to be ready... (${WAITED}s elapsed)"
  sleep $INTERVAL
  WAITED=$((WAITED + INTERVAL))
done

echo "Redis instance is READY!"
echo ""

# Get connection details
echo "Getting connection details..."
REDIS_HOST=$(gcloud redis instances describe $INSTANCE_NAME --region=$REGION --project=$PROJECT_ID --format="value(host)")
REDIS_PORT=$(gcloud redis instances describe $INSTANCE_NAME --region=$REGION --project=$PROJECT_ID --format="value(port)")
REDIS_VERSION=$(gcloud redis instances describe $INSTANCE_NAME --region=$REGION --project=$PROJECT_ID --format="value(redisVersion)")
REDIS_TIER=$(gcloud redis instances describe $INSTANCE_NAME --region=$REGION --project=$PROJECT_ID --format="value(tier)")
REDIS_SIZE=$(gcloud redis instances describe $INSTANCE_NAME --region=$REGION --project=$PROJECT_ID --format="value(memorySizeGb)")

echo ""
echo "======================================"
echo "Memorystore Redis setup complete!"
echo "======================================"
echo ""
echo "Instance Name: $INSTANCE_NAME"
echo "Redis Version: $REDIS_VERSION"
echo "Tier: $REDIS_TIER"
echo "Memory Size: ${REDIS_SIZE}GB"
echo ""
echo "Connection Details:"
echo "  Host (Private IP): $REDIS_HOST"
echo "  Port: $REDIS_PORT"
echo ""
echo "Redis URL: redis://$REDIS_HOST:$REDIS_PORT/0"
echo ""
echo "======================================"
echo ""
echo "IMPORTANT NOTES:"
echo "1. Redis is only accessible from within the VPC"
echo "2. Cloud Run services must use the VPC connector to connect"
echo "3. No authentication is configured (basic tier)"
echo "4. For production, consider upgrading to standard tier for HA"
echo ""
echo "To use in Phoenix application, set these environment variables:"
echo "  REDIS_HOST=$REDIS_HOST"
echo "  REDIS_PORT=$REDIS_PORT"
echo "  REDIS_URL=redis://$REDIS_HOST:$REDIS_PORT/0"
echo "======================================"
