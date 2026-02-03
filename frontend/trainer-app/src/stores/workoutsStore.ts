import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useApi } from '@ga-personal/shared'
import { API_ENDPOINTS } from '@ga-personal/shared'
import type { Exercise, WorkoutPlan } from '@ga-personal/shared'

export const useWorkoutsStore = defineStore('workouts', () => {
  const api = useApi()

  // State
  const exercises = ref<Exercise[]>([])
  const workoutPlans = ref<WorkoutPlan[]>([])
  const currentExercise = ref<Exercise | null>(null)
  const currentPlan = ref<WorkoutPlan | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Exercises
  async function fetchExercises(filters: Record<string, any> = {}) {
    loading.value = true
    try {
      const response = await api.get<Exercise[]>(API_ENDPOINTS.EXERCISES, { params: filters })
      exercises.value = response
      return response
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  async function createExercise(data: Partial<Exercise>) {
    loading.value = true
    try {
      const response = await api.post<Exercise>(API_ENDPOINTS.EXERCISES, data)
      exercises.value.push(response)
      return response
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  async function updateExercise(id: string, data: Partial<Exercise>) {
    loading.value = true
    try {
      const response = await api.put<Exercise>(API_ENDPOINTS.EXERCISE(id), data)
      const index = exercises.value.findIndex(e => e.id === id)
      if (index > -1) exercises.value[index] = response
      return response
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  async function deleteExercise(id: string) {
    loading.value = true
    try {
      await api.delete(API_ENDPOINTS.EXERCISE(id))
      exercises.value = exercises.value.filter(e => e.id !== id)
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  // Workout Plans
  async function fetchWorkoutPlans(filters: Record<string, any> = {}) {
    loading.value = true
    try {
      const response = await api.get<WorkoutPlan[]>(API_ENDPOINTS.WORKOUT_PLANS, { params: filters })
      workoutPlans.value = response
      return response
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  async function fetchWorkoutPlan(id: string) {
    loading.value = true
    try {
      const response = await api.get<WorkoutPlan>(API_ENDPOINTS.WORKOUT_PLAN(id))
      currentPlan.value = response
      return response
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  async function createWorkoutPlan(data: Partial<WorkoutPlan>) {
    loading.value = true
    try {
      const response = await api.post<WorkoutPlan>(API_ENDPOINTS.WORKOUT_PLANS, data)
      workoutPlans.value.push(response)
      return response
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  async function updateWorkoutPlan(id: string, data: Partial<WorkoutPlan>) {
    loading.value = true
    try {
      const response = await api.put<WorkoutPlan>(API_ENDPOINTS.WORKOUT_PLAN(id), data)
      const index = workoutPlans.value.findIndex(p => p.id === id)
      if (index > -1) workoutPlans.value[index] = response
      return response
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  async function deleteWorkoutPlan(id: string) {
    loading.value = true
    try {
      await api.delete(API_ENDPOINTS.WORKOUT_PLAN(id))
      workoutPlans.value = workoutPlans.value.filter(p => p.id !== id)
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  return {
    exercises,
    workoutPlans,
    currentExercise,
    currentPlan,
    loading,
    error,
    fetchExercises,
    createExercise,
    updateExercise,
    deleteExercise,
    fetchWorkoutPlans,
    fetchWorkoutPlan,
    createWorkoutPlan,
    updateWorkoutPlan,
    deleteWorkoutPlan,
  }
})
