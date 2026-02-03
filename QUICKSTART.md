# Quick Start Guide - GA Personal Backend

## TL;DR - Get Running in 3 Steps

```bash
# 1. Run setup (installs deps, starts DB, migrates)
./bin/setup

# 2. Start the server
mix phx.server

# 3. Test the API
curl http://localhost:4000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"guilherme@gapersonal.com","password":"trainer123"}'
```

## What You Get

- **Full Phoenix API** with 8 business contexts
- **PostgreSQL database** with 20+ tables
- **JWT authentication** with Guardian
- **Bilingual support** (PT-BR/EN-US)
- **Multi-tenant** architecture (trainer-scoped)
- **20+ exercises** in seed data
- **2 test students** ready to use
- **Complete CRUD** for all resources

## Available Endpoints

### Authentication
```bash
# Register new user
POST /api/v1/auth/register

# Login (get JWT token)
POST /api/v1/auth/login

# Get current user
GET /api/v1/auth/me
```

### Resources (all require JWT)
- `/api/v1/students` - Student management
- `/api/v1/appointments` - Appointment scheduling
- `/api/v1/exercises` - Exercise library
- `/api/v1/workout-plans` - Workout plan builder
- `/api/v1/workout-logs` - Student workout logs
- `/api/v1/body-assessments` - Body measurements
- `/api/v1/goals` - Goal tracking
- `/api/v1/plans` - Subscription plans
- `/api/v1/subscriptions` - Student subscriptions
- `/api/v1/payments` - Payment tracking
- `/api/v1/messages` - Direct messaging
- `/api/v1/notifications` - System notifications
- `/api/v1/blog-posts` - Blog content
- `/api/v1/testimonials` - Client testimonials
- `/api/v1/faqs` - FAQ management

## Testing the API

### 1. Login as Trainer
```bash
curl -X POST http://localhost:4000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "guilherme@gapersonal.com",
    "password": "trainer123"
  }'
```

Response:
```json
{
  "data": {
    "user": {
      "id": "...",
      "email": "guilherme@gapersonal.com",
      "full_name": "Guilherme Almeida",
      "role": "trainer"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### 2. List Students
```bash
TOKEN="your_token_here"

curl http://localhost:4000/api/v1/students \
  -H "Authorization: Bearer $TOKEN"
```

### 3. List Exercises
```bash
curl http://localhost:4000/api/v1/exercises \
  -H "Authorization: Bearer $TOKEN"
```

### 4. Create Appointment
```bash
curl -X POST http://localhost:4000/api/v1/appointments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "appointment": {
      "student_id": "student_id_here",
      "scheduled_at": "2026-02-10T10:00:00Z",
      "duration_minutes": 60,
      "appointment_type": "personal_training"
    }
  }'
```

## Database Management

```bash
# View all routes
mix phx.routes

# Reset database (drops, creates, migrates, seeds)
mix ecto.reset

# Create new migration
mix ecto.gen.migration add_field_to_table

# Run migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback
```

## Development Tools

```bash
# Format code
mix format

# Interactive Elixir shell with app loaded
iex -S mix phx.server

# Generate TypeScript types from schemas
mix phx.gen.typescript

# Run tests
mix test
```

## Default Accounts

### Trainer
- Email: `guilherme@gapersonal.com`
- Password: `trainer123`
- Role: `trainer`

### Students
1. **Maria Silva**
   - Email: `maria.silva@example.com`
   - Password: `student123`
   - Goals: Weight loss & fitness

2. **Carlos Santos**
   - Email: `carlos.santos@example.com`
   - Password: `student123`
   - Goals: Muscle gain & strength

## Common Tasks

### Add New Exercise
```bash
curl -X POST http://localhost:4000/api/v1/exercises \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "exercise": {
      "name": "Deadlift",
      "category": "strength",
      "muscle_groups": ["back", "glutes", "hamstrings"],
      "difficulty_level": "advanced",
      "is_public": true
    }
  }'
```

### Create Workout Plan
```bash
curl -X POST http://localhost:4000/api/v1/workout-plans \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "workout_plan": {
      "student_id": "student_id_here",
      "name": "Beginner Full Body",
      "duration_weeks": 8,
      "sessions_per_week": 3,
      "difficulty_level": "beginner",
      "status": "active"
    }
  }'
```

### Log Body Assessment
```bash
curl -X POST http://localhost:4000/api/v1/body-assessments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "body_assessment": {
      "student_id": "student_id_here",
      "assessment_date": "2026-02-03",
      "weight_kg": 75.5,
      "body_fat_percentage": 18.5,
      "waist_cm": 85.0
    }
  }'
```

## Troubleshooting

### Database Connection Issues
```bash
# Check if PostgreSQL is running
docker-compose ps

# Restart PostgreSQL
docker-compose restart postgres

# View PostgreSQL logs
docker-compose logs postgres
```

### Port Already in Use
```bash
# Find process using port 4000
lsof -i :4000

# Kill process
kill -9 <PID>
```

### Reset Everything
```bash
# Stop Docker containers
docker-compose down

# Clean build artifacts
mix clean

# Reset database
mix ecto.reset

# Recompile
mix compile
```

## Next Steps

1. **Explore the API** - Try all endpoints with different data
2. **Build Frontend** - Connect Vue 3 apps to this API
3. **Add Features** - Implement email notifications, file uploads
4. **Deploy** - Deploy to Fly.io or Gigalixir

## Resources

- [Phoenix Documentation](https://hexdocs.pm/phoenix)
- [Ecto Documentation](https://hexdocs.pm/ecto)
- [Guardian Documentation](https://hexdocs.pm/guardian)
- [API Documentation](./docs/api.md) *(coming soon)*

## Need Help?

- Check `README.md` for detailed documentation
- View logs: `docker-compose logs -f`
- Interactive shell: `iex -S mix phx.server`
- Ask for help: guilherme@gapersonal.com
