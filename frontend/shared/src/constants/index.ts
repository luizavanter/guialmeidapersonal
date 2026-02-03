// API Configuration
export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:4000'
export const API_VERSION = 'v1'
export const API_TIMEOUT = 30000

// API Endpoints
export const API_ENDPOINTS = {
  // Auth
  LOGIN: '/auth/login',
  LOGOUT: '/auth/logout',
  REFRESH: '/auth/refresh',
  REGISTER: '/auth/register',

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

  // Workout Logs
  WORKOUT_LOGS: '/workout-logs',
  WORKOUT_LOG: (id: string) => `/workout-logs/${id}`,

  // Body Assessments
  BODY_ASSESSMENTS: '/body-assessments',
  BODY_ASSESSMENT: (id: string) => `/body-assessments/${id}`,

  // Evolution Photos
  EVOLUTION_PHOTOS: '/evolution-photos',
  EVOLUTION_PHOTO: (id: string) => `/evolution-photos/${id}`,

  // Goals
  GOALS: '/goals',
  GOAL: (id: string) => `/goals/${id}`,

  // Messages
  MESSAGES: '/messages',
  MESSAGE: (id: string) => `/messages/${id}`,

  // Notifications
  NOTIFICATIONS: '/notifications',
  NOTIFICATION: (id: string) => `/notifications/${id}`,

  // Plans
  PLANS: '/plans',
  PLAN: (id: string) => `/plans/${id}`,

  // Subscriptions
  SUBSCRIPTIONS: '/subscriptions',
  SUBSCRIPTION: (id: string) => `/subscriptions/${id}`,

  // Payments
  PAYMENTS: '/payments',
  PAYMENT: (id: string) => `/payments/${id}`,
} as const

// Storage Keys
export const STORAGE_KEYS = {
  ACCESS_TOKEN: 'ga_personal_access_token',
  REFRESH_TOKEN: 'ga_personal_refresh_token',
  USER: 'ga_personal_user',
  LOCALE: 'ga_personal_locale',
  THEME: 'ga_personal_theme',
} as const

// Colors (matching Tailwind config)
export const COLORS = {
  coal: '#0A0A0A',
  coalLight: '#1A1A1A',
  coalLighter: '#2A2A2A',
  lime: '#C4F53A',
  limeDark: '#A8D32E',
  ocean: '#0EA5E9',
  oceanDark: '#0C87BB',
  smoke: '#F5F5F0',
  smokeDark: '#E5E5E0',
} as const

// Chart colors using GA Personal palette
export const CHART_COLORS = {
  primary: COLORS.lime,
  secondary: COLORS.ocean,
  success: '#10B981',
  warning: '#F59E0B',
  danger: '#EF4444',
  info: COLORS.ocean,

  // Dataset colors
  datasets: [
    COLORS.lime,
    COLORS.ocean,
    '#8B5CF6',
    '#EC4899',
    '#F59E0B',
    '#10B981',
  ],

  // Background variants with opacity
  backgrounds: [
    'rgba(196, 245, 58, 0.2)',
    'rgba(14, 165, 233, 0.2)',
    'rgba(139, 92, 246, 0.2)',
    'rgba(236, 72, 153, 0.2)',
    'rgba(245, 158, 11, 0.2)',
    'rgba(16, 185, 129, 0.2)',
  ],

  // Border colors
  borders: [
    COLORS.lime,
    COLORS.ocean,
    '#8B5CF6',
    '#EC4899',
    '#F59E0B',
    '#10B981',
  ],
} as const

// Pagination defaults
export const PAGINATION = {
  DEFAULT_PAGE: 1,
  DEFAULT_PER_PAGE: 20,
  PER_PAGE_OPTIONS: [10, 20, 50, 100],
} as const

// Date formats
export const DATE_FORMATS = {
  DATE: 'DD/MM/YYYY',
  TIME: 'HH:mm',
  DATETIME: 'DD/MM/YYYY HH:mm',
  DATETIME_LONG: 'DD/MM/YYYY HH:mm:ss',
  ISO: 'YYYY-MM-DDTHH:mm:ss',
} as const

// Status options
export const STATUS_OPTIONS = {
  student: [
    { value: 'active', label: 'Active' },
    { value: 'inactive', label: 'Inactive' },
    { value: 'suspended', label: 'Suspended' },
  ],
  appointment: [
    { value: 'scheduled', label: 'Scheduled' },
    { value: 'confirmed', label: 'Confirmed' },
    { value: 'completed', label: 'Completed' },
    { value: 'cancelled', label: 'Cancelled' },
    { value: 'no_show', label: 'No Show' },
  ],
  workoutPlan: [
    { value: 'draft', label: 'Draft' },
    { value: 'active', label: 'Active' },
    { value: 'completed', label: 'Completed' },
    { value: 'archived', label: 'Archived' },
  ],
  goal: [
    { value: 'active', label: 'Active' },
    { value: 'achieved', label: 'Achieved' },
    { value: 'abandoned', label: 'Abandoned' },
  ],
  subscription: [
    { value: 'active', label: 'Active' },
    { value: 'expired', label: 'Expired' },
    { value: 'cancelled', label: 'Cancelled' },
    { value: 'pending', label: 'Pending' },
  ],
  payment: [
    { value: 'pending', label: 'Pending' },
    { value: 'paid', label: 'Paid' },
    { value: 'failed', label: 'Failed' },
    { value: 'refunded', label: 'Refunded' },
  ],
} as const

// Muscle groups
export const MUSCLE_GROUPS = [
  'Chest',
  'Back',
  'Shoulders',
  'Arms',
  'Legs',
  'Core',
  'Cardio',
  'Full Body',
] as const

// Equipment types
export const EQUIPMENT_TYPES = [
  'Barbell',
  'Dumbbell',
  'Machine',
  'Cable',
  'Bodyweight',
  'Resistance Band',
  'Kettlebell',
  'Other',
] as const

// Exercise difficulty
export const DIFFICULTY_LEVELS = [
  { value: 'beginner', label: 'Beginner' },
  { value: 'intermediate', label: 'Intermediate' },
  { value: 'advanced', label: 'Advanced' },
] as const

// Goal types
export const GOAL_TYPES = [
  { value: 'weight_loss', label: 'Weight Loss' },
  { value: 'muscle_gain', label: 'Muscle Gain' },
  { value: 'strength', label: 'Strength' },
  { value: 'endurance', label: 'Endurance' },
  { value: 'flexibility', label: 'Flexibility' },
  { value: 'other', label: 'Other' },
] as const

// Payment methods
export const PAYMENT_METHODS = [
  { value: 'cash', label: 'Cash' },
  { value: 'credit_card', label: 'Credit Card' },
  { value: 'debit_card', label: 'Debit Card' },
  { value: 'pix', label: 'PIX' },
  { value: 'bank_transfer', label: 'Bank Transfer' },
  { value: 'other', label: 'Other' },
] as const

// Notification types
export const NOTIFICATION_TYPES = [
  { value: 'appointment', label: 'Appointment' },
  { value: 'payment', label: 'Payment' },
  { value: 'message', label: 'Message' },
  { value: 'workout', label: 'Workout' },
  { value: 'assessment', label: 'Assessment' },
  { value: 'system', label: 'System' },
] as const

// Days of week
export const DAYS_OF_WEEK = [
  { value: 0, label: 'Sunday' },
  { value: 1, label: 'Monday' },
  { value: 2, label: 'Tuesday' },
  { value: 3, label: 'Wednesday' },
  { value: 4, label: 'Thursday' },
  { value: 5, label: 'Friday' },
  { value: 6, label: 'Saturday' },
] as const

// Regex patterns
export const REGEX = {
  EMAIL: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  PHONE: /^\+?[\d\s\-()]+$/,
  URL: /^https?:\/\/.+/,
  PASSWORD: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/,
} as const

// Validation messages
export const VALIDATION_MESSAGES = {
  REQUIRED: 'This field is required',
  EMAIL: 'Please enter a valid email',
  PHONE: 'Please enter a valid phone number',
  URL: 'Please enter a valid URL',
  PASSWORD: 'Password must be at least 8 characters with uppercase, lowercase, and number',
  MIN: (min: number) => `Minimum value is ${min}`,
  MAX: (max: number) => `Maximum value is ${max}`,
  MIN_LENGTH: (min: number) => `Minimum length is ${min} characters`,
  MAX_LENGTH: (max: number) => `Maximum length is ${max} characters`,
} as const
