#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
CONNECTOR_NAME="ga-personal-vpc-connector"
NETWORK="ga-personal-vpc"

echo "Creating VPC connector for Cloud Run..."
gcloud compute networks vpc-access connectors create $CONNECTOR_NAME \
  --region=$REGION \
  --network=$NETWORK \
  --range=10.8.0.0/28 \
  --min-throughput=200 \
  --max-throughput=300 \
  --project=$PROJECT_ID

echo "Waiting for connector to be ready..."
while [ "$(gcloud compute networks vpc-access connectors describe $CONNECTOR_NAME --region=$REGION --project=$PROJECT_ID --format='value(state)')" != "READY" ]; do
  echo "Waiting..."
  sleep 10
done

echo "VPC connector ready!"
