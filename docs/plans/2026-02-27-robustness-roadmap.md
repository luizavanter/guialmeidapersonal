# GA Personal — Robustness & Integration Roadmap

**Date:** 2026-02-27
**Status:** Approved
**Scope:** Security hardening, test coverage, email transacional, Asaas payment integration

---

## Understanding Summary

- **What:** Harden the GA Personal platform for production readiness with security fixes, comprehensive tests, automated emails, notifications, and Asaas payment integration
- **Why:** System is about to go live with real students — must be secure, tested, and automated
- **Who:** Guilherme Almeida (single trainer, up to 30 active students)
- **Key constraints:** Asaas account not yet created (sandbox first), Resend already configured for email
- **Non-goals:** Chat system (replaced by notifications), multi-trainer support, mobile app

## Assumptions

- Asaas sandbox API is functionally identical to production
- Resend free tier is sufficient for < 30 students
- Single trainer model (no multi-tenancy complexity for billing)
- Portuguese is the primary language for all automated emails
- Oban is acceptable as a dependency for background jobs

---

## Phase 1 — Security Hardening

### Approach: Sequential PRs (Option A)

#### PR 1.1: Fix JWT Refresh Tokens
**Problem:** Refresh token currently uses the same value as access token. If compromised, attacker has permanent access.

**Changes:**
- Generate separate opaque refresh token (secure random, 64 bytes)
- Store refresh tokens in DB table `refresh_tokens` (token_hash, user_id, expires_at, revoked_at)
- Hash refresh tokens before storage (`:crypto.hash(:sha256, token)`)
- Access token: 15-minute TTL (Guardian JWT)
- Refresh token: 30-day TTL (opaque, DB-backed)
- Logout revokes refresh token in DB
- Token refresh issues new access + new refresh token (rotation)

**Files:**
- `apps/ga_personal/lib/ga_personal/accounts/refresh_token.ex` — Schema
- `apps/ga_personal/priv/repo/migrations/*_create_refresh_tokens.exs` — Migration
- `apps/ga_personal/lib/ga_personal/accounts.ex` — Token management functions
- `apps/ga_personal_web/lib/ga_personal_web/controllers/auth_controller.ex` — Updated login/refresh/logout

#### PR 1.2: Rate Limiting
**Changes:**
- Add `hammer` dependency for rate limiting
- Rate limit public endpoints:
  - `/api/v1/auth/login` — 5 attempts per minute per IP
  - `/api/v1/auth/register` — 3 attempts per minute per IP
  - `/api/v1/contact` — 3 attempts per minute per IP
  - `/api/v1/auth/refresh` — 10 attempts per minute per IP
- Custom plug `RateLimit` with configurable limits
- Return 429 Too Many Requests with `Retry-After` header

**Files:**
- `mix.exs` — Add `hammer` dependency
- `apps/ga_personal_web/lib/ga_personal_web/plugs/rate_limit.ex` — Plug
- `apps/ga_personal_web/lib/ga_personal_web/router.ex` — Apply to pipelines

#### PR 1.3: Health Check Endpoint
**Changes:**
- `GET /api/v1/health` — Returns 200 with system status
- Checks: DB connectivity, Redis connectivity, app version
- No authentication required
- Used by Cloud Run health checks and deploy verification

**Files:**
- `apps/ga_personal_web/lib/ga_personal_web/controllers/health_controller.ex`
- `apps/ga_personal_web/lib/ga_personal_web/router.ex`

#### PR 1.4: Input Validation & Sanitization
**Changes:**
- Add `html_sanitize_ex` dependency
- Sanitize all text inputs (strip HTML/script tags)
- Validate string lengths on all text fields
- Validate email format server-side
- Validate phone format

**Files:**
- `mix.exs` — Add dependency
- `apps/ga_personal/lib/ga_personal/validators.ex` — Shared validation module
- Update changesets in all schemas

---

## Phase 2 — Complete Test Coverage

### PR 2.1: Test Infrastructure
- ExMachina factories for all 17 schemas
- ConnCase helpers (authenticated requests, role-based)
- DataCase helpers (context testing)
- Shared test fixtures

### PR 2.2: Context Tests
- Tests for all 8 contexts (Accounts, Schedule, Workouts, Evolution, Finance, Messaging, Content, System)
- CRUD operations, business logic, edge cases
- Multi-tenant isolation verification

### PR 2.3: Controller Tests
- Tests for all 20 controllers
- Auth: unauthenticated (401), wrong role (403), correct role (200)
- CRUD: create (201), read (200), update (200), delete (200/204)
- Validation: invalid data (422), missing fields (422)
- Rate limiting (429) — after Phase 1

---

## Phase 3 — Email Transacional + Notifications

### PR 3.1: Email Templates & Triggers
**Emails (via Resend):**
1. `welcome_email` — When student is created
2. `appointment_confirmation` — When appointment is booked
3. `appointment_reminder` — 24h before appointment (Oban scheduled job)
4. `payment_due_reminder` — 3 days before due date (Oban scheduled job)
5. `payment_overdue` — When payment passes due date
6. `weekly_trainer_summary` — Every Monday morning (active students, upcoming week, pending payments)

**Templates:** HTML with inline CSS, bilingual (PT-BR primary, EN-US fallback based on user locale)

**Files:**
- `apps/ga_personal/lib/ga_personal/emails/` — Email modules
- `apps/ga_personal/lib/ga_personal/workers/` — Oban workers
- `mix.exs` — Add `oban` dependency
- `config/config.exs` — Oban configuration

### PR 3.2: Notification System
**In-app notifications:**
- Use existing `notifications` table
- Types: appointment_reminder, payment_due, workout_assigned, assessment_due, system
- API: `GET /api/v1/notifications`, `PUT /api/v1/notifications/:id/read`, `PUT /api/v1/notifications/read-all`
- Unread count in nav badge (both apps)
- Created automatically by email triggers (dual delivery: email + in-app)

**Files:**
- `apps/ga_personal/lib/ga_personal/messaging.ex` — Notification functions
- `apps/ga_personal_web/lib/ga_personal_web/controllers/notification_controller.ex`
- `apps/ga_personal_web/lib/ga_personal_web/router.ex` — New routes
- Frontend: notification badge component, notifications view

---

## Phase 4 — Asaas Payment Integration

### PR 4.1: Asaas Client + Customer Sync
**Asaas HTTP client:**
- `GaPersonal.Asaas.Client` — Base HTTP client (Tesla or Req)
- `GaPersonal.Asaas.Customers` — Create, update, find customers
- Config: `ASAAS_API_KEY`, `ASAAS_ENVIRONMENT` (sandbox/production)

**Customer sync:**
- When student is created → create Asaas customer
- Store `asaas_customer_id` on students table
- Sync name, email, CPF, phone

**Database:**
- Migration: add `asaas_customer_id` to `students`
- Migration: add `asaas_charge_id`, `payment_method` to `payments`

### PR 4.2: Charges + Webhooks
**Charge creation:**
- Trainer creates charge from Trainer App (select student, amount, payment method)
- `GaPersonal.Asaas.Charges` — Create charge (Pix, Boleto, Credit Card)
- Returns payment link/QR code/boleto URL
- Store `asaas_charge_id` on payment record

**Webhook handler:**
- `POST /api/v1/webhooks/asaas` (public, verified by Asaas access token)
- Events: PAYMENT_CONFIRMED, PAYMENT_RECEIVED, PAYMENT_OVERDUE, PAYMENT_REFUNDED
- Updates local payment status
- Triggers notification + email on status change

**Files:**
- `apps/ga_personal/lib/ga_personal/asaas/charges.ex`
- `apps/ga_personal_web/lib/ga_personal_web/controllers/webhook_controller.ex`
- `apps/ga_personal_web/lib/ga_personal_web/router.ex`

### PR 4.3: Auto-Billing (Oban)
**Automatic charge generation:**
- Oban cron job runs daily
- Checks subscriptions with upcoming due dates
- Creates Asaas charge automatically
- Payment method from subscription or student preference
- Creates local payment record linked to Asaas charge

**Files:**
- `apps/ga_personal/lib/ga_personal/workers/auto_billing_worker.ex`
- `config/config.exs` — Oban cron schedule

---

## Implementation Order

```
Phase 1 ─── PR 1.1 (JWT) → PR 1.2 (Rate Limit) → PR 1.3 (Health) → PR 1.4 (Validation)
Phase 2 ─── PR 2.1 (Infra) → PR 2.2 (Contexts) → PR 2.3 (Controllers)
Phase 3 ─── PR 3.1 (Email) → PR 3.2 (Notifications)
Phase 4 ─── PR 4.1 (Client) → PR 4.2 (Charges) → PR 4.3 (Auto-billing)
```

Total: 12 PRs, sequential within phases, phases can partially overlap.

---

## Decision Log

| # | Decision | Alternatives Considered | Rationale |
|---|----------|------------------------|-----------|
| 1 | Security before features | Features first | System going live — security is non-negotiable |
| 2 | Sequential PRs per phase | Monolithic PRs | Easier review, test, rollback |
| 3 | Separate opaque refresh tokens | Keep JWT refresh | Industry best practice, prevents token reuse attacks |
| 4 | Hammer for rate limiting | Custom GenServer, PlugAttack | Simple, proven, ETS-backed |
| 5 | ExMachina for test factories | Manual fixtures | Standard Elixir pattern, maintainable |
| 6 | Resend for transactional email | SendGrid, SES | Already configured in project |
| 7 | Oban for background jobs | GenServer, Quantum | Persistent, retryable, battle-tested, Ecto-backed |
| 8 | Notifications replace chat | Keep bidirectional chat | Simpler, more useful for 1-trainer model |
| 9 | Asaas for payments | Stripe, PagSeguro | User's explicit choice, Brazilian-focused with Pix |
| 10 | Sandbox development first | Direct production | Zero financial risk during development |
| 11 | Tesla/Req for Asaas client | HTTPoison, Finch | Modern, middleware-based, testable |
| 12 | Webhook verification via access token | IP whitelist, signature | Asaas standard approach |
