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

echo "Granting database permissions to user..."

# Grant database-level permissions (requires postgres superuser)
echo "Attempting to grant database-level permissions..."
gcloud sql execute $INSTANCE_NAME \
  --user=postgres \
  --password="$DB_PASSWORD" \
  --project=$PROJECT_ID \
  --sql="GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" 2>/dev/null || {
    echo "Note: Database-level grant requires manual execution if above failed."
    echo "This is expected on fresh instances and can be done after first deployment."
}

# Grant schema and table permissions (can be executed with --database flag)
echo "Granting schema and table permissions..."
gcloud sql execute $INSTANCE_NAME \
  --database=$DB_NAME \
  --user=postgres \
  --password="$DB_PASSWORD" \
  --project=$PROJECT_ID \
  --sql="GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER; \
         GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER; \
         GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER; \
         ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $DB_USER; \
         ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO $DB_USER;" || {
  echo ""
  echo "================================================================"
  echo "WARNING: Automatic permission grants failed!"
  echo "================================================================"
  echo "You may need to run these SQL commands manually using Cloud SQL Proxy:"
  echo ""
  echo "1. Start Cloud SQL Proxy:"
  echo "   cloud-sql-proxy $PROJECT_ID:$REGION:$INSTANCE_NAME"
  echo ""
  echo "2. Connect with psql (in another terminal):"
  echo "   PGPASSWORD='<DB_PASSWORD>' psql -h 127.0.0.1 -U postgres -d $DB_NAME"
  echo ""
  echo "3. Run these commands:"
  echo "   GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
  echo "   GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER;"
  echo "   GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;"
  echo "   GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;"
  echo "   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $DB_USER;"
  echo "   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO $DB_USER;"
  echo "================================================================"
  echo ""
}

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
