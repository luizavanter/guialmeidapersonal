export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:4000/api/v1'

export const API_ENDPOINTS = {
  // Auth
  LOGIN: '/auth/login',
  REGISTER: '/auth/register',
  REFRESH: '/auth/refresh',
  LOGOUT: '/auth/logout',
  ME: '/auth/me',

  // Profile
  PROFILE: '/students/profile',
  UPDATE_PROFILE: '/students/profile',

  // Workouts
  WORKOUT_PLANS: '/workout-plans',
  WORKOUT_PLAN: (id: string) => `/workout-plans/${id}`,
  WORKOUT_LOGS: '/workout-logs',
  WORKOUT_LOG: (id: string) => `/workout-logs/${id}`,
  EXERCISES: '/exercises',

  // Evolution
  BODY_ASSESSMENTS: '/body-assessments',
  EVOLUTION_PHOTOS: '/evolution-photos',
  GOALS: '/goals',
  GOAL: (id: string) => `/goals/${id}`,

  // Schedule
  APPOINTMENTS: '/appointments',
  APPOINTMENT: (id: string) => `/appointments/${id}`,
  APPOINTMENT_CHANGE_REQUEST: '/appointments/change-request',

  // Messages
  MESSAGES: '/messages',
  MESSAGE: (id: string) => `/messages/${id}`,
  MARK_READ: (id: string) => `/messages/${id}/read`,

  // Dashboard
  DASHBOARD: '/students/dashboard',
} as const

export const STORAGE_KEYS = {
  ACCESS_TOKEN: 'ga_access_token',
  REFRESH_TOKEN: 'ga_refresh_token',
  USER: 'ga_user',
  LOCALE: 'ga_locale',
} as const
