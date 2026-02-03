#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
INSTANCE_NAME="ga-personal-db"
NETWORK="ga-personal-vpc"
DB_NAME="ga_personal_prod"
DB_USER="ga_personal_user"

echo "Allocating IP range for private service connection..."
gcloud compute addresses create ga-personal-sql-range \
  --global \
  --purpose=VPC_PEERING \
  --prefix-length=16 \
  --network=$NETWORK \
  --project=$PROJECT_ID

echo "Creating private service connection..."
gcloud services vpc-peerings connect \
  --service=servicenetworking.googleapis.com \
  --ranges=ga-personal-sql-range \
  --network=$NETWORK \
  --project=$PROJECT_ID

echo "Generating database password..."
DB_PASSWORD=$(openssl rand -base64 32)
echo "Database password: $DB_PASSWORD"
echo "IMPORTANT: Save this password - you'll need it for Secret Manager"

echo "Creating Cloud SQL instance (this takes 5-10 minutes)..."
gcloud sql instances create $INSTANCE_NAME \
  --database-version=POSTGRES_16 \
  --tier=db-perf-optimized-N-2 \
  --region=$REGION \
  --network=projects/$PROJECT_ID/global/networks/$NETWORK \
  --no-assign-ip \
  --backup-start-time=03:00 \
  --maintenance-window-day=SUN \
  --maintenance-window-hour=3 \
  --storage-auto-increase \
  --storage-size=10GB \
  --project=$PROJECT_ID

echo "Waiting for instance to be ready..."
while [ "$(gcloud sql instances describe $INSTANCE_NAME --project=$PROJECT_ID --format='value(state)')" != "RUNNABLE" ]; do
  echo "Waiting..."
  sleep 15
done

echo "Setting database password..."
gcloud sql users set-password postgres \
  --instance=$INSTANCE_NAME \
  --password="$DB_PASSWORD" \
  --project=$PROJECT_ID

echo "Creating application database and user..."
gcloud sql databases create $DB_NAME \
  --instance=$INSTANCE_NAME \
  --project=$PROJECT_ID

gcloud sql users create $DB_USER \
  --instance=$INSTANCE_NAME \
  --password="$DB_PASSWORD" \
  --project=$PROJECT_ID

echo "Getting connection details..."
CONNECTION_NAME=$(gcloud sql instances describe $INSTANCE_NAME --project=$PROJECT_ID --format="value(connectionName)")
PRIVATE_IP=$(gcloud sql instances describe $INSTANCE_NAME --project=$PROJECT_ID --format="value(ipAddresses[0].ipAddress)")

echo ""
echo "Cloud SQL setup complete!"
echo "Connection Name: $CONNECTION_NAME"
echo "Private IP: $PRIVATE_IP"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "Password: $DB_PASSWORD"
echo ""
echo "Database URL: postgresql://$DB_USER:$DB_PASSWORD@$PRIVATE_IP:5432/$DB_NAME"
