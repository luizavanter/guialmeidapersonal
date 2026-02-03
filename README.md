# GA Personal - Complete Personal Training Management System

A comprehensive full-stack personal training management system built for Guilherme Almeida in Florianópolis, Brazil.

## Tech Stack

### Backend
- **Phoenix 1.8** - Elixir web framework
- **Ecto 3.13** - Database wrapper and query generator
- **PostgreSQL 16** - Primary database
- **Guardian 2.4** - JWT authentication
- **Redis 7** - Caching and session storage

### Frontend (Separate projects in /frontend/)
- **Vue 3** - Progressive JavaScript framework
- **TypeScript** - Type safety
- **Pinia** - State management
- **Tailwind CSS** - Utility-first CSS
- **Vite** - Build tool

## Project Structure

```
ga-personal/
├── apps/
│   ├── ga_personal/              # Core business logic
│   │   ├── lib/
│   │   │   ├── ga_personal/
│   │   │   │   ├── accounts/     # Users & authentication
│   │   │   │   ├── schedule/     # Time slots & appointments
│   │   │   │   ├── workouts/     # Exercises, plans & logs
│   │   │   │   ├── evolution/    # Body assessments & goals
│   │   │   │   ├── finance/      # Plans, subscriptions & payments
│   │   │   │   ├── messaging/    # Messages & notifications
│   │   │   │   ├── content/      # Blog, testimonials & FAQs
│   │   │   │   └── system/       # Settings & audit logs
│   │   │   ├── guardian.ex       # JWT authentication
│   │   │   └── gettext.ex        # Internationalization
│   │   └── priv/
│   │       └── repo/
│   │           ├── migrations/   # Database migrations
│   │           └── seeds.exs     # Seed data
│   └── ga_personal_web/          # Phoenix API
│       ├── lib/
│       │   └── ga_personal_web/
│       │       ├── controllers/  # API controllers
│       │       ├── router.ex     # API routes
│       │       └── endpoint.ex   # HTTP endpoint
│       └── test/
├── config/                       # Application configuration
├── docker-compose.yml            # PostgreSQL & Redis
└── mix.exs                       # Umbrella project config
```

## Database Schema

### 8 Main Contexts with 20+ Tables:

1. **Accounts** - users, student_profiles
2. **Schedule** - time_slots, appointments
3. **Workouts** - exercises, workout_plans, workout_exercises, workout_logs
4. **Evolution** - body_assessments, evolution_photos, goals
5. **Finance** - plans, subscriptions, payments
6. **Messaging** - messages, notifications
7. **Content** - blog_posts, testimonials, faqs
8. **System** - system_settings, audit_logs

## Setup Instructions

### Prerequisites
- Elixir 1.15+
- Erlang/OTP 28+
- PostgreSQL 16+ (or Docker)
- Redis 7+ (or Docker)
- Node.js 20+ (for frontend)

### 1. Install Dependencies

```bash
# Install Elixir dependencies
mix deps.get

# Compile the project
mix compile
```

### 2. Database Setup

#### Option A: Using Docker (Recommended)

```bash
# Start PostgreSQL and Redis
docker-compose up -d

# Create and migrate database
mix ecto.setup

# This runs:
# - mix ecto.create (creates database)
# - mix ecto.migrate (runs migrations)
# - mix run apps/ga_personal/priv/repo/seeds.exs (seeds data)
```

#### Option B: Local PostgreSQL

```bash
# Update config/dev.exs with your PostgreSQL credentials
# Then run:
mix ecto.setup
```

### 3. Start the Server

```bash
# Start Phoenix server
mix phx.server

# Or inside IEx
iex -S mix phx.server
```

The API will be available at `http://localhost:4000`

### 4. Generate TypeScript Types (Optional)

```bash
# Generate TypeScript interfaces from Ecto schemas
mix phx.gen.typescript

# Output: frontend/shared/src/types/generated/index.ts
```

## Default Credentials

After running `mix ecto.setup`, you'll have:

### Trainer Account
- **Email:** guilherme@gapersonal.com
- **Password:** trainer123
- **Role:** trainer

### Test Students
- **Email:** maria.silva@example.com
- **Password:** student123
- **Role:** student

- **Email:** carlos.santos@example.com
- **Password:** student123
- **Role:** student

## API Endpoints

All endpoints are prefixed with `/api/v1`

### Public Endpoints
```
POST /api/v1/auth/register  - Register new user
POST /api/v1/auth/login     - Login and get JWT token
```

### Protected Endpoints (Require JWT)
```
GET  /api/v1/auth/me        - Get current user

# Students
GET    /api/v1/students     - List students
POST   /api/v1/students     - Create student
GET    /api/v1/students/:id - Get student
PUT    /api/v1/students/:id - Update student
DELETE /api/v1/students/:id - Delete student

# Appointments
GET    /api/v1/appointments     - List appointments
POST   /api/v1/appointments     - Create appointment
GET    /api/v1/appointments/:id - Get appointment
PUT    /api/v1/appointments/:id - Update appointment
DELETE /api/v1/appointments/:id - Delete appointment

# Exercises
GET    /api/v1/exercises     - List exercises
POST   /api/v1/exercises     - Create exercise
GET    /api/v1/exercises/:id - Get exercise
PUT    /api/v1/exercises/:id - Update exercise
DELETE /api/v1/exercises/:id - Delete exercise

# Workout Plans
GET    /api/v1/workout-plans     - List workout plans
POST   /api/v1/workout-plans     - Create plan
GET    /api/v1/workout-plans/:id - Get plan
PUT    /api/v1/workout-plans/:id - Update plan
DELETE /api/v1/workout-plans/:id - Delete plan

# Body Assessments
GET    /api/v1/body-assessments     - List assessments
POST   /api/v1/body-assessments     - Create assessment
GET    /api/v1/body-assessments/:id - Get assessment
PUT    /api/v1/body-assessments/:id - Update assessment
DELETE /api/v1/body-assessments/:id - Delete assessment

# Goals
GET    /api/v1/goals     - List goals
POST   /api/v1/goals     - Create goal
GET    /api/v1/goals/:id - Get goal
PUT    /api/v1/goals/:id - Update goal
DELETE /api/v1/goals/:id - Delete goal

# Plans (Subscription Plans)
GET    /api/v1/plans     - List plans
POST   /api/v1/plans     - Create plan
GET    /api/v1/plans/:id - Get plan
PUT    /api/v1/plans/:id - Update plan
DELETE /api/v1/plans/:id - Delete plan

# Subscriptions
GET    /api/v1/subscriptions     - List subscriptions
POST   /api/v1/subscriptions     - Create subscription
GET    /api/v1/subscriptions/:id - Get subscription
PUT    /api/v1/subscriptions/:id - Update subscription
DELETE /api/v1/subscriptions/:id - Delete subscription

# Payments
GET  /api/v1/payments     - List payments
POST /api/v1/payments     - Create payment
GET  /api/v1/payments/:id - Get payment
PUT  /api/v1/payments/:id - Update payment

# Messages
GET    /api/v1/messages       - List all messages
POST   /api/v1/messages       - Send message
GET    /api/v1/messages/inbox - Inbox messages
GET    /api/v1/messages/sent  - Sent messages
GET    /api/v1/messages/:id   - Get message
DELETE /api/v1/messages/:id   - Delete message

# Notifications
GET  /api/v1/notifications           - List notifications
GET  /api/v1/notifications/:id       - Get notification
POST /api/v1/notifications/:id/read  - Mark as read
```

## Authentication

All protected endpoints require a JWT token in the Authorization header:

```bash
# Login to get token
curl -X POST http://localhost:4000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"guilherme@gapersonal.com","password":"trainer123"}'

# Use token in subsequent requests
curl http://localhost:4000/api/v1/students \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Testing

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover

# Run specific test file
mix test test/ga_personal/accounts_test.exs
```

## Database Commands

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Reset database (drop, create, migrate, seed)
mix ecto.reset

# Generate new migration
mix ecto.gen.migration migration_name
```

## Development Workflow

```bash
# Format code
mix format

# Check for code issues
mix credo

# View routes
mix phx.routes

# Open IEx with app loaded
iex -S mix

# Generate TypeScript types
mix phx.gen.typescript
```

## Multi-tenant Architecture

All data is scoped to `trainer_id` for multi-tenant support:
- Each trainer has isolated data
- Student profiles belong to a trainer
- Queries automatically filter by trainer_id
- Prevents data leakage between trainers

## Internationalization

The system supports bilingual content (PT-BR/EN-US):
- Default locale: `pt_BR` (Brazilian Portuguese)
- Fallback locale: `en_US` (English)
- User-specific locale preference stored in database
- Gettext for backend translations
- Vue I18n for frontend translations

## Next Steps

1. **Frontend Development**
   - Trainer Dashboard (Vue 3)
   - Student Portal (Vue 3)
   - Marketing Site (VitePress)

2. **Additional Features**
   - Email notifications
   - SMS reminders
   - File upload for photos
   - Payment gateway integration
   - Report generation (PDF)

3. **Phase 2: AI Features**
   - Pose detection (TensorFlow.js MoveNet)
   - Body analysis (Claude API)
   - Anovator bioimpedance integration

## License

Proprietary - Copyright © 2026 Guilherme Almeida

## Support

For questions or issues, contact: guilherme@gapersonal.com
