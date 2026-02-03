import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/LoginView.vue'),
    meta: { requiresAuth: false },
  },
  {
    path: '/',
    component: () => import('@/layouts/MainLayout.vue'),
    meta: { requiresAuth: true, requiresRole: 'student' },
    children: [
      {
        path: '',
        name: 'Dashboard',
        component: () => import('@/views/DashboardView.vue'),
      },
      {
        path: 'workouts',
        name: 'Workouts',
        component: () => import('@/views/WorkoutsView.vue'),
      },
      {
        path: 'workouts/:id',
        name: 'WorkoutDetail',
        component: () => import('@/views/WorkoutDetailView.vue'),
      },
      {
        path: 'evolution',
        name: 'Evolution',
        component: () => import('@/views/EvolutionView.vue'),
      },
      {
        path: 'schedule',
        name: 'Schedule',
        component: () => import('@/views/ScheduleView.vue'),
      },
      {
        path: 'messages',
        name: 'Messages',
        component: () => import('@/views/MessagesView.vue'),
      },
      {
        path: 'profile',
        name: 'Profile',
        component: () => import('@/views/ProfileView.vue'),
      },
    ],
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    redirect: '/',
  },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})

// Navigation guard
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()

  // Check if route requires authentication
  if (to.meta.requiresAuth) {
    // Initialize auth if not already done
    if (!authStore.user) {
      await authStore.checkAuth()
    }

    // Redirect to login if not authenticated
    if (!authStore.isAuthenticated) {
      next({ name: 'Login', query: { redirect: to.fullPath } })
      return
    }

    // Check role requirements
    if (to.meta.requiresRole && authStore.user?.role !== to.meta.requiresRole) {
      console.error('Access denied: incorrect role')
      next({ name: 'Login' })
      return
    }
  }

  // Redirect to dashboard if already authenticated and trying to access login
  if (to.name === 'Login' && authStore.isAuthenticated) {
    next({ name: 'Dashboard' })
    return
  }

  next()
})

export default router
