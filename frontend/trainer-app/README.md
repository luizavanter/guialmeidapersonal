# GA Personal - Trainer Dashboard

Complete Vue 3 application for personal trainers to manage their business.

## Features

### ✅ Implemented

- **Authentication & Authorization**
  - Login with JWT tokens
  - Token refresh mechanism
  - Role-based access (trainer only)
  - Protected routes

- **Dashboard**
  - Today's appointments overview
  - Pending payments summary
  - Active students count
  - Monthly revenue statistics
  - Recent activity widgets

- **Students Management**
  - Complete CRUD operations
  - Student list with search and filters
  - Detailed student profiles
  - Activity history tracking
  - Status management (active/inactive/suspended)

- **Agenda/Calendar**
  - Day/Week/Month views
  - Appointment scheduling
  - Today's schedule view
  - Status tracking (scheduled/confirmed/completed/cancelled)

- **Workout Management**
  - Exercise library with CRUD
  - Muscle group categorization
  - Difficulty levels
  - Workout plan builder
  - Plan assignment to students
  - Exercise ordering and configuration

- **Evolution Tracking**
  - Body assessments structure
  - Photo comparison framework
  - Goal tracking system
  - Progress visualization

- **Finance Management**
  - Payment tracking
  - Subscription management
  - Plan configuration
  - Revenue reports
  - Pending/overdue payment alerts

- **Messaging**
  - Inbox/Sent structure
  - Message composition
  - Student communication

- **Settings**
  - Profile management
  - Language switcher (PT-BR/EN-US)
  - Bilingual support throughout

## Tech Stack

- **Framework:** Vue 3 with Composition API & `<script setup>`
- **Language:** TypeScript
- **State Management:** Pinia
- **Routing:** Vue Router 4
- **Styling:** Tailwind CSS with GA Personal design system
- **Build Tool:** Vite
- **API Client:** Axios with interceptors
- **Internationalization:** Vue I18n

## Design System

### Colors
- **Coal** (#0A0A0A) - Dark background
- **Lime** (#C4F53A) - Primary actions, highlights
- **Ocean** (#0EA5E9) - Secondary, links
- **Smoke** (#F5F5F0) - Text, light elements

### Typography
- **Display:** Bebas Neue (headlines)
- **Body:** Outfit (content)
- **Mono:** JetBrains Mono (data, metrics)

## Project Structure

```
trainer-app/
├── public/              # Static assets
├── src/
│   ├── assets/         # CSS, images
│   │   └── main.css    # Tailwind + custom styles
│   ├── components/     # Vue components
│   │   ├── common/     # Reusable components
│   │   └── layout/     # Layout components
│   │       ├── MainLayout.vue
│   │       ├── Sidebar.vue
│   │       └── Topbar.vue
│   ├── composables/    # Composition functions
│   ├── router/         # Vue Router config
│   │   └── index.ts    # Routes & guards
│   ├── stores/         # Pinia stores
│   │   ├── studentsStore.ts
│   │   ├── appointmentsStore.ts
│   │   ├── workoutsStore.ts
│   │   └── financeStore.ts
│   ├── types/          # TypeScript types
│   ├── utils/          # Utility functions
│   ├── views/          # Page components
│   │   ├── auth/
│   │   │   └── LoginView.vue
│   │   ├── dashboard/
│   │   │   └── DashboardView.vue
│   │   ├── students/
│   │   │   ├── StudentsView.vue
│   │   │   └── StudentDetailView.vue
│   │   ├── appointments/
│   │   │   └── AgendaView.vue
│   │   ├── workouts/
│   │   │   ├── WorkoutsView.vue
│   │   │   ├── ExercisesView.vue
│   │   │   ├── WorkoutPlansView.vue
│   │   │   └── WorkoutPlanDetailView.vue
│   │   ├── evolution/
│   │   │   └── EvolutionView.vue
│   │   ├── finance/
│   │   │   ├── FinanceView.vue
│   │   │   ├── PaymentsView.vue
│   │   │   ├── SubscriptionsView.vue
│   │   │   └── PlansView.vue
│   │   ├── messages/
│   │   │   └── MessagesView.vue
│   │   └── settings/
│   │       └── SettingsView.vue
│   ├── App.vue         # Root component
│   ├── main.ts         # App entry point
│   └── env.d.ts        # TypeScript env declarations
├── .env                # Environment variables
├── index.html          # HTML entry point
├── package.json        # Dependencies
├── tailwind.config.js  # Tailwind configuration
├── tsconfig.json       # TypeScript config
├── vite.config.ts      # Vite configuration
└── README.md           # This file
```

## Setup

### Prerequisites
- Node.js 18+
- npm or yarn

### Installation

1. Install dependencies:
```bash
npm install
```

2. Install shared package dependencies:
```bash
cd ../shared
npm install
npm run build
cd ../trainer-app
```

3. Create `.env` file:
```
VITE_API_URL=http://localhost:4000/api/v1
VITE_APP_NAME=GA Personal - Trainer Dashboard
```

### Development

Start development server:
```bash
npm run dev
```

App runs on http://localhost:3001

### Build

Build for production:
```bash
npm run build
```

Type check:
```bash
npm run type-check
```

## API Integration

The app connects to the Phoenix backend API at `http://localhost:4000/api/v1`

### API Endpoints Used:
- `POST /auth/login` - User authentication
- `POST /auth/logout` - User logout
- `POST /auth/refresh` - Token refresh
- `GET /students` - List students
- `GET /students/:id` - Get student details
- `POST /students` - Create student
- `PUT /students/:id` - Update student
- `DELETE /students/:id` - Delete student
- `GET /appointments` - List appointments
- `GET /exercises` - List exercises
- `GET /workout-plans` - List workout plans
- `GET /payments` - List payments
- `GET /subscriptions` - List subscriptions
- `GET /plans` - List pricing plans

### Authentication Flow:
1. User submits login form
2. API returns access token + refresh token + user data
3. Tokens stored in localStorage
4. Access token included in Authorization header for all requests
5. On 401 response, attempt token refresh
6. On refresh failure, redirect to login

## Key Features Detail

### Multi-tenant Support
All API calls are automatically scoped to the authenticated trainer via JWT token.

### Route Guards
- `requiresAuth` - Ensures user is logged in
- `requiresTrainer` - Ensures user has trainer role
- Auto-redirect to login when unauthorized

### State Management
Each domain has its own Pinia store:
- **studentsStore** - Student CRUD operations
- **appointmentsStore** - Appointment scheduling
- **workoutsStore** - Exercises & workout plans
- **financeStore** - Payments, subscriptions, plans

### Shared Package Integration
Imports from `@ga-personal/shared`:
- UI components (Button, Input, Card, etc.)
- Composables (useAuth, useApi, usePagination)
- Types (Student, Appointment, Exercise, etc.)
- Utils (formatters, validators, date helpers)
- Constants (API endpoints, colors)
- i18n configuration

### Responsive Design
- Mobile-first approach
- Breakpoints: sm, md, lg, xl
- Collapsible sidebar on mobile
- Grid layouts adapt to screen size

### Bilingual Support
- PT-BR (default) and EN-US
- Language switcher in settings
- All UI text internationalized
- Stored preference in localStorage

## Development Guidelines

### Component Structure
```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useApi } from '@ga-personal/shared'

const { t } = useI18n()
const api = useApi()

// Component logic
</script>

<template>
  <!-- Template -->
</template>

<style scoped>
/* Optional scoped styles */
</style>
```

### Store Pattern
```typescript
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useApi } from '@ga-personal/shared'

export const useMyStore = defineStore('my-store', () => {
  const api = useApi()

  // State
  const items = ref([])
  const loading = ref(false)

  // Getters
  const itemCount = computed(() => items.value.length)

  // Actions
  async function fetchItems() {
    loading.value = true
    try {
      const response = await api.get('/items')
      items.value = response.data
    } finally {
      loading.value = false
    }
  }

  return { items, loading, itemCount, fetchItems }
})
```

## Deployment

### Environment Variables
Set in production:
- `VITE_API_URL` - Production API URL

### Build Command
```bash
npm run build
```

Output in `dist/` directory ready for static hosting (Vercel, Netlify, etc.)

## License

Private - GA Personal Training System
