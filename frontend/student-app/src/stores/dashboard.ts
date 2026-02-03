import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '@/lib/api'
import { API_ENDPOINTS } from '@/constants/api'
import type { DashboardStats } from '@/types'

export const useDashboardStore = defineStore('dashboard', () => {
  const stats = ref<DashboardStats | null>(null)
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  const fetchDashboard = async () => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.get<DashboardStats>(API_ENDPOINTS.DASHBOARD)
      stats.value = response.data
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to fetch dashboard'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  return {
    stats,
    isLoading,
    error,
    fetchDashboard,
  }
})
