import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '@/lib/api'
import { API_ENDPOINTS } from '@/constants/api'
import type { BodyAssessment, EvolutionPhoto, Goal } from '@/types'

export const useEvolutionStore = defineStore('evolution', () => {
  const bodyAssessments = ref<BodyAssessment[]>([])
  const evolutionPhotos = ref<EvolutionPhoto[]>([])
  const goals = ref<Goal[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  const fetchBodyAssessments = async () => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.get<BodyAssessment[]>(API_ENDPOINTS.BODY_ASSESSMENTS)
      bodyAssessments.value = response.data
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to fetch body assessments'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const fetchEvolutionPhotos = async () => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.get<EvolutionPhoto[]>(API_ENDPOINTS.EVOLUTION_PHOTOS)
      evolutionPhotos.value = response.data
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to fetch evolution photos'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const fetchGoals = async () => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.get<Goal[]>(API_ENDPOINTS.GOALS)
      goals.value = response.data
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to fetch goals'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const getLatestAssessment = () => {
    if (bodyAssessments.value.length === 0) return null
    return [...bodyAssessments.value].sort(
      (a: any, b: any) => new Date(b.assessment_date || b.assessmentDate).getTime() - new Date(a.assessment_date || a.assessmentDate).getTime()
    )[0]
  }

  const getActiveGoals = () => {
    return goals.value.filter((g) => g.status === 'active')
  }

  const getWeightHistory = () => {
    return bodyAssessments.value
      .filter((a: any) => (a.weight_kg || a.weight) !== null && (a.weight_kg || a.weight) !== undefined)
      .map((a: any) => ({
        date: a.assessment_date || a.assessmentDate,
        value: parseFloat(a.weight_kg || a.weight),
      }))
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
  }

  const getBodyFatHistory = () => {
    return bodyAssessments.value
      .filter((a: any) => (a.body_fat_percentage || a.bodyFat) !== null && (a.body_fat_percentage || a.bodyFat) !== undefined)
      .map((a: any) => ({
        date: a.assessment_date || a.assessmentDate,
        value: parseFloat(a.body_fat_percentage || a.bodyFat),
      }))
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
  }

  const getMuscleMassHistory = () => {
    return bodyAssessments.value
      .filter((a: any) => (a.muscle_mass_kg || a.muscleMass) !== null && (a.muscle_mass_kg || a.muscleMass) !== undefined)
      .map((a: any) => ({
        date: a.assessment_date || a.assessmentDate,
        value: parseFloat(a.muscle_mass_kg || a.muscleMass),
      }))
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
  }

  return {
    bodyAssessments,
    evolutionPhotos,
    goals,
    isLoading,
    error,
    fetchBodyAssessments,
    fetchEvolutionPhotos,
    fetchGoals,
    getLatestAssessment,
    getActiveGoals,
    getWeightHistory,
    getBodyFatHistory,
    getMuscleMassHistory,
  }
})
