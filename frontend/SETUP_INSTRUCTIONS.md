# GA Personal Frontend - Setup Instructions

## Quick Start

### 1. Install Dependencies

```bash
# Install shared package dependencies
cd /Users/luizpenha/guipersonal/frontend/shared
npm install
npm run build

# Install trainer app dependencies
cd /Users/luizpenha/guipersonal/frontend/trainer-app
npm install
```

### 2. Start Development Server

```bash
cd /Users/luizpenha/guipersonal/frontend/trainer-app
npm run dev
```

The app will be available at: **http://localhost:3001**

### 3. Backend API

Make sure the Phoenix backend is running at: **http://localhost:4000**

---

## File Structure Verification

### Shared Package Files (`/frontend/shared/src/`)
- [x] `index.ts`
- [x] `types/index.ts`
- [x] `constants/api.ts`
- [x] `constants/colors.ts`
- [x] `utils/date.ts`
- [x] `utils/validators.ts`
- [x] `utils/formatters.ts`
- [x] `composables/useApi.ts`
- [x] `composables/useAuth.ts`
- [x] `composables/usePagination.ts`
- [x] `composables/useToast.ts`
- [x] `i18n/index.ts`
- [x] `i18n/locales/pt-BR.json`
- [x] `i18n/locales/en-US.json`

### Trainer App Files (`/frontend/trainer-app/src/`)
- [x] `main.ts`
- [x] `App.vue`
- [x] `env.d.ts`
- [x] `assets/main.css`
- [x] `router/index.ts`
- [x] `stores/studentsStore.ts`
- [x] `stores/appointmentsStore.ts`
- [x] `stores/workoutsStore.ts`
- [x] `stores/financeStore.ts`
- [x] `components/layout/MainLayout.vue`
- [x] `components/layout/Sidebar.vue`
- [x] `components/layout/Topbar.vue`
- [x] `views/auth/LoginView.vue`
- [x] `views/dashboard/DashboardView.vue`
- [x] `views/students/StudentsView.vue`
- [x] `views/students/StudentDetailView.vue`
- [x] `views/appointments/AgendaView.vue`
- [x] `views/workouts/WorkoutsView.vue`
- [x] `views/workouts/ExercisesView.vue`
- [x] `views/workouts/WorkoutPlansView.vue`
- [x] `views/workouts/WorkoutPlanDetailView.vue`
- [x] `views/evolution/EvolutionView.vue`
- [x] `views/finance/FinanceView.vue`
- [x] `views/finance/PaymentsView.vue`
- [x] `views/finance/SubscriptionsView.vue`
- [x] `views/finance/PlansView.vue`
- [x] `views/messages/MessagesView.vue`
- [x] `views/settings/SettingsView.vue`

### Configuration Files
- [x] `vite.config.ts`
- [x] `tsconfig.json`
- [x] `tsconfig.node.json`
- [x] `tailwind.config.js`
- [x] `postcss.config.js`
- [x] `.env`
- [x] `.gitignore`
- [x] `index.html`
- [x] `package.json`

---

## Environment Variables

File: `/frontend/trainer-app/.env`

```
VITE_API_URL=http://localhost:4000/api/v1
VITE_APP_NAME=GA Personal - Trainer Dashboard
```

---

## Default Test Credentials (Backend Required)

After backend is set up with seeds, use:
- **Email:** trainer@example.com
- **Password:** [as defined in backend seeds]
- **Role:** trainer

---

## Available NPM Scripts

### Trainer App
```bash
npm run dev          # Start dev server on port 3001
npm run build        # Build for production
npm run preview      # Preview production build
npm run type-check   # TypeScript type checking
```

### Shared Package
```bash
npm run dev          # Development mode
npm run build        # Build library
npm run type-check   # TypeScript checking
```

---

## Browser Requirements

- Modern browser with ES2020 support
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

---

## Development Workflow

1. **Start Backend API** (Phoenix)
   ```bash
   cd /path/to/backend
   mix phx.server
   ```

2. **Start Frontend** (Vue)
   ```bash
   cd /Users/luizpenha/guipersonal/frontend/trainer-app
   npm run dev
   ```

3. **Access Application**
   - Frontend: http://localhost:3001
   - Backend API: http://localhost:4000/api/v1

---

## Common Issues & Solutions

### Issue: Module not found '@ga-personal/shared'
**Solution:**
```bash
cd /Users/luizpenha/guipersonal/frontend/shared
npm install
npm run build
cd ../trainer-app
npm install
```

### Issue: Port 3001 already in use
**Solution:**
```bash
# Kill process on port 3001
lsof -ti:3001 | xargs kill -9

# Or change port in vite.config.ts
```

### Issue: API connection refused
**Solution:**
- Ensure Phoenix backend is running on port 4000
- Check `.env` file has correct API URL
- Verify CORS settings on backend

### Issue: TypeScript errors
**Solution:**
```bash
npm run type-check
# Fix any type errors reported
```

---

## Feature Testing Checklist

### Authentication
- [ ] Login with valid credentials
- [ ] Error display for invalid credentials
- [ ] Remember me functionality
- [ ] Auto-redirect after login
- [ ] Logout functionality
- [ ] Token refresh on 401

### Dashboard
- [ ] Welcome message displays
- [ ] Stats cards show correct data
- [ ] Today's appointments list
- [ ] Pending payments widget
- [ ] Active students widget
- [ ] Click-through navigation works

### Students
- [ ] List all students
- [ ] Search functionality
- [ ] Status filter
- [ ] View student detail
- [ ] Create new student (if backend ready)
- [ ] Edit student (if backend ready)
- [ ] Status badges display correctly

### Agenda
- [ ] View appointments
- [ ] Switch day/week/month views
- [ ] Navigate dates
- [ ] See appointment details
- [ ] Status badges

### Workouts
- [ ] View exercise library
- [ ] Search exercises
- [ ] View workout plans
- [ ] View plan details
- [ ] See exercises in plan

### Finance
- [ ] View revenue stats
- [ ] List payments
- [ ] Filter by status
- [ ] View subscriptions
- [ ] View pricing plans
- [ ] Currency formatting

### Messages
- [ ] View inbox structure
- [ ] Compose button
- [ ] Message layout

### Settings
- [ ] View profile info
- [ ] Switch language (PT-BR ↔ EN-US)
- [ ] Language persists on reload

---

## Deployment Checklist

### Pre-deployment
- [ ] All dependencies installed
- [ ] TypeScript checks pass
- [ ] Build succeeds
- [ ] Environment variables set for production
- [ ] API URL points to production backend

### Build
```bash
npm run build
```

### Deploy
- Output in `dist/` directory
- Deploy to static hosting (Vercel, Netlify, etc.)
- Set environment variables in hosting platform

---

## Performance Metrics Target

- Time to Interactive: < 3s
- First Contentful Paint: < 1.5s
- Bundle Size: < 500KB (gzipped)
- Lighthouse Score: > 90

---

## Support

For issues or questions:
1. Check this documentation
2. Review IMPLEMENTATION_SUMMARY.md
3. Check README.md in trainer-app directory
4. Review component code comments

---

## Success Indicators

✅ App runs on http://localhost:3001
✅ Login page displays correctly
✅ Can authenticate with test credentials
✅ Dashboard loads with sample data
✅ All navigation links work
✅ Language switcher functions
✅ API calls succeed (with backend running)
✅ No console errors
✅ TypeScript compiles without errors
✅ Responsive design works on mobile/tablet/desktop

---

**Last Updated:** 2026-02-03
**Status:** ✅ Ready for development
