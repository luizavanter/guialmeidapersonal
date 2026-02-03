// API Configuration and Endpoints

// API Base URL - determined at runtime based on environment
// Use getter to ensure runtime evaluation
let _apiBaseUrl: string | null = null

export const getApiBaseUrl = (): string => {
  if (_apiBaseUrl !== null) return _apiBaseUrl

  // Check for env variable first (Vite dev mode)
  const envUrl = (import.meta as any)?.env?.VITE_API_URL
  if (envUrl) {
    _apiBaseUrl = `${envUrl}/api/v1`
    return _apiBaseUrl
  }

  // Check if running on localhost (development)
  if (typeof window !== 'undefined' && window.location?.hostname === 'localhost') {
    _apiBaseUrl = 'http://localhost:4000/api/v1'
    return _apiBaseUrl
  }

  // Default to production
  _apiBaseUrl = 'https://api.guialmeidapersonal.esp.br/api/v1'
  return _apiBaseUrl
}

// For backwards compatibility, export as constant that resolves at first access
export const API_BASE_URL = 'https://api.guialmeidapersonal.esp.br/api/v1'

export const API_ENDPOINTS = {
  // Auth
  LOGIN: '/auth/login',
  REGISTER: '/auth/register',
  REFRESH: '/auth/refresh',
  LOGOUT: '/auth/logout',

  // Students
  STUDENTS: '/students',
  STUDENT: (id: string) => `/students/${id}`,

  // Appointments
  APPOINTMENTS: '/appointments',
  APPOINTMENT: (id: string) => `/appointments/${id}`,

  // Exercises
  EXERCISES: '/exercises',
  EXERCISE: (id: string) => `/exercises/${id}`,

  // Workout Plans
  WORKOUT_PLANS: '/workout-plans',
  WORKOUT_PLAN: (id: string) => `/workout-plans/${id}`,

  // Body Assessments
  BODY_ASSESSMENTS: '/body-assessments',
  BODY_ASSESSMENT: (id: string) => `/body-assessments/${id}`,

  // Evolution Photos
  EVOLUTION_PHOTOS: '/evolution-photos',
  EVOLUTION_PHOTO: (id: string) => `/evolution-photos/${id}`,

  // Goals
  GOALS: '/goals',
  GOAL: (id: string) => `/goals/${id}`,

  // Plans
  PLANS: '/plans',
  PLAN: (id: string) => `/plans/${id}`,

  // Subscriptions
  SUBSCRIPTIONS: '/subscriptions',
  SUBSCRIPTION: (id: string) => `/subscriptions/${id}`,

  // Payments
  PAYMENTS: '/payments',
  PAYMENT: (id: string) => `/payments/${id}`,

  // Messages
  MESSAGES: '/messages',
  MESSAGE: (id: string) => `/messages/${id}`,
}

export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  NO_CONTENT: 204,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  UNPROCESSABLE_ENTITY: 422,
  INTERNAL_SERVER_ERROR: 500,
}
