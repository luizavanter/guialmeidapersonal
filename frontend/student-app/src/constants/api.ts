export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:4000/api/v1'

export const API_ENDPOINTS = {
  // Auth (no prefix - public/any-authenticated scope)
  LOGIN: '/auth/login',
  REGISTER: '/auth/register',
  REFRESH: '/auth/refresh',
  LOGOUT: '/auth/logout',
  ME: '/auth/me',

  // Profile (student scope)
  PROFILE: '/student/profile',
  UPDATE_PROFILE: '/student/profile',

  // Workouts (student scope)
  WORKOUT_PLANS: '/student/workout-plans',
  WORKOUT_PLAN: (id: string) => `/student/workout-plans/${id}`,
  WORKOUT_LOGS: '/student/workout-logs',
  WORKOUT_LOG: (id: string) => `/student/workout-logs/${id}`,
  EXERCISES: '/student/exercises',

  // Evolution (student scope)
  BODY_ASSESSMENTS: '/student/body-assessments',
  EVOLUTION_PHOTOS: '/student/evolution-photos',
  GOALS: '/student/goals',
  GOAL: (id: string) => `/student/goals/${id}`,

  // Schedule (student scope)
  APPOINTMENTS: '/student/appointments',
  APPOINTMENT: (id: string) => `/student/appointments/${id}`,
  APPOINTMENT_CHANGE_REQUEST: '/student/appointments/change-request',

  // Messages (student scope)
  MESSAGES: '/student/messages',
  MESSAGE: (id: string) => `/student/messages/${id}`,
  MARK_READ: (id: string) => `/student/messages/${id}/read`,

  // Dashboard (student scope)
  DASHBOARD: '/student/dashboard',
} as const

export const STORAGE_KEYS = {
  ACCESS_TOKEN: 'ga_access_token',
  REFRESH_TOKEN: 'ga_refresh_token',
  USER: 'ga_user',
  LOCALE: 'ga_locale',
} as const
