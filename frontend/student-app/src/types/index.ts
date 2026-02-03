// User & Auth Types
export interface User {
  id: string
  email: string
  name: string
  role: 'student' | 'trainer' | 'admin'
  locale: 'pt-BR' | 'en-US'
  avatarUrl?: string
  insertedAt: string
  updatedAt: string
}

export interface StudentProfile {
  id: string
  userId: string
  trainerId: string
  dateOfBirth: string
  phone: string
  emergencyContact?: string
  emergencyPhone?: string
  healthConditions?: string
  goals?: string
  notes?: string
  status: 'active' | 'inactive' | 'suspended'
  insertedAt: string
  updatedAt: string
  user?: User
}

export interface LoginCredentials {
  email: string
  password: string
}

export interface AuthTokens {
  accessToken: string
  refreshToken: string
}

export interface AuthResponse {
  user: User
  tokens: AuthTokens
}

// Workout Types
export interface Exercise {
  id: string
  name: string
  description?: string
  category: string
  muscleGroup: string
  equipment?: string
  videoUrl?: string
  imageUrl?: string
  instructions?: string
  insertedAt: string
  updatedAt: string
}

export interface WorkoutPlan {
  id: string
  trainerId: string
  studentId: string
  name: string
  description?: string
  startDate: string
  endDate?: string
  status: 'draft' | 'active' | 'completed' | 'archived'
  notes?: string
  insertedAt: string
  updatedAt: string
  exercises?: WorkoutExercise[]
}

export interface WorkoutExercise {
  id: string
  workoutPlanId: string
  exerciseId: string
  dayOfWeek: number
  orderIndex: number
  sets: number
  reps: string
  restSeconds?: number
  notes?: string
  insertedAt: string
  updatedAt: string
  exercise?: Exercise
}

export interface WorkoutLog {
  id: string
  studentId: string
  workoutExerciseId: string
  completedAt: string
  sets: number
  reps: number[]
  weight: number[]
  rpe?: number[]
  duration?: number
  notes?: string
  insertedAt: string
  updatedAt: string
  workoutExercise?: WorkoutExercise
}

export interface WorkoutLogInput {
  workoutExerciseId: string
  completedAt: string
  sets: number
  reps: number[]
  weight: number[]
  rpe?: number[]
  duration?: number
  notes?: string
}

// Evolution Types
export interface BodyAssessment {
  id: string
  studentId: string
  trainerId: string
  assessmentDate: string
  weight?: number
  height?: number
  bodyFat?: number
  muscleMass?: number
  visceralFat?: number
  bmr?: number
  measurements?: Record<string, number>
  notes?: string
  insertedAt: string
  updatedAt: string
}

export interface EvolutionPhoto {
  id: string
  studentId: string
  photoDate: string
  photoType: 'front' | 'side' | 'back' | 'other'
  photoUrl: string
  notes?: string
  insertedAt: string
  updatedAt: string
}

export interface Goal {
  id: string
  studentId: string
  goalType: 'weight' | 'body_fat' | 'muscle_mass' | 'measurement' | 'performance' | 'other'
  title: string
  description?: string
  targetValue?: number
  targetUnit?: string
  currentValue?: number
  startDate: string
  targetDate?: string
  completedAt?: string
  status: 'active' | 'completed' | 'abandoned'
  insertedAt: string
  updatedAt: string
}

// Schedule Types
export interface TimeSlot {
  id: string
  trainerId: string
  dayOfWeek: number
  startTime: string
  endTime: string
  isAvailable: boolean
  insertedAt: string
  updatedAt: string
}

export interface Appointment {
  id: string
  trainerId: string
  studentId: string
  timeSlotId: string
  appointmentDate: string
  startTime: string
  endTime: string
  status: 'scheduled' | 'completed' | 'cancelled' | 'no_show'
  notes?: string
  insertedAt: string
  updatedAt: string
  timeSlot?: TimeSlot
  student?: StudentProfile
}

export interface AppointmentChangeRequest {
  appointmentId: string
  reason: string
  preferredDate?: string
  preferredTime?: string
}

// Message Types
export interface Message {
  id: string
  senderId: string
  receiverId: string
  content: string
  readAt?: string
  insertedAt: string
  updatedAt: string
  sender?: User
  receiver?: User
}

export interface MessageInput {
  receiverId: string
  content: string
}

// API Response Types
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
}

// Stats & Dashboard
export interface DashboardStats {
  nextAppointment?: Appointment
  activeWorkoutPlan?: WorkoutPlan
  recentProgress?: {
    lastAssessment?: BodyAssessment
    lastWorkout?: WorkoutLog
    completedWorkoutsThisWeek: number
  }
  activeGoals?: Goal[]
  unreadMessages: number
}
