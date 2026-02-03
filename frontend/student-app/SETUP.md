# Student Portal Setup Guide

## Quick Start

1. **Install dependencies**
```bash
npm install
```

2. **Start development server**
```bash
npm run dev
```

The app will be available at: http://localhost:3002

## First Time Setup

### Prerequisites
- Node.js 18+ installed
- Backend API running at http://localhost:4000

### Installation Steps

1. Navigate to the project directory:
```bash
cd /Users/luizpenha/guipersonal/frontend/student-app
```

2. Install all dependencies:
```bash
npm install
```

3. Verify the `.env` file exists with the correct API URL:
```bash
cat .env
# Should show: VITE_API_BASE_URL=http://localhost:4000/api/v1
```

4. Start the development server:
```bash
npm run dev
```

5. Open your browser to: http://localhost:3002

## Test the Application

### Login
- Navigate to http://localhost:3002/login
- Enter student credentials (from backend seed data)
- Should redirect to Dashboard after successful login

### Expected Flow
1. **Login** → Enter credentials
2. **Dashboard** → See overview (appointments, workouts, progress)
3. **My Workouts** → View workout plans
4. **Workout Detail** → Click on plan → Log exercises
5. **Evolution** → View charts and progress
6. **Schedule** → View appointments, request changes
7. **Messages** → Chat with trainer
8. **Profile** → Edit personal info

## Troubleshooting

### Port 3002 already in use
```bash
# Kill the process using port 3002
lsof -ti:3002 | xargs kill -9
```

### Cannot connect to API
- Verify backend is running at http://localhost:4000
- Check `.env` file has correct VITE_API_BASE_URL
- Check browser console for CORS errors

### Build errors
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

### Type errors
```bash
# Run type checker
npm run type-check
```

## Development Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start dev server on port 3002 |
| `npm run build` | Build for production |
| `npm run preview` | Preview production build |
| `npm run type-check` | Check TypeScript types |
| `npm run lint` | Lint and fix code |

## Project Status

✅ **Completed Features:**
- Full authentication flow with JWT
- Dashboard with stats and overview
- Workout plans viewing
- Exercise logging with validation
- Evolution tracking with charts
- Body assessments display
- Goal tracking with progress bars
- Schedule viewing and change requests
- Messaging system
- Profile editing
- Full bilingual support (PT-BR/EN-US)
- Responsive design
- Toast notifications
- Route guards (student role only)
- Auto token refresh

## API Endpoints Used

All endpoints are prefixed with `http://localhost:4000/api/v1`:

- `POST /auth/login` - Login
- `POST /auth/logout` - Logout
- `POST /auth/refresh` - Refresh token
- `GET /auth/me` - Get current user
- `GET /students/profile` - Get student profile
- `PUT /students/profile` - Update profile
- `GET /students/dashboard` - Dashboard stats
- `GET /workout-plans` - List workout plans
- `GET /workout-plans/:id` - Get workout plan
- `GET /workout-logs` - List workout logs
- `POST /workout-logs` - Log workout
- `GET /body-assessments` - List assessments
- `GET /evolution-photos` - List photos
- `GET /goals` - List goals
- `GET /appointments` - List appointments
- `POST /appointments/change-request` - Request change
- `GET /messages` - List messages
- `POST /messages` - Send message

## Next Steps

1. **Test all features** with real backend data
2. **Add loading states** where needed
3. **Handle edge cases** (empty states, errors)
4. **Optimize performance** (lazy loading, memoization)
5. **Add unit tests** for critical functions
6. **E2E testing** with Playwright/Cypress
7. **Deploy to production** (Vercel/Netlify)

## Notes

- Students can only access their own data
- Most data is read-only except for:
  - Workout logs (create)
  - Messages (create)
  - Profile (update)
  - Appointment change requests (create)
- All dates/times are formatted according to locale
- Charts auto-update when data changes
- Toast notifications show success/error feedback
