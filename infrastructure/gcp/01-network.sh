#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
NETWORK="ga-personal-vpc"
SUBNET="ga-personal-subnet"

echo "Creating VPC network..."
gcloud compute networks create $NETWORK \
  --subnet-mode=custom \
  --bgp-routing-mode=regional \
  --project=$PROJECT_ID

echo "Creating subnet..."
gcloud compute networks subnets create $SUBNET \
  --network=$NETWORK \
  --region=$REGION \
  --range=10.0.0.0/20 \
  --enable-private-ip-google-access \
  --project=$PROJECT_ID

echo "Creating firewall rules..."
gcloud compute firewall-rules create ga-personal-allow-internal \
  --network=$NETWORK \
  --allow=tcp,udp,icmp \
  --source-ranges=10.0.0.0/20 \
  --project=$PROJECT_ID

echo "Network setup complete!"
