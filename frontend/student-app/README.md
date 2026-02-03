# GA Personal - Student Portal

Vue 3 Student Portal application for GA Personal training management system.

## Features

- **Dashboard**: Overview of next appointment, current workout, recent progress, and active goals
- **My Workouts**: View assigned workout plans and log completed exercises with weight/reps/RPE
- **Evolution**: View body assessments, evolution photos, goal progress with charts
- **Schedule**: View appointments and request changes
- **Messages**: Chat with trainer
- **Profile**: Edit personal information and emergency contact

## Tech Stack

- Vue 3 with Composition API
- TypeScript
- Vite
- Pinia (state management)
- Vue Router
- Vue I18n (bilingual support: PT-BR/EN-US)
- Tailwind CSS
- Chart.js (progress tracking)
- Axios (API client)

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file:
```bash
cp .env.example .env
```

3. Start development server:
```bash
npm run dev
```

The app will run on http://localhost:3002

## Project Structure

```
src/
├── components/       # UI components
│   └── ui/          # Reusable UI components (Button, Input, Card, Modal, Toast)
├── composables/     # Vue composables (useAuth, useToast)
├── constants/       # API endpoints, storage keys
├── i18n/           # Internationalization (PT-BR, EN-US)
├── layouts/        # Layout components (MainLayout)
├── lib/            # Core libraries (API client)
├── router/         # Vue Router configuration
├── stores/         # Pinia stores
│   ├── auth.ts
│   ├── workouts.ts
│   ├── evolution.ts
│   ├── schedule.ts
│   ├── messages.ts
│   ├── profile.ts
│   └── dashboard.ts
├── types/          # TypeScript type definitions
├── utils/          # Utility functions (date, format, validation)
├── views/          # Page components
│   ├── LoginView.vue
│   ├── DashboardView.vue
│   ├── WorkoutsView.vue
│   ├── WorkoutDetailView.vue
│   ├── EvolutionView.vue
│   ├── ScheduleView.vue
│   ├── MessagesView.vue
│   └── ProfileView.vue
├── App.vue
├── main.ts
└── style.css
```

## Key Features

### Authentication
- JWT-based authentication with auto-refresh
- Role-based access control (students only)
- Route guards

### Workout Logging
- View assigned workout plans by day
- Log exercises with:
  - Sets and reps per set
  - Weight (kg) per set
  - RPE (Rate of Perceived Exertion) per set
  - Duration
  - Notes
- Form validation

### Progress Tracking
- Body assessment history
- Weight and body fat charts
- Evolution photo gallery
- Goal tracking with progress bars

### Responsive Design
- Mobile-first approach
- Collapsible sidebar on mobile
- Touch-friendly interface

### Bilingual Support
- Full Portuguese (PT-BR) and English (EN-US) support
- Language persisted in localStorage
- All UI text translated

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run type-check` - Run TypeScript type checking
- `npm run lint` - Run ESLint

## API Integration

The app connects to the Phoenix backend at `http://localhost:4000/api/v1` by default.

All API calls include:
- JWT authentication header
- Automatic token refresh on 401
- Error handling
- Loading states

## Design System

- **Colors**:
  - Coal (#0A0A0A) - Background
  - Lime (#C4F53A) - Primary actions
  - Ocean (#0EA5E9) - Secondary/links
  - Smoke (#F5F5F0) - Text/cards

- **Typography**:
  - Display: Bebas Neue
  - Body: Outfit
  - Mono: JetBrains Mono

## License

Private - GA Personal
