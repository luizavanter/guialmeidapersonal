// Core types for GA Personal system

export interface User {
  id: string
  email: string
  role: 'trainer' | 'student' | 'admin'
  firstName: string
  lastName: string
  phone?: string
  avatarUrl?: string
  locale: 'en-US' | 'pt-BR'
  createdAt: string
  updatedAt: string
}

export interface Student {
  id: string
  userId: string
  trainerId: string
  status: 'active' | 'inactive' | 'suspended'
  emergencyContact?: string
  emergencyPhone?: string
  medicalNotes?: string
  goals?: string
  createdAt: string
  updatedAt: string
  user?: User
}

export interface Appointment {
  id: string
  trainerId: string
  studentId: string
  startTime: string
  endTime: string
  scheduledAt?: string
  durationMinutes?: number
  appointmentType?: string
  location?: string
  status: 'scheduled' | 'confirmed' | 'completed' | 'cancelled' | 'no_show'
  notes?: string
  createdAt: string
  updatedAt: string
  student?: Student
}

export interface Exercise {
  id: string
  name: string
  description?: string
  muscleGroup: string
  equipment?: string
  videoUrl?: string
  thumbnailUrl?: string
  difficulty: 'beginner' | 'intermediate' | 'advanced'
  createdAt: string
  updatedAt: string
}

export interface WorkoutPlan {
  id: string
  trainerId: string
  studentId?: string
  name: string
  description?: string
  durationWeeks?: number
  status: 'draft' | 'active' | 'completed' | 'archived'
  createdAt: string
  updatedAt: string
  exercises?: WorkoutExercise[]
}

export interface WorkoutExercise {
  id: string
  workoutPlanId: string
  exerciseId: string
  dayOfWeek: number
  sets: number
  reps?: string
  duration?: number
  rest?: number
  notes?: string
  order: number
  exercise?: Exercise
}

export interface WorkoutLog {
  id: string
  studentId: string
  workoutPlanId: string
  exerciseId: string
  completedAt: string
  sets: number
  reps?: string
  weight?: number
  duration?: number
  notes?: string
  rating?: number
}

export interface BodyAssessment {
  id: string
  studentId: string
  assessedAt: string
  weight?: number
  height?: number
  bodyFat?: number
  muscleMass?: number
  bmi?: number
  chest?: number
  waist?: number
  hips?: number
  leftArm?: number
  rightArm?: number
  leftThigh?: number
  rightThigh?: number
  leftCalf?: number
  rightCalf?: number
  notes?: string
  createdAt: string
  updatedAt: string
}

export interface EvolutionPhoto {
  id: string
  studentId: string
  photoUrl: string
  photoType: 'front' | 'back' | 'side' | 'other'
  takenAt: string
  notes?: string
  createdAt: string
  updatedAt: string
}

export interface Goal {
  id: string
  studentId: string
  type: 'weight_loss' | 'muscle_gain' | 'strength' | 'endurance' | 'flexibility' | 'other'
  targetValue?: number
  currentValue?: number
  unit?: string
  deadline?: string
  status: 'active' | 'achieved' | 'abandoned'
  notes?: string
  createdAt: string
  updatedAt: string
}

export interface Message {
  id: string
  senderId: string
  receiverId: string
  content: string
  read: boolean
  readAt?: string
  createdAt: string
  updatedAt: string
  sender?: User
  receiver?: User
}

export interface Notification {
  id: string
  userId: string
  type: 'appointment' | 'payment' | 'message' | 'workout' | 'assessment' | 'system'
  title: string
  content: string
  read: boolean
  readAt?: string
  actionUrl?: string
  createdAt: string
  updatedAt: string
}

export interface Plan {
  id: string
  name: string
  description?: string
  price: number
  currency: string
  duration: number
  durationType: 'days' | 'weeks' | 'months'
  sessionsPerWeek?: number
  features?: string[]
  active: boolean
  createdAt: string
  updatedAt: string
}

export interface Subscription {
  id: string
  studentId: string
  planId: string
  startDate: string
  endDate: string
  status: 'active' | 'expired' | 'cancelled' | 'pending'
  autoRenew: boolean
  createdAt: string
  updatedAt: string
  plan?: Plan
  student?: Student
}

export interface Payment {
  id: string
  subscriptionId: string
  amount: number
  amountCents?: number
  currency: string
  status: 'pending' | 'paid' | 'failed' | 'refunded'
  method?: 'cash' | 'credit_card' | 'debit_card' | 'pix' | 'bank_transfer' | 'other'
  paidAt?: string
  dueDate?: string
  notes?: string
  createdAt: string
  updatedAt: string
  subscription?: Subscription
  student?: any
}

// API Response types
export interface ApiResponse<T> {
  data: T
  meta?: {
    page?: number
    perPage?: number
    total?: number
    totalPages?: number
  }
  errors?: ApiError[]
}

export interface ApiError {
  field?: string
  message: string
  code?: string
}

// Pagination
export interface PaginationParams {
  page?: number
  perPage?: number
  sortBy?: string
  sortOrder?: 'asc' | 'desc'
}

export interface PaginationMeta {
  page: number
  perPage: number
  total: number
  totalPages: number
}

// Auth
export interface LoginCredentials {
  email: string
  password: string
  rememberMe?: boolean
}

export interface AuthTokens {
  accessToken: string
  refreshToken: string
  expiresIn: number
}

export interface AuthResponse {
  user: User
  tokens: AuthTokens
}

// Chart types
export interface ChartDataPoint {
  x: string | number | Date
  y: number
}

export interface ChartData {
  labels: string[]
  datasets: ChartDataset[]
}

export interface ChartDataset {
  label: string
  data: number[]
  backgroundColor?: string | string[]
  borderColor?: string | string[]
  borderWidth?: number
}

// Form types
export interface FormField {
  name: string
  label: string
  type: 'text' | 'email' | 'password' | 'number' | 'date' | 'select' | 'textarea' | 'checkbox' | 'radio'
  value?: any
  placeholder?: string
  required?: boolean
  disabled?: boolean
  options?: SelectOption[]
  validation?: ValidationRule[]
}

export interface SelectOption {
  label: string
  value: any
  disabled?: boolean
}

export interface ValidationRule {
  type: 'required' | 'email' | 'min' | 'max' | 'minLength' | 'maxLength' | 'pattern' | 'custom'
  value?: any
  message?: string
  validator?: (value: any) => boolean | Promise<boolean>
}

// Filter types
export interface FilterConfig {
  field: string
  label: string
  type: 'text' | 'select' | 'date' | 'daterange' | 'number'
  options?: SelectOption[]
}

export interface FilterValue {
  field: string
  operator: 'eq' | 'ne' | 'gt' | 'gte' | 'lt' | 'lte' | 'contains' | 'in'
  value: any
}

// Table types
export interface TableColumn<T = any> {
  key: keyof T | string
  label: string
  sortable?: boolean
  width?: string
  align?: 'left' | 'center' | 'right'
  format?: (value: any, row: T) => string
  render?: (value: any, row: T) => any
}

export interface SortConfig {
  key: string
  order: 'asc' | 'desc'
}
