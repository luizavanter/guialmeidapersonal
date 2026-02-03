#!/bin/bash
set -e

PROJECT_ID="guialmeidapersonal"
REGION="southamerica-east1"
INSTANCE_NAME="ga-personal-db"
NETWORK="ga-personal-vpc"
DB_NAME="ga_personal_prod"
DB_USER="ga_personal_user"

# Check if IP range already exists
if gcloud compute addresses describe ga-personal-sql-range --global --project=$PROJECT_ID &>/dev/null; then
  echo "IP range 'ga-personal-sql-range' already exists, skipping creation..."
else
  echo "Allocating IP range for private service connection..."
  gcloud compute addresses create ga-personal-sql-range \
    --global \
    --purpose=VPC_PEERING \
    --prefix-length=16 \
    --network=$NETWORK \
    --project=$PROJECT_ID
fi

# Check if VPC peering already exists
if gcloud services vpc-peerings list --network=$NETWORK --project=$PROJECT_ID 2>/dev/null | grep -q "servicenetworking.googleapis.com"; then
  echo "VPC peering already exists, skipping connection..."
else
  echo "Creating private service connection..."
  gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --ranges=ga-personal-sql-range \
    --network=$NETWORK \
    --project=$PROJECT_ID
fi

# Generate or retrieve password
PASSWORD_FILE="/tmp/.ga-personal-db-password"
if [ -f "$PASSWORD_FILE" ]; then
  echo "Using existing database password from previous run..."
  DB_PASSWORD=$(cat "$PASSWORD_FILE")
else
  echo "Generating database password..."
  DB_PASSWORD=$(openssl rand -base64 32)
  echo "$DB_PASSWORD" > "$PASSWORD_FILE"
  chmod 600 "$PASSWORD_FILE"
fi

# Check if Cloud SQL instance already exists
if gcloud sql instances describe $INSTANCE_NAME --project=$PROJECT_ID &>/dev/null; then
  echo "Cloud SQL instance '$INSTANCE_NAME' already exists, skipping creation..."
else
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
fi

echo "Waiting for instance to be ready..."
while [ "$(gcloud sql instances describe $INSTANCE_NAME --project=$PROJECT_ID --format='value(state)')" != "RUNNABLE" ]; do
  echo "Waiting..."
  sleep 15
done

# Set postgres password (idempotent operation)
echo "Setting postgres user password..."
gcloud sql users set-password postgres \
  --instance=$INSTANCE_NAME \
  --password="$DB_PASSWORD" \
  --project=$PROJECT_ID

# Check if database already exists
if gcloud sql databases describe $DB_NAME --instance=$INSTANCE_NAME --project=$PROJECT_ID &>/dev/null; then
  echo "Database '$DB_NAME' already exists, skipping creation..."
else
  echo "Creating application database..."
  gcloud sql databases create $DB_NAME \
    --instance=$INSTANCE_NAME \
    --project=$PROJECT_ID
fi

# Check if user already exists
if gcloud sql users list --instance=$INSTANCE_NAME --project=$PROJECT_ID --format="value(name)" | grep -q "^$DB_USER$"; then
  echo "User '$DB_USER' already exists, updating password..."
  gcloud sql users set-password $DB_USER \
    --instance=$INSTANCE_NAME \
    --password="$DB_PASSWORD" \
    --project=$PROJECT_ID
else
  echo "Creating application user..."
  gcloud sql users create $DB_USER \
    --instance=$INSTANCE_NAME \
    --password="$DB_PASSWORD" \
    --project=$PROJECT_ID
fi

echo "Granting database permissions to user via Cloud Storage import..."

# Create temporary SQL file with grant statements
GRANTS_FILE="/tmp/ga-personal-grants-$$.sql"
cat > "$GRANTS_FILE" <<EOF
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
\c $DB_NAME
GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER;
GRANT ALL ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
EOF

# Create temporary GCS bucket for SQL import (if it doesn't exist)
TEMP_BUCKET="gs://guialmeidapersonal-temp-sql"
if ! gsutil ls -p $PROJECT_ID $TEMP_BUCKET &>/dev/null; then
  echo "Creating temporary Cloud Storage bucket for SQL import..."
  gsutil mb -p $PROJECT_ID -l $REGION $TEMP_BUCKET
fi

# Upload grants file to GCS
echo "Uploading grants file to Cloud Storage..."
gsutil cp "$GRANTS_FILE" "$TEMP_BUCKET/grants-$$.sql"

# Import SQL file (runs as postgres user, fully automated)
echo "Executing grants via Cloud SQL import..."
gcloud sql import sql $INSTANCE_NAME "$TEMP_BUCKET/grants-$$.sql" \
  --database=postgres \
  --user=postgres \
  --project=$PROJECT_ID || {
    echo ""
    echo "================================================================"
    echo "WARNING: Automatic permission grants failed!"
    echo "================================================================"
    echo "This may happen if the database is not fully ready."
    echo "You can retry the grants manually with:"
    echo ""
    echo "1. Upload the grants file:"
    echo "   gsutil cp <grants.sql> $TEMP_BUCKET/grants.sql"
    echo ""
    echo "2. Run the import:"
    echo "   gcloud sql import sql $INSTANCE_NAME $TEMP_BUCKET/grants.sql \\"
    echo "     --database=postgres --user=postgres --project=$PROJECT_ID"
    echo ""
    echo "Or connect via Cloud SQL Proxy and run manually:"
    echo "   GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
    echo "   \c $DB_NAME"
    echo "   GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER;"
    echo "   GRANT ALL ON ALL TABLES IN SCHEMA public TO $DB_USER;"
    echo "   GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;"
    echo "   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;"
    echo "   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;"
    echo "================================================================"
    echo ""
}

# Cleanup temporary files
echo "Cleaning up temporary files..."
rm -f "$GRANTS_FILE"
gsutil rm "$TEMP_BUCKET/grants-$$.sql" 2>/dev/null || true

echo "Getting connection details..."
CONNECTION_NAME=$(gcloud sql instances describe $INSTANCE_NAME --project=$PROJECT_ID --format="value(connectionName)")
PRIVATE_IP=$(gcloud sql instances describe $INSTANCE_NAME --project=$PROJECT_ID --format="value(ipAddresses[0].ipAddress)")

echo ""
echo "======================================"
echo "Cloud SQL setup complete!"
echo "======================================"
echo "Connection Name: $CONNECTION_NAME"
echo "Private IP: $PRIVATE_IP"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo ""
echo "!!! CRITICAL - SAVE THIS PASSWORD !!!"
echo "======================================"
echo "Database Password: $DB_PASSWORD"
echo "======================================"
echo ""
echo "IMPORTANT SECURITY INSTRUCTIONS:"
echo "1. Save this password to Secret Manager immediately"
echo "2. Delete the temp file after saving: rm $PASSWORD_FILE"
echo "3. NEVER commit this password to version control"
echo ""
echo "Database URL template (for Secret Manager):"
echo "postgresql://$DB_USER:<PASSWORD>@$PRIVATE_IP:5432/$DB_NAME"
echo ""
echo "To test connection immediately (replace <PASSWORD> with actual password):"
echo "PGPASSWORD='<PASSWORD>' psql -h $PRIVATE_IP -U $DB_USER -d $DB_NAME"
echo "======================================"
