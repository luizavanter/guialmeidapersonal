import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useApi } from '@ga-personal/shared'
import { API_ENDPOINTS } from '@ga-personal/shared'
import type { Appointment } from '@ga-personal/shared'

export const useAppointmentsStore = defineStore('appointments', () => {
  const api = useApi()

  // State
  const appointments = ref<Appointment[]>([])
  const currentAppointment = ref<Appointment | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Getters
  const todayAppointments = computed(() => {
    const today = new Date().toISOString().split('T')[0]
    return appointments.value.filter(a =>
      a.startTime.startsWith(today)
    )
  })

  const upcomingAppointments = computed(() => {
    const now = new Date()
    return appointments.value.filter(a =>
      new Date(a.startTime) > now
    ).sort((a, b) =>
      new Date(a.startTime).getTime() - new Date(b.startTime).getTime()
    )
  })

  // Actions
  async function fetchAppointments(filters: Record<string, any> = {}) {
    loading.value = true
    error.value = null

    try {
      const response = await api.get<Appointment[]>(API_ENDPOINTS.APPOINTMENTS, { params: filters })
      appointments.value = response.data
      return response.data
    } catch (err: any) {
      error.value = err.response?.data?.errors?.[0]?.message || 'Failed to fetch appointments'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function fetchAppointment(id: string) {
    loading.value = true
    error.value = null

    try {
      const response = await api.get<Appointment>(API_ENDPOINTS.APPOINTMENT(id))
      currentAppointment.value = response.data
      return response.data
    } catch (err: any) {
      error.value = err.response?.data?.errors?.[0]?.message || 'Failed to fetch appointment'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function createAppointment(data: Partial<Appointment>) {
    loading.value = true
    error.value = null

    try {
      const response = await api.post<Appointment>(API_ENDPOINTS.APPOINTMENTS, data)
      appointments.value.push(response.data)
      return response.data
    } catch (err: any) {
      error.value = err.response?.data?.errors?.[0]?.message || 'Failed to create appointment'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function updateAppointment(id: string, data: Partial<Appointment>) {
    loading.value = true
    error.value = null

    try {
      const response = await api.put<Appointment>(API_ENDPOINTS.APPOINTMENT(id), data)
      const index = appointments.value.findIndex(a => a.id === id)
      if (index > -1) {
        appointments.value[index] = response.data
      }
      return response.data
    } catch (err: any) {
      error.value = err.response?.data?.errors?.[0]?.message || 'Failed to update appointment'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function deleteAppointment(id: string) {
    loading.value = true
    error.value = null

    try {
      await api.delete(API_ENDPOINTS.APPOINTMENT(id))
      appointments.value = appointments.value.filter(a => a.id !== id)
    } catch (err: any) {
      error.value = err.response?.data?.errors?.[0]?.message || 'Failed to delete appointment'
      throw err
    } finally {
      loading.value = false
    }
  }

  return {
    appointments,
    currentAppointment,
    loading,
    error,
    todayAppointments,
    upcomingAppointments,
    fetchAppointments,
    fetchAppointment,
    createAppointment,
    updateAppointment,
    deleteAppointment,
  }
})
