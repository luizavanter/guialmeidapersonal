# GA Personal - Complete System Design

**Date:** 2026-02-03
**Status:** Approved
**Scope:** Full-stack personal training management system with bilingual support

---

## Executive Summary

Building a complete personal training management system for Guilherme Almeida in Florianópolis, Brazil. The system includes:
- Phoenix/Elixir backend with 8 business contexts
- 3 Vue 3 frontend applications (trainer dashboard, student portal, marketing site)
- Full bilingual support (PT-BR/EN-US)
- AI features in Phase 2 (pose detection, body analysis, Anovator integration)

**Implementation approach:** Full scaffold of entire system, then implement all features in parallel.

---

## 1. Project Architecture & Tooling

**Monorepo structure** using Elixir umbrella application:

```
ga-personal/
├── apps/
│   ├── ga_personal/         # Core business logic (contexts)
│   ├── ga_personal_web/     # Phoenix API + channels
│   └── ga_personal_ai/      # (Phase 2) AI integrations
├── frontend/
│   ├── shared/              # @ga-personal/shared package
│   ├── trainer-app/         # Vue 3 - Trainer dashboard
│   ├── student-app/         # Vue 3 - Student portal
│   └── site/                # VitePress - Marketing site
├── docker-compose.yml       # PostgreSQL + Redis
├── mix.exs                  # Umbrella config
└── .github/workflows/       # CI/CD
```

**Key architectural decisions:**
1. Phoenix umbrella app - separates business logic from web layer
2. JSON API - Phoenix serves pure JSON, frontends are SPAs
3. JWT auth with Guardian - tokens work across all 3 frontends
4. Shared types - generate TypeScript types from Ecto schemas
5. Monorepo tooling - single command to start all services

---

## 2. Database Schema & Migrations

**All migrations created upfront** with complete schema:

**8 main domain groups:**
- `users`, `student_profiles` (Accounts)
- `time_slots`, `appointments` (Schedule)
- `exercises`, `workout_plans`, `workout_exercises`, `workout_logs` (Workouts)
- `body_assessments`, `evolution_photos`, `goals` (Evolution)
- `plans`, `subscriptions`, `payments` (Finance)
- `messages`, `notifications` (Messaging)
- Content tables (blog posts, testimonials, FAQs)
- System tables (audit logs, settings)

**Migration strategy:**
- Single initial migration with all core tables
- UUID primary keys everywhere
- Timestamps on everything (`inserted_at`, `updated_at`)
- Soft deletes where needed
- Foreign key constraints enforced at DB level
- Indexes on foreign keys and frequently queried fields

**Data seeding:**
- Sample exercises library (50-100 exercises)
- Default trainer account for Guilherme
- Sample plans (monthly, quarterly, personal training packages)
- Test student accounts for development

---

## 3. Phoenix Contexts Architecture

Each context is a **boundary around a business domain** with clean public API:

**Context pattern:**
```elixir
defmodule GaPersonal.Accounts do
  def list_students(trainer_id, filters \\ %{})
  def get_student!(id)
  def create_student(trainer_id, attrs)
  def update_student(student, attrs)
  def deactivate_student(student)
  def register_user(attrs)
  def authenticate(email, password)
end
```

**Key principles:**
1. No direct Ecto queries in web layer
2. Bang functions (!) for "must exist" operations
3. Multi-tenant by default - every query scoped to trainer_id
4. Changesets for validation - business rules in schemas
5. Preloading strategy - contexts handle associations

**Context responsibilities:**
- **Accounts** - user CRUD, auth, profiles, roles
- **Schedule** - slot management, appointment booking, recurrence logic
- **Workouts** - exercise library, plan assembly, logging
- **Evolution** - assessments, photos, goal tracking, calculations
- **Finance** - plan management, subscription lifecycle, payment tracking
- **Messaging** - direct messages, notifications, broadcasts
- **Content** - blog posts, testimonials, FAQs
- **Notifications** - system notifications, reminders

---

## 4. REST API Design & Authentication

**API structure:**
```
/api/v1/
├── /auth/register, /login, /refresh, /logout
├── /students (GET, POST)
├── /students/:id (GET, PUT, DELETE)
├── /appointments (GET, POST)
├── /workout-plans (GET, POST)
├── /exercises (GET)
├── /body-assessments (GET, POST)
├── /goals (GET, POST, PUT)
└── /messages (GET, POST)
```

**Authentication flow:**
1. Login → returns access token (15min) + refresh token (7 days)
2. All requests include `Authorization: Bearer <access_token>`
3. Token refresh → exchange refresh token for new access token
4. Logout → blacklist refresh token

**Authorization middleware:**
- `RequireAuth` - verifies valid token
- `RequireRole` - checks user role (`:trainer`, `:student`, `:admin`)
- `RequireOwnership` - ensures users can only access their own data

**Response format:**
```json
{
  "data": {...},
  "meta": {"page": 1, "total": 50},
  "errors": null
}
```

---

## 5. Frontend Architecture (Vue 3 Apps)

**3 separate Vue 3 applications** with shared package:

**Shared frontend stack:**
- Vue 3 with Composition API + `<script setup>`
- TypeScript for type safety
- Pinia for state management
- Vue Router for navigation
- Axios with interceptors for API calls
- Tailwind CSS matching design system
- Vite for dev experience

**Shared package structure:**
```
frontend/shared/
├── package.json         # @ga-personal/shared
├── src/
│   ├── components/      # Button, Input, Modal, Card, etc.
│   ├── composables/     # useAuth, useApi, usePagination
│   ├── types/           # Generated TypeScript from backend
│   ├── utils/           # Date formatters, validators
│   ├── constants/       # API endpoints, colors, config
│   ├── i18n/            # Translation files
│   └── styles/          # Shared Tailwind config
```

**Benefits:**
- Single source of truth for UI components
- Type safety across all apps
- Design system consistency enforced
- Less duplication of API calls, auth logic
- Easier maintenance

---

## 6. Individual App Responsibilities

**Trainer App (Painel do Personal)**
- Dashboard - today's appointments, pending payments, messages
- Students - list, search, detailed profiles, activity history
- Agenda - calendar view, drag-drop scheduling, recurring appointments
- Workouts - exercise library, build/edit workout plans, assign to students
- Evolution - view student assessments, compare photos, track goals
- Finance - payment tracking, subscription management, revenue reports
- Messages - inbox, send announcements, individual chats
- **Role:** `:trainer` only

**Student App (Portal do Aluno)**
- Dashboard - next appointment, current workout plan, recent progress
- My Workouts - view assigned plans, log completed exercises
- Evolution - view own assessments/photos, track goals, progress charts
- Schedule - view upcoming appointments, request changes
- Messages - chat with trainer
- Profile - update personal info
- **Role:** `:student` only

**Site (VitePress)**
- Home - hero, services, social proof
- About Guilherme - bio, credentials, philosophy
- Services - training packages, pricing
- Blog - fitness tips, success stories
- Contact - booking inquiry form

---

## 7. Authentication Flow

**Login flow:**
1. User visits app → redirected to `/login`
2. Submit email/password → `POST /api/v1/auth/login`
3. Backend returns access token + refresh token + user object
4. Frontend stores tokens in localStorage
5. Redirect to dashboard

**Token management:**
- Access token in Axios interceptor: `Authorization: Bearer <token>`
- 401 response → attempt refresh with refresh token
- Refresh succeeds → retry original request
- Refresh fails → logout, redirect to login

**Composable:**
```typescript
export const useAuth = () => {
  const user = ref(null)
  const isAuthenticated = computed(() => !!user.value)

  const login = async (email, password) => {...}
  const logout = async () => {...}
  const refreshToken = async () => {...}

  return { user, isAuthenticated, login, logout }
}
```

**Route guards:**
- Trainer app requires `:trainer` role
- Student app requires `:student` role
- Unauthorized role → redirect or error

---

## 8. Development Workflow & Tooling

**One-command startup:**
```bash
npm run dev          # Starts everything
npm run dev:backend  # Phoenix only
npm run dev:frontend # All 3 Vue apps
npm run setup        # First-time setup
```

**Docker Compose:**
```yaml
services:
  postgres:
    image: postgres:16
    ports: ["5432:5432"]

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
```

**Development ports:**
- Phoenix API: `localhost:4000`
- Trainer app: `localhost:3001`
- Student app: `localhost:3002`
- VitePress site: `localhost:3003`

**Hot reloading:**
- Phoenix auto-recompiles Elixir files
- Vite provides instant HMR for Vue apps

**Type generation:**
```bash
mix phx.gen.typescript  # Generates TS types from Ecto schemas
# Output: frontend/shared/src/types/generated/
```

---

## 9. Deployment & CI/CD

**Backend (Phoenix):**
- Deploy to Fly.io or Gigalixir
- PostgreSQL managed database
- Redis for caching, token blacklist

**Frontends (3 Vue apps):**
- Deploy to Vercel or Netlify
- Each app as separate project
- Environment variables per app

**CI/CD Pipeline (GitHub Actions):**
- `backend-test` - mix test, format check, credo
- `frontend-test` - type checking, linting, build
- `deploy-staging` - on develop branch
- `deploy-production` - on main branch, runs migrations

---

## 10. Initial Scaffold Implementation

**Backend:**
- ✅ All 8 contexts with module files
- ✅ All database tables migrated
- ✅ All Ecto schemas with relationships
- ✅ Basic CRUD functions in each context
- ✅ All API endpoints responding
- ✅ Auth working end-to-end
- ✅ Seeds for exercises, sample data
- ⚠️ Business logic stubbed initially

**Frontends:**
- ✅ Project structure, dependencies
- ✅ Router with all routes defined
- ✅ Layout components (header, sidebar)
- ✅ Auth pages fully functional
- ✅ Navigation to all screens
- ✅ API client with auth interceptors
- ⚠️ Feature screens placeholder initially

**Shared package:**
- ✅ Design system components
- ✅ TypeScript types generated
- ✅ `useAuth`, `useApi` composables
- ✅ Tailwind config with GA colors/fonts

---

## 11. Feature Implementation Priority

**Priority 1 - Core Workflow**
1. Student Management - Full CRUD
2. Schedule/Agenda - Time slots, booking, calendar
3. Basic messaging - Direct messages

**Priority 2 - Training Features**
1. Exercise library - Full CRUD
2. Workout plan builder - Drag-drop exercises
3. Student workout view - See assigned plans
4. Workout logging - Log completed exercises

**Priority 3 - Progress Tracking**
1. Body assessments - Manual entry
2. Evolution photos - Upload, compare
3. Goals tracking - Set targets, track progress
4. Charts/graphs - Weight, measurements over time

**Priority 4 - Business Management**
1. Plans & subscriptions - Package management
2. Payment tracking - Manual payment logging
3. Financial reports - Revenue, outstanding
4. Notifications - Reminders, announcements

**Timeline:** All priorities implemented in parallel today.

---

## 12. Design System Implementation

**GA Personal Design System:**

**Colors (Tailwind):**
```js
colors: {
  coal: '#0A0A0A',      // backgrounds
  lime: '#C4F53A',      // primary actions
  ocean: '#0EA5E9',     // secondary, links
  smoke: '#F5F5F0',     // light text, cards
}
```

**Typography:**
- Display: Bebas Neue (impact headlines)
- Body: Outfit (comfortable reading)
- Mono: JetBrains Mono (metrics/data)

**Component library (shared package):**
- `Button` - primary, secondary, ghost variants
- `Input` / `Textarea` - dark mode, validation states
- `Card` - container with subtle borders
- `Modal` - overlay dialogs
- `Table` - data tables with sorting
- `Chart` - wrapper around Chart.js
- `Avatar` - user photos with fallback
- `Badge` - status indicators

**Dark-first design:**
- Coal backgrounds, smoke text
- Lime accents for CTAs
- Ocean for informational elements

---

## 13. Internationalization (i18n)

**Frontend (Vue I18n):**
```typescript
const i18n = createI18n({
  locale: 'pt-BR',        // Default Brazilian Portuguese
  fallbackLocale: 'en-US',
  messages: { 'en-US': en, 'pt-BR': pt }
})
```

**Translation structure:**
```json
// locales/pt-BR.json
{
  "auth": {
    "login": "Entrar",
    "email": "E-mail"
  },
  "students": {
    "title": "Alunos",
    "addNew": "Adicionar Aluno"
  }
}
```

**Backend (Gettext):**
- Error messages in both languages
- Email templates in both languages
- API returns translated errors based on `Accept-Language`

**Language switcher:**
- Toggle in user profile
- Persisted in database + localStorage
- Browser language detection on first visit

**Default:** PT-BR (Guilherme's market), switchable to EN-US anytime

---

## Phase 2: AI Features (Future)

**To be implemented after core system:**
- TensorFlow.js MoveNet - pose detection in browser
- Claude API Sonnet - visual body analysis
- Anovator Collector - automated bioimpedance import
- Integration of AI insights with body assessments

---

## Success Criteria

✅ Complete monorepo running locally with one command
✅ All 3 frontends + backend + database working
✅ Full authentication flow functional
✅ All features implemented across all priorities
✅ Bilingual support (PT-BR/EN-US) throughout
✅ Design system consistently applied
✅ Type-safe API communication
✅ Ready for production deployment

---

*Design approved: 2026-02-03*
