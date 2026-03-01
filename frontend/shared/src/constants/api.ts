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

  // Media (Trainer)
  MEDIA_UPLOAD_URL: '/media/upload-url',
  MEDIA_CONFIRM: '/media/confirm-upload',
  MEDIA_DOWNLOAD: (id: string) => `/media/${id}/download`,
  MEDIA_DELETE: (id: string) => `/media/${id}`,
  STUDENT_MEDIA: (studentId: string) => `/students/${studentId}/media`,

  // Bioimpedance (Trainer)
  BIOIMPEDANCE_EXTRACT: '/bioimpedance/extract',
  BIOIMPEDANCE_IMPORTS: '/bioimpedance/imports',
  BIOIMPEDANCE_IMPORT: (id: string) => `/bioimpedance/imports/${id}`,
  BIOIMPEDANCE_APPLY: (id: string) => `/bioimpedance/imports/${id}/apply`,
  BIOIMPEDANCE_REJECT: (id: string) => `/bioimpedance/imports/${id}/reject`,

  // AI Analysis (Trainer)
  AI_ANALYZE_VISUAL: '/ai/analyze/visual',
  AI_ANALYZE_TRENDS: '/ai/analyze/trends',
  AI_ANALYZE_DOCUMENT: '/ai/analyze/document',
  AI_ANALYSES: '/ai/analyses',
  AI_ANALYSIS: (id: string) => `/ai/analyses/${id}`,
  AI_REVIEW: (id: string) => `/ai/analyses/${id}/review`,
  AI_SHARE: (id: string) => `/ai/analyses/${id}/share`,
  AI_USAGE: '/ai/usage',
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
