import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { useAuth } from '@ga-personal/shared'

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/auth/LoginView.vue'),
    meta: { requiresAuth: false, layout: 'auth' },
  },
  {
    path: '/',
    component: () => import('@/components/layout/MainLayout.vue'),
    meta: { requiresAuth: true, requiresTrainer: true },
    children: [
      {
        path: '',
        name: 'dashboard',
        component: () => import('@/views/dashboard/DashboardView.vue'),
      },
      {
        path: 'students',
        name: 'students',
        component: () => import('@/views/students/StudentsView.vue'),
      },
      {
        path: 'students/:id',
        name: 'student-detail',
        component: () => import('@/views/students/StudentDetailView.vue'),
      },
      {
        path: 'agenda',
        name: 'agenda',
        component: () => import('@/views/appointments/AgendaView.vue'),
      },
      {
        path: 'workouts',
        name: 'workouts',
        component: () => import('@/views/workouts/WorkoutsView.vue'),
      },
      {
        path: 'workouts/exercises',
        name: 'exercises',
        component: () => import('@/views/workouts/ExercisesView.vue'),
      },
      {
        path: 'workouts/plans',
        name: 'workout-plans',
        component: () => import('@/views/workouts/WorkoutPlansView.vue'),
      },
      {
        path: 'workouts/plans/:id',
        name: 'workout-plan-detail',
        component: () => import('@/views/workouts/WorkoutPlanDetailView.vue'),
      },
      {
        path: 'evolution/:studentId',
        name: 'evolution',
        component: () => import('@/views/evolution/EvolutionView.vue'),
      },
      {
        path: 'finance',
        name: 'finance',
        component: () => import('@/views/finance/FinanceView.vue'),
      },
      {
        path: 'finance/payments',
        name: 'payments',
        component: () => import('@/views/finance/PaymentsView.vue'),
      },
      {
        path: 'finance/subscriptions',
        name: 'subscriptions',
        component: () => import('@/views/finance/SubscriptionsView.vue'),
      },
      {
        path: 'finance/plans',
        name: 'plans',
        component: () => import('@/views/finance/PlansView.vue'),
      },
      {
        path: 'messages',
        name: 'messages',
        component: () => import('@/views/messages/MessagesView.vue'),
      },
      {
        path: 'settings',
        name: 'settings',
        component: () => import('@/views/settings/SettingsView.vue'),
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})

// Navigation guards
router.beforeEach((to, from, next) => {
  const { checkAuth, user } = useAuth()

  // Check if route requires authentication
  if (to.meta.requiresAuth) {
    if (!checkAuth()) {
      next({ name: 'login', query: { redirect: to.fullPath } })
      return
    }

    // Check if route requires trainer role
    if (to.meta.requiresTrainer && user.value?.role !== 'trainer') {
      next({ name: 'login' })
      return
    }
  }

  // Redirect to dashboard if already logged in and trying to access login
  if (to.name === 'login' && checkAuth()) {
    next({ name: 'dashboard' })
    return
  }

  next()
})

export default router
