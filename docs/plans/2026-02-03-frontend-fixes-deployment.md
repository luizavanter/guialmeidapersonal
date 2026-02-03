# Frontend Fixes and Deployment - 2026-02-03

## Overview

Full debugging and deployment of GA Personal frontend applications with backend integration fixes.

## Issues Found and Fixed

### 1. CORS Configuration (Backend)

**Problem:** OPTIONS preflight requests returned 404 because CORSPlug was in the router pipeline, not intercepting requests before routing.

**Solution:** Moved CORSPlug from `router.ex` to `endpoint.ex` (before the router) to handle OPTIONS preflight requests.

**File:** `apps/ga_personal_web/lib/ga_personal_web/endpoint.ex`
```elixir
# CORS - must be before Router to handle OPTIONS preflight requests
plug CORSPlug,
  origin: [
    "http://localhost:3001", "http://localhost:3002", "http://localhost:3003",
    "https://guialmeidapersonal.esp.br", "https://www.guialmeidapersonal.esp.br",
    "https://admin.guialmeidapersonal.esp.br", "https://app.guialmeidapersonal.esp.br",
    ...
  ],
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  headers: ["Authorization", "Content-Type", "Accept", "Origin", "User-Agent", "X-Requested-With"]

plug GaPersonalWeb.Router
```

### 2. Auth Response Format (Backend)

**Problem:** Frontend expected `{ user, tokens: { accessToken, refreshToken, expiresIn } }` but backend returned `{ user, token }`.

**Solution:** Updated `auth_controller.ex` to return the expected format with proper field names.

**File:** `apps/ga_personal_web/lib/ga_personal_web/controllers/auth_controller.ex`
- Changed `token` to `tokens: { accessToken, refreshToken, expiresIn }`
- Changed `full_name` to `firstName` + `lastName`
- Changed `locale` format from `pt_BR` to `pt-BR`
- Added `createdAt`, `updatedAt`, `avatarUrl` fields

### 3. Router Infinite Loop (Frontend)

**Problem:** Admin users couldn't access trainer routes because guard checked `role === 'trainer'`, causing infinite redirect loop.

**Solution:** Updated router guard to allow both 'trainer' and 'admin' roles.

**File:** `frontend/trainer-app/src/router/index.ts`
```typescript
if (to.meta.requiresTrainer) {
  const allowedRoles = ['trainer', 'admin']
  if (!user.value || !allowedRoles.includes(user.value.role)) {
    next({ name: 'login' })
    return
  }
}
```

### 4. Missing Vue Imports (Frontend)

**Problem:** `computed` was used but not imported in some components.

**Files Fixed:**
- `frontend/trainer-app/src/views/students/StudentsView.vue`
- `frontend/trainer-app/src/views/workouts/ExercisesView.vue`

```typescript
// Before
import { ref, onMounted } from 'vue'
// After
import { ref, computed, onMounted } from 'vue'
```

### 5. Store Data Access Bug (Frontend)

**Problem:** Stores used `response.data` but `useApi` already extracts data, so it was accessing undefined.

**Solution:** Changed `response.data` to `response` in all stores.

**Files Fixed:**
- `frontend/trainer-app/src/stores/studentsStore.ts`
- `frontend/trainer-app/src/stores/appointmentsStore.ts`
- `frontend/trainer-app/src/stores/financeStore.ts`
- `frontend/trainer-app/src/stores/workoutsStore.ts`

### 6. GCS SPA Routing

**Problem:** Direct navigation to routes like `/login` returned 404 from GCS.

**Solution:** Configured GCS buckets to serve `index.html` for error pages.

```bash
gcloud storage buckets update gs://admin-guialmeidapersonal \
  --web-main-page-suffix=index.html \
  --web-error-page=index.html
```

### 7. CDN Caching

**Problem:** Old JavaScript files were cached, causing stale code to run.

**Solution:**
- Set `cache-control: no-cache` for `index.html`
- Invalidated CDN cache after each deployment

```bash
gcloud storage objects update gs://admin-guialmeidapersonal/index.html \
  --cache-control="no-cache, no-store, must-revalidate"

gcloud compute url-maps invalidate-cdn-cache ga-personal-lb \
  --host admin.guialmeidapersonal.esp.br --path "/*"
```

## Deployment Status

| Component | URL | Status |
|-----------|-----|--------|
| Backend API | api.guialmeidapersonal.esp.br | ✅ Deployed |
| Admin Dashboard | admin.guialmeidapersonal.esp.br | ✅ Deployed |
| Main Site | guialmeidapersonal.esp.br | ✅ Deployed |
| Student App | app.guialmeidapersonal.esp.br | ✅ Deployed |

### 8. Missing Modal Functionality (Frontend)

**Problem:** Multiple views had buttons with no @click handlers and no modals.

**Files Fixed:**
- `frontend/trainer-app/src/views/students/StudentsView.vue` - Add Student modal
- `frontend/trainer-app/src/views/appointments/AgendaView.vue` - Create Appointment modal
- `frontend/trainer-app/src/views/workouts/ExercisesView.vue` - Add Exercise modal
- `frontend/trainer-app/src/views/workouts/WorkoutPlansView.vue` - Add Plan modal
- `frontend/trainer-app/src/views/finance/PaymentsView.vue` - Add Payment modal + View modal
- `frontend/trainer-app/src/views/finance/SubscriptionsView.vue` - Add Subscription modal
- `frontend/trainer-app/src/views/finance/PlansView.vue` - Add Plan modal
- `frontend/trainer-app/src/views/messages/MessagesView.vue` - Compose modal

**Solution:** Added complete modal functionality with:
- Reactive form state
- Form validation
- API integration via stores
- Error handling
- Loading states

## Pages Tested

### Admin Dashboard (trainer-app)
- ✅ Login - authentication working
- ✅ Dashboard - stats, appointments, payments display
- ✅ Alunos - student list, filters, add student modal
- ✅ Agenda - calendar navigation, create appointment modal
- ✅ Treinos - exercises library (add exercise modal), workout plans (add plan modal)
- ✅ Financeiro - payments (add/view modals), subscriptions (add modal), plans (add modal)
- ✅ Mensagens - inbox, compose modal
- ✅ Configurações - profile settings, language

### Main Site
- ✅ Home page loads with hero, services, testimonials
- ✅ Navigation works (Home, About, Services, Blog, Contact)
- ⚠️ Some images 404 (need to upload to GCS)

### Student App
- ✅ Login page loads and redirects properly

## Test Credentials

```
Email: admin@guialmeidapersonal.esp.br
Password: Admin@123456
Role: admin
```

## Commands Reference

### Build and Deploy Frontend
```bash
# Build
cd frontend/trainer-app && npm run build

# Deploy to GCS
gcloud storage rsync dist gs://admin-guialmeidapersonal --recursive --delete-unmatched-destination-objects

# Set cache headers
gcloud storage objects update gs://admin-guialmeidapersonal/index.html --cache-control="no-cache, no-store, must-revalidate"

# Invalidate CDN
gcloud compute url-maps invalidate-cdn-cache ga-personal-lb --host admin.guialmeidapersonal.esp.br --path "/*"
```

### Build and Deploy Backend
```bash
./infrastructure/gcp/09-build-backend.sh
SKIP_MIGRATIONS=true ./infrastructure/gcp/10-deploy-backend.sh
```
