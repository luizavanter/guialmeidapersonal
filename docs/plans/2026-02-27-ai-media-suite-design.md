# AI Media Suite — Design Document

**Date:** 2026-02-27
**Status:** Approved
**Approach:** Monolithic Phased (4 phases within existing Phoenix umbrella)

---

## Understanding Summary

- **What:** Comprehensive AI-powered media management system for health/fitness tracking
- **Why:** Core differentiator — AI-driven body analysis, medical document processing, and pose detection
- **Who:** Personal trainer Guilherme (30-100 active students) and his students
- **Key Constraints:** 100% GCP cloud infrastructure, LGPD compliance mandatory, privacy-first design
- **Non-Goals:** Real-time video streaming, social media features, third-party app marketplace

## Assumptions

1. GCS `ga-personal-media` bucket already exists and is configured
2. Claude API (Anthropic) will be available in production with Sonnet and Haiku models
3. TensorFlow.js MoveNet models can run client-side in modern browsers (Chrome, Safari, Firefox)
4. Students consent to data collection at registration (LGPD opt-in)
5. Anovator and Relaxmedic reports are uploaded as PDF or photo (no direct API integration)
6. Budget allows Claude API usage at ~R$50-200/month for 30-100 students
7. Medical documents are stored encrypted and access-logged per LGPD
8. Trainer always reviews AI analysis before it becomes visible to students

## Decision Log

| # | Decision | Alternatives Considered | Rationale |
|---|----------|------------------------|-----------|
| 1 | Monolithic phased (single Phoenix app) | Microservices, BFF pattern | Simpler ops, team of 1, existing umbrella structure |
| 2 | GCS signed URLs for direct upload | Server-side proxy upload | Reduces backend load, scales better, GCS already configured |
| 3 | Claude API for all AI analysis | OpenAI, local models, Google Vision | Best multimodal quality, consistent API, company preference |
| 4 | Haiku for OCR/extraction, Sonnet for complex analysis | Single model for all | Cost optimization — Haiku is 10x cheaper for simple tasks |
| 5 | TensorFlow.js client-side for pose detection | Server-side pose detection | Zero latency for real-time, no GPU server costs, privacy (video stays on device) |
| 6 | MoveNet Lightning for real-time, Thunder for static | Single model | Lightning: 30fps real-time guidance. Thunder: higher accuracy for posture analysis |
| 7 | Mandatory trainer review for AI results | Auto-publish to students | Safety — AI analysis should be validated by professional before student sees it |
| 8 | Full LGPD compliance (consent + audit + retention + deletion) | Basic access control only | Legal requirement in Brazil, trust building with students |
| 9 | Oban workers for async AI processing | Synchronous processing, GenServer | Resilient, retryable, observable, already in the stack |
| 10 | All bioimpedance devices via OCR upload (no direct API) | Device-specific integrations | Simpler, works for all devices, avoids vendor lock-in |

---

## Phase A: Media Upload Infrastructure

### Scope
Direct browser-to-GCS upload with signed URLs, new database schemas, LGPD compliance layer.

### New Database Tables

#### `media_files`
Core table for all uploaded files (photos, documents, reports).

```elixir
schema "media_files" do
  field :file_type, :string          # "evolution_photo", "medical_document", "bioimpedance_report"
  field :gcs_path, :string           # Full GCS object path
  field :original_filename, :string
  field :content_type, :string       # MIME type
  field :file_size_bytes, :integer
  field :metadata, :map, default: %{}  # Flexible metadata (dimensions, page count, etc.)
  field :encrypted, :boolean, default: true
  field :deleted_at, :utc_datetime   # Soft delete for LGPD

  belongs_to :student, GaPersonal.Accounts.StudentProfile
  belongs_to :uploaded_by, GaPersonal.Accounts.User  # Trainer or student
  belongs_to :trainer, GaPersonal.Accounts.User

  timestamps()
end
```

#### `consent_records`
LGPD consent tracking.

```elixir
schema "consent_records" do
  field :consent_type, :string       # "media_upload", "ai_analysis", "data_retention"
  field :granted, :boolean
  field :granted_at, :utc_datetime
  field :revoked_at, :utc_datetime
  field :ip_address, :string
  field :user_agent, :string

  belongs_to :user, GaPersonal.Accounts.User

  timestamps()
end
```

#### `access_logs`
Audit trail for sensitive data access.

```elixir
schema "access_logs" do
  field :action, :string             # "view", "download", "delete", "ai_analyze"
  field :resource_type, :string      # "media_file", "medical_document"
  field :resource_id, :integer
  field :ip_address, :string
  field :user_agent, :string
  field :metadata, :map, default: %{}

  belongs_to :user, GaPersonal.Accounts.User

  timestamps()
end
```

### New Context: `GaPersonal.Media`

Functions:
- `generate_upload_url/3` — Creates GCS signed URL for direct browser upload
- `generate_download_url/2` — Creates time-limited signed URL for viewing
- `register_upload/2` — Records completed upload in `media_files` table
- `list_files/2` — Lists files by student/type with pagination
- `soft_delete/2` — LGPD-compliant soft delete
- `hard_delete_expired/0` — Cron job to permanently delete files past retention period

### New Context: `GaPersonal.Privacy`

Functions:
- `record_consent/3` — Records user consent with timestamp and IP
- `revoke_consent/2` — Revokes consent and triggers data cleanup
- `check_consent/2` — Verifies active consent before operations
- `log_access/4` — Records access to sensitive data
- `export_user_data/1` — LGPD right of access (data portability)
- `delete_user_data/1` — LGPD right to be forgotten
- `get_audit_trail/2` — View access history for a user's data

### API Endpoints

```
POST   /api/v1/media/upload-url      # Get signed upload URL
POST   /api/v1/media/confirm-upload  # Confirm upload completed
GET    /api/v1/media/:id/download    # Get signed download URL
GET    /api/v1/students/:id/media    # List student's files
DELETE /api/v1/media/:id             # Soft delete file

POST   /api/v1/privacy/consent       # Record consent
DELETE /api/v1/privacy/consent/:type  # Revoke consent
GET    /api/v1/privacy/my-data       # Export my data (LGPD)
DELETE /api/v1/privacy/my-data       # Delete my data (LGPD)
```

### Upload Flow

```
Browser → POST /media/upload-url (get signed URL + file_id)
Browser → PUT directly to GCS signed URL (file bytes)
Browser → POST /media/confirm-upload (file_id, metadata)
Backend → Validates file exists in GCS, updates media_files record
```

### LGPD Compliance

1. **Consent at Registration:** Students must accept terms including media/AI consent
2. **Granular Consent:** Separate consent for upload, AI analysis, data retention
3. **Access Logging:** Every view/download/analysis of sensitive data is logged
4. **Right to Access:** Student can export all their data as JSON/ZIP
5. **Right to Deletion:** Student can request deletion; 30-day grace period then hard delete
6. **Data Retention:** Medical documents auto-expire after 5 years unless renewed
7. **Signed URLs:** All file access via time-limited signed URLs (15 min default)

---

## Phase B: Bioimpedance Import

### Scope
Upload bioimpedance reports (PDF/photo) from any device, extract data via Claude API OCR, populate BodyAssessment after trainer review.

### Supported Devices
- **Anovator** — Professional tower, generates detailed PDF reports
- **Relaxmedic Intelligence Plus** — Consumer Bluetooth scale, app exports PDF/screenshot
- **InBody / Tanita / Omron** — Various formats, manual entry fallback

### New Database Table

#### `bioimpedance_imports`

```elixir
schema "bioimpedance_imports" do
  field :device_type, :string          # "anovator", "relaxmedic", "inbody", "tanita", "omron", "other"
  field :status, :string               # "pending_extraction", "extracted", "reviewed", "applied", "rejected"
  field :extracted_data, :map          # AI-extracted measurements
  field :confidence_score, :float      # AI confidence (0.0-1.0)
  field :trainer_notes, :string
  field :applied_at, :utc_datetime     # When data was applied to BodyAssessment

  belongs_to :media_file, GaPersonal.Media.MediaFile
  belongs_to :student, GaPersonal.Accounts.StudentProfile
  belongs_to :trainer, GaPersonal.Accounts.User
  belongs_to :body_assessment, GaPersonal.Evolution.BodyAssessment  # Created after review

  timestamps()
end
```

### Processing Flow

```
1. Upload PDF/photo → media_files (Phase A flow)
2. POST /bioimpedance/extract → Creates bioimpedance_import (status: pending_extraction)
3. Oban worker → Sends to Claude Haiku for OCR extraction
4. Claude returns structured data → Updates extracted_data, confidence_score
5. Trainer reviews extracted data in UI → Can edit values
6. Trainer approves → Creates BodyAssessment record from extracted data
```

### AI Extraction (Claude Haiku)

Prompt template:
```
Extract bioimpedance measurements from this {device_type} report.
Return JSON with these fields (null if not found):
- weight_kg, height_cm, body_fat_percentage, muscle_mass_kg
- visceral_fat_level, basal_metabolic_rate, body_water_percentage
- bone_mass_kg, protein_percentage, segmental_analysis (if available)
Include a confidence score (0.0-1.0) for each extracted value.
```

### API Endpoints

```
POST   /api/v1/bioimpedance/extract         # Start extraction from uploaded file
GET    /api/v1/bioimpedance/imports          # List imports (with filters)
GET    /api/v1/bioimpedance/imports/:id      # Import detail with extracted data
PUT    /api/v1/bioimpedance/imports/:id      # Trainer edits extracted data
POST   /api/v1/bioimpedance/imports/:id/apply   # Apply to BodyAssessment
POST   /api/v1/bioimpedance/imports/:id/reject  # Reject extraction
```

---

## Phase C: AI Analysis

### Scope
Three analysis types using Claude API, with rate limiting, caching, and mandatory trainer review.

### New Database Table

#### `ai_analyses`

```elixir
schema "ai_analyses" do
  field :analysis_type, :string     # "visual_body", "numeric_trends", "medical_document"
  field :status, :string            # "queued", "processing", "completed", "failed", "reviewed"
  field :model_used, :string        # "claude-haiku-4-5", "claude-sonnet-4-5"
  field :input_data, :map           # What was sent to Claude (references, not raw data)
  field :result, :map               # Structured AI analysis result
  field :confidence_score, :float
  field :trainer_review, :string    # Trainer's notes after review
  field :reviewed_at, :utc_datetime
  field :visible_to_student, :boolean, default: false
  field :tokens_used, :integer      # For cost tracking
  field :processing_time_ms, :integer

  belongs_to :student, GaPersonal.Accounts.StudentProfile
  belongs_to :trainer, GaPersonal.Accounts.User
  belongs_to :media_file, GaPersonal.Media.MediaFile  # Optional, for visual/doc analysis

  timestamps()
end
```

### C1: Visual Body Analysis (Claude Sonnet)

**Input:** Evolution photos (front, back, side)
**Output:** Structured observations about posture, muscle symmetry, body composition changes

```
Prompt: Analyze these fitness progress photos. Provide professional observations about:
- Visible muscle development changes
- Posture alignment observations
- Body composition visual assessment
- Areas of notable progress
- Suggestions for focus areas
Do NOT provide medical diagnoses. This is for a personal trainer's reference only.
```

### C2: Numeric Trends Analysis (Claude Haiku)

**Input:** BodyAssessment history (last 6-12 months)
**Output:** Trend analysis, alerts, recommendations

```
Prompt: Analyze this body composition data series for a fitness client:
{assessment_data_json}
Provide:
- Key trends (improving, stable, declining)
- Alerts (sudden changes, plateaus)
- Contextual observations
- Suggested focus areas based on data patterns
```

### C3: Medical Document Extraction (Claude Haiku + Sonnet)

**Input:** Medical exam photos/PDFs (blood work, clearances, etc.)
**Output:** Extracted values, flagged abnormalities, fitness-relevant observations

```
Step 1 (Haiku): Extract all numeric values and reference ranges from this medical document.
Step 2 (Sonnet): Given these extracted lab values, provide fitness-relevant observations:
- Values outside normal ranges
- Nutritional deficiency indicators
- Exercise contraindications (if any)
- Relevant observations for a personal trainer
IMPORTANT: This is NOT medical advice. Flag anything requiring medical attention.
```

### New Module: `GaPersonal.AI.Client`

Centralized Claude API client:
- Rate limiting: Max 10 analyses per trainer per hour
- Cost tracking: Log tokens used per analysis
- Retry logic: 3 retries with exponential backoff
- Caching: Cache identical analysis requests for 24 hours
- Model selection: Route to Haiku or Sonnet based on analysis type

### API Endpoints

```
POST   /api/v1/ai/analyze/visual       # Request visual body analysis
POST   /api/v1/ai/analyze/trends       # Request numeric trends analysis
POST   /api/v1/ai/analyze/document     # Request medical document analysis
GET    /api/v1/ai/analyses             # List analyses (with filters)
GET    /api/v1/ai/analyses/:id         # Analysis detail
PUT    /api/v1/ai/analyses/:id/review  # Trainer review (approve/edit)
POST   /api/v1/ai/analyses/:id/share   # Make visible to student
GET    /api/v1/ai/usage                # Usage stats and costs
```

### Oban Workers

- `GaPersonal.Workers.VisualAnalysis` — Queue: `:ai`, max_attempts: 3
- `GaPersonal.Workers.TrendsAnalysis` — Queue: `:ai`, max_attempts: 3
- `GaPersonal.Workers.DocumentAnalysis` — Queue: `:ai`, max_attempts: 3

---

## Phase D: Pose Detection

### Scope
Client-side pose detection using TensorFlow.js MoveNet. Two modes: static posture analysis and real-time exercise guidance.

### Architecture

100% client-side — no server processing for pose detection.

```
Browser loads TensorFlow.js + MoveNet model
Camera feed → MoveNet → 17 keypoints
Keypoints → Analysis logic (JS) → Visual overlay + feedback
Results (keypoints + scores) → Backend for storage (optional)
```

### D1: Static Posture Analysis (MoveNet Thunder)

**Use case:** Student takes photo or short video, app analyzes posture alignment.

**Keypoints analyzed:**
- Shoulder alignment (left/right shoulder Y-axis comparison)
- Hip alignment (left/right hip Y-axis comparison)
- Spine curvature (nose → mid-shoulder → mid-hip line)
- Knee alignment (front view)
- Head position relative to shoulders

**Output:** Visual overlay with alignment lines, deviation angles, symmetry scores.

### D2: Real-Time Exercise Guidance (MoveNet Lightning @ 30fps)

**Use case:** During exercise execution, provides real-time form feedback.

**Supported exercises (initial set):**
- Squat — Knee tracking, depth detection, back angle
- Deadlift — Hip hinge angle, back alignment
- Shoulder press — Elbow path, wrist alignment
- Plank — Hip sag/pike detection
- Lunge — Front knee tracking, torso alignment

**Feedback mechanism:**
- Green overlay: Good form
- Yellow overlay: Minor correction needed
- Red overlay: Stop — significant form issue
- Audio cues (optional): "Knees out", "Chest up", "Go deeper"

### Vue Component: `<PoseDetector>`

Location: `frontend/shared/src/components/PoseDetector.vue`

```typescript
interface PoseDetectorProps {
  mode: 'posture' | 'exercise'
  exercise?: string           // Exercise name for guidance mode
  onKeypointsDetected?: (keypoints: Keypoint[]) => void
  onFeedback?: (feedback: FormFeedback) => void
  showOverlay?: boolean       // Draw skeleton on canvas
  showAngles?: boolean        // Show joint angles
  captureResults?: boolean    // Save results to backend
}
```

### New Database Table

#### `pose_analyses`

```elixir
schema "pose_analyses" do
  field :analysis_type, :string     # "posture", "exercise"
  field :exercise_name, :string     # For exercise mode
  field :keypoints_data, :map       # Raw keypoints from MoveNet
  field :scores, :map               # Computed scores (symmetry, angles, form)
  field :feedback, {:array, :string}  # Generated feedback messages
  field :overall_score, :float      # 0.0-1.0

  belongs_to :student, GaPersonal.Accounts.StudentProfile
  belongs_to :trainer, GaPersonal.Accounts.User

  timestamps()
end
```

### API Endpoints

```
POST   /api/v1/pose/results           # Save pose analysis results
GET    /api/v1/pose/results           # List results (with filters)
GET    /api/v1/pose/results/:id       # Result detail
GET    /api/v1/students/:id/pose      # Student's pose history
```

### Dependencies (Frontend)

```json
{
  "@tensorflow/tfjs": "^4.x",
  "@tensorflow-models/pose-detection": "^2.x"
}
```

Model loading strategy:
- Load on demand (not at app startup)
- Cache model in IndexedDB after first load
- Lightning model: ~5MB (exercise guidance)
- Thunder model: ~8MB (posture analysis)

---

## Implementation Order

```
Phase A (Media Upload) → Phase B (Bioimpedance) → Phase C (AI Analysis) → Phase D (Pose Detection)
```

Each phase is independently deployable and testable. Phase B and C depend on Phase A for file upload infrastructure. Phase D is fully independent (client-side).

### Estimated New Tables
- `media_files`
- `consent_records`
- `access_logs`
- `bioimpedance_imports`
- `ai_analyses`
- `pose_analyses`

### New Oban Queues
- `:ai` — For AI analysis workers (concurrency: 2)
- `:cleanup` — For LGPD data retention cleanup (concurrency: 1)

### New Dependencies
- `gcs_signed_url` or `goth` — GCS signed URL generation (backend)
- `req` — HTTP client for Claude API calls (backend, already available)
- `@tensorflow/tfjs` — TensorFlow.js (frontend)
- `@tensorflow-models/pose-detection` — MoveNet models (frontend)

---

## Security & Privacy Summary

| Concern | Solution |
|---------|----------|
| File storage | GCS with encryption at rest (Google-managed keys) |
| File access | Time-limited signed URLs (15 min default) |
| Medical data | Separate access controls, audit logging |
| AI analysis | Results stored encrypted, trainer review required |
| LGPD consent | Granular consent tracking with revocation |
| LGPD deletion | Soft delete → 30-day grace → hard delete + GCS purge |
| LGPD access | Data export endpoint for student self-service |
| LGPD audit | Complete access log trail for all sensitive operations |
| Pose data | Processed client-side, video never leaves device |
| Rate limiting | 10 AI analyses per trainer per hour |
| Cost control | Token usage tracking, alerts at budget thresholds |
