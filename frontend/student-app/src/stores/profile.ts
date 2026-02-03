import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '@/lib/api'
import { API_ENDPOINTS } from '@/constants/api'
import type { StudentProfile } from '@/types'

export const useProfileStore = defineStore('profile', () => {
  const profile = ref<StudentProfile | null>(null)
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  const fetchProfile = async () => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.get<StudentProfile>(API_ENDPOINTS.PROFILE)
      profile.value = response.data
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to fetch profile'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const updateProfile = async (data: Partial<StudentProfile>) => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.put<StudentProfile>(API_ENDPOINTS.UPDATE_PROFILE, data)
      profile.value = response.data
      return response.data
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to update profile'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  return {
    profile,
    isLoading,
    error,
    fetchProfile,
    updateProfile,
  }
})
