# Cal.com Self-Hosted Setup Guide

This document describes how to deploy and configure Cal.com self-hosted for the GA Personal project on Google Cloud Platform.

## Overview

Cal.com is an open-source scheduling platform that integrates with GA Personal to handle appointment booking for personal training sessions. Students can book sessions through Cal.com, and appointments are automatically synced to the GA Personal system via webhooks.

## Architecture

```
                                    +-------------------+
                                    |    Cal.com        |
    Student books                   |   Cloud Run       |
    appointment     +------------>  |   (ga-calcom)     |
                                    +--------+----------+
                                             |
                                             | Webhook
                                             v
    +-------------------+           +-------------------+
    |   GA Personal     |<----------|   Phoenix API     |
    |   Database        |           |   Cloud Run       |
    |   (PostgreSQL)    |           |   (ga-personal)   |
    +-------------------+           +-------------------+
```

## Prerequisites

Before deploying Cal.com, ensure the following infrastructure is in place:

1. **VPC Network** - `ga-personal-vpc`
2. **VPC Connector** - `ga-personal-vpc-connector`
3. **Cloud SQL PostgreSQL** - `ga-personal-db`
4. **Service Account** - `backend-sa@guialmeidapersonal.iam.gserviceaccount.com`
5. **GA Personal API deployed** - `ga-personal-api`

## Deployment

### 1. Deploy Cal.com to Cloud Run

Run the deployment script:

```bash
cd infrastructure/gcp/calcom
./deploy-calcom.sh
```

For a dry run (preview without changes):

```bash
DRY_RUN=true ./deploy-calcom.sh
```

To deploy a specific version:

```bash
CALCOM_VERSION=v4.7.1 ./deploy-calcom.sh
```

### 2. Configure DNS

Add a DNS record for Cal.com:

| Type  | Name | Value               |
|-------|------|---------------------|
| CNAME | cal  | ghs.googlehosted.com |

Full domain: `cal.guialmeidapersonal.esp.br`

Alternatively, add to Cloud DNS:

```bash
gcloud dns record-sets create cal.guialmeidapersonal.esp.br \
  --zone=guialmeidapersonal \
  --type=CNAME \
  --ttl=300 \
  --rrdatas="ghs.googlehosted.com." \
  --project=guialmeidapersonal
```

### 3. Configure Load Balancer (Optional)

If using the Global HTTPS Load Balancer for all services, add Cal.com as a backend:

1. Create a backend service for ga-calcom Cloud Run
2. Add URL map rule for `cal.guialmeidapersonal.esp.br`
3. Update SSL certificate to include the cal subdomain

### 4. First-time Setup in Cal.com

1. Navigate to `https://cal.guialmeidapersonal.esp.br`
2. Create the admin account (this will be Guilherme's account)
3. Complete the onboarding wizard:
   - Set timezone (America/Sao_Paulo)
   - Configure availability
   - Create event types (see below)

## Event Types Configuration

Create the following event types in Cal.com:

### Personal Training Session

| Field | Value |
|-------|-------|
| Title | Personal Training Session |
| Duration | 60 minutes |
| Location | Gym/Custom |
| Description | One-on-one personal training session |

### Physical Assessment

| Field | Value |
|-------|-------|
| Title | Physical Assessment |
| Duration | 90 minutes |
| Location | Gym |
| Description | Initial or periodic physical assessment and body composition analysis |

### Trial Session

| Field | Value |
|-------|-------|
| Title | Trial Session |
| Duration | 45 minutes |
| Location | Gym |
| Description | Free trial session for new clients |

## Webhook Integration

### 1. Get the Webhook Secret

```bash
gcloud secrets versions access latest \
  --secret=calcom-webhook-secret \
  --project=guialmeidapersonal
```

### 2. Configure Webhook in Cal.com

1. Go to **Settings > Developer > Webhooks**
2. Click **New Webhook**
3. Configure:

| Field | Value |
|-------|-------|
| Subscriber URL | `https://api.guialmeidapersonal.esp.br/api/v1/webhooks/calcom` |
| Event Triggers | BOOKING_CREATED, BOOKING_CANCELLED, BOOKING_RESCHEDULED |
| Secret | (paste the secret from step 1) |
| Active | Yes |

### 3. Test the Webhook

Create a test booking and verify:

1. Check Cloud Run logs for GA Personal API:
   ```bash
   gcloud run services logs read ga-personal-api \
     --region=southamerica-east1 \
     --project=guialmeidapersonal \
     --limit=20
   ```

2. Verify appointment was created in the database

## User Mapping

Cal.com integrates with GA Personal by mapping users through email addresses. For this to work:

### Trainer (Guilherme)

The Cal.com admin account email must match the trainer's email in GA Personal:
- Email: `guilherme@gapersonal.com`

### Students

Students booking through Cal.com must have their email registered in GA Personal. The webhook will:

1. Look up the trainer by organizer email
2. Look up the student by attendee email
3. Create the appointment linking both

### Custom Metadata

For more reliable user mapping, Cal.com bookings can include custom metadata:

```json
{
  "metadata": {
    "trainer_id": "uuid-of-trainer",
    "student_id": "uuid-of-student"
  }
}
```

This can be configured in Cal.com using custom booking fields.

## Webhook Payload Structure

### BOOKING_CREATED

```json
{
  "triggerEvent": "BOOKING_CREATED",
  "createdAt": "2026-02-04T10:00:00.000Z",
  "payload": {
    "uid": "unique-booking-id",
    "startTime": "2026-02-05T10:00:00.000Z",
    "endTime": "2026-02-05T11:00:00.000Z",
    "title": "Personal Training Session",
    "description": "Session notes from booking",
    "location": "Gym Address",
    "organizer": {
      "email": "guilherme@gapersonal.com",
      "name": "Guilherme Almeida"
    },
    "attendees": [
      {
        "email": "student@example.com",
        "name": "Student Name",
        "notes": "Any notes from the student"
      }
    ],
    "eventType": {
      "title": "Personal Training Session",
      "length": 60
    },
    "metadata": {}
  }
}
```

### BOOKING_CANCELLED

```json
{
  "triggerEvent": "BOOKING_CANCELLED",
  "createdAt": "2026-02-04T12:00:00.000Z",
  "payload": {
    "uid": "unique-booking-id",
    "cancellationReason": "Reason provided by user"
  }
}
```

### BOOKING_RESCHEDULED

```json
{
  "triggerEvent": "BOOKING_RESCHEDULED",
  "createdAt": "2026-02-04T14:00:00.000Z",
  "payload": {
    "uid": "unique-booking-id",
    "startTime": "2026-02-06T14:00:00.000Z",
    "endTime": "2026-02-06T15:00:00.000Z",
    "rescheduleReason": "Reason provided by user"
  }
}
```

## Appointment Status Mapping

| Cal.com Event | GA Personal Status |
|---------------|-------------------|
| BOOKING_CREATED | `scheduled` |
| BOOKING_CANCELLED | `cancelled` |
| BOOKING_RESCHEDULED | `scheduled` (updated time) |

## Secrets Reference

| Secret Name | Description |
|-------------|-------------|
| `calcom-database-url` | PostgreSQL connection string for Cal.com |
| `calcom-nextauth-secret` | NextAuth.js session secret |
| `calcom-encryption-key` | Cal.com encryption key |
| `calcom-webhook-secret` | Shared secret for webhook signature verification |

### Accessing Secrets

```bash
# View a secret
gcloud secrets versions access latest --secret=<secret-name> --project=guialmeidapersonal

# List all secrets
gcloud secrets list --project=guialmeidapersonal

# Update a secret
echo -n "new-value" | gcloud secrets versions add <secret-name> --data-file=- --project=guialmeidapersonal
```

## Monitoring

### View Cal.com Logs

```bash
gcloud run services logs read ga-calcom \
  --region=southamerica-east1 \
  --project=guialmeidapersonal \
  --limit=50
```

### Service Status

```bash
gcloud run services describe ga-calcom \
  --region=southamerica-east1 \
  --project=guialmeidapersonal
```

### Webhook Debugging

If webhooks are not working:

1. Check Cal.com webhook configuration is active
2. Verify the webhook secret matches
3. Check GA Personal API logs for errors
4. Test with curl:

```bash
# Get webhook secret
SECRET=$(gcloud secrets versions access latest --secret=calcom-webhook-secret --project=guialmeidapersonal)

# Create test payload
PAYLOAD='{"triggerEvent":"BOOKING_CREATED","payload":{"uid":"test-123"}}'

# Calculate signature
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | cut -d' ' -f2)

# Send test request
curl -X POST https://api.guialmeidapersonal.esp.br/api/v1/webhooks/calcom \
  -H "Content-Type: application/json" \
  -H "X-Cal-Signature-256: sha256=$SIGNATURE" \
  -d "$PAYLOAD"
```

## Troubleshooting

### Database Connection Issues

If Cal.com cannot connect to the database:

1. Verify VPC connector is running
2. Check Cloud SQL instance is running
3. Verify calcom-database-url secret is correct
4. Check Cloud SQL user permissions

### Webhook Signature Failures

If webhooks return 401 Unauthorized:

1. Verify webhook secret in Cal.com matches Secret Manager
2. Check raw body is being captured (endpoint.ex configuration)
3. Ensure signature header is being sent correctly

### Booking Not Created in GA Personal

If appointments are not appearing:

1. Check user emails match between Cal.com and GA Personal
2. Verify trainer account exists in GA Personal
3. Check student account exists in GA Personal
4. Review GA Personal API logs for errors

## Scaling

Cal.com is configured with:

- **Min instances:** 0 (scale to zero)
- **Max instances:** 4
- **CPU:** 2 vCPU
- **Memory:** 2Gi

To adjust scaling:

```bash
gcloud run services update ga-calcom \
  --min-instances=1 \
  --max-instances=10 \
  --region=southamerica-east1 \
  --project=guialmeidapersonal
```

## Cost Optimization

1. **Scale to zero** - Cal.com will scale down when not in use
2. **Shared database** - Uses the same Cloud SQL instance as GA Personal
3. **Regional deployment** - Deploy in the same region for lower latency

Estimated monthly cost:
- Cloud Run: ~$0-30 (depends on usage)
- Cloud SQL: Shared with GA Personal (no additional cost)
- Secrets: Negligible

## Security Considerations

1. **HTTPS only** - All traffic is encrypted
2. **Webhook signatures** - All webhooks are verified
3. **Private networking** - Database accessible only via VPC
4. **Secret management** - All secrets stored in Secret Manager
5. **Authentication** - Cal.com handles its own user authentication

## Future Improvements

1. **Google Calendar sync** - Automatic sync with trainer's Google Calendar
2. **Email notifications** - Booking confirmations via email
3. **SMS reminders** - Integration with Twilio for SMS
4. **Payment integration** - Collect payment at booking time
5. **Custom booking pages** - Embed on guialmeidapersonal.esp.br

## References

- [Cal.com Documentation](https://cal.com/docs)
- [Cal.com Self-Hosting Guide](https://cal.com/docs/introduction/quick-start/self-hosting)
- [Cal.com Webhooks](https://cal.com/docs/core-features/webhooks)
- [Google Cloud Run](https://cloud.google.com/run/docs)
