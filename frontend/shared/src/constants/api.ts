// API Configuration and Endpoints

export const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:4000/api/v1'

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
