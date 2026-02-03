import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '@/lib/api'
import { API_ENDPOINTS } from '@/constants/api'
import type { WorkoutPlan, WorkoutLog, WorkoutLogInput, Exercise } from '@/types'

export const useWorkoutsStore = defineStore('workouts', () => {
  const workoutPlans = ref<WorkoutPlan[]>([])
  const currentPlan = ref<WorkoutPlan | null>(null)
  const workoutLogs = ref<WorkoutLog[]>([])
  const exercises = ref<Exercise[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  const fetchWorkoutPlans = async () => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.get<WorkoutPlan[]>(API_ENDPOINTS.WORKOUT_PLANS, {
        status: 'active',
      })
      workoutPlans.value = response.data

      // Set current plan to the first active one
      if (workoutPlans.value.length > 0) {
        currentPlan.value = workoutPlans.value[0]
      }
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to fetch workout plans'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const fetchWorkoutPlan = async (id: string) => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.get<WorkoutPlan>(API_ENDPOINTS.WORKOUT_PLAN(id))
      currentPlan.value = response.data
      return response.data
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to fetch workout plan'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const fetchWorkoutLogs = async (params?: { startDate?: string; endDate?: string }) => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.get<WorkoutLog[]>(API_ENDPOINTS.WORKOUT_LOGS, params)
      workoutLogs.value = response.data
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to fetch workout logs'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const logWorkout = async (log: WorkoutLogInput) => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.post<WorkoutLog>(API_ENDPOINTS.WORKOUT_LOGS, log)
      workoutLogs.value.unshift(response.data)
      return response.data
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to log workout'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const fetchExercises = async () => {
    try {
      const response = await api.get<Exercise[]>(API_ENDPOINTS.EXERCISES)
      exercises.value = response.data
    } catch (err) {
      // Silently fail, not critical
    }
  }

  const getExerciseById = (id: string) => {
    return exercises.value.find((e) => e.id === id)
  }

  return {
    workoutPlans,
    currentPlan,
    workoutLogs,
    exercises,
    isLoading,
    error,
    fetchWorkoutPlans,
    fetchWorkoutPlan,
    fetchWorkoutLogs,
    logWorkout,
    fetchExercises,
    getExerciseById,
  }
})
