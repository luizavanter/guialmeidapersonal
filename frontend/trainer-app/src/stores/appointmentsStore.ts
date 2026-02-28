import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useApi } from '@ga-personal/shared'
import { API_ENDPOINTS } from '@ga-personal/shared'
import type { Appointment } from '@ga-personal/shared'

// Transform backend snake_case appointment to frontend format
function normalizeAppointment(raw: any): Appointment {
  const scheduledAt = raw.scheduled_at || raw.scheduledAt || raw.startTime || ''
  const durationMinutes = raw.duration_minutes || raw.durationMinutes || 60

  let startTime = ''
  let endTime = ''
  if (scheduledAt) {
    startTime = scheduledAt
    const startDate = new Date(scheduledAt)
    if (!isNaN(startDate.getTime())) {
      const endDate = new Date(startDate.getTime() + durationMinutes * 60000)
      endTime = endDate.toISOString()
    }
  }

  return {
    id: raw.id,
    trainerId: raw.trainer_id || raw.trainerId || '',
    studentId: raw.student_id || raw.studentId || '',
    startTime,
    endTime,
    scheduledAt,
    durationMinutes,
    status: raw.status || 'scheduled',
    appointmentType: raw.appointment_type || raw.appointmentType || '',
    location: raw.location || '',
    notes: raw.notes || '',
    createdAt: raw.created_at || raw.createdAt || '',
    updatedAt: raw.updated_at || raw.updatedAt || '',
    student: raw.student,
  }
}

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
    return appointments.value.filter(a => {
      const time = a.startTime || a.scheduledAt || ''
      return time && time.startsWith(today)
    })
  })

  const upcomingAppointments = computed(() => {
    const now = new Date()
    return appointments.value.filter(a => {
      const time = a.startTime || a.scheduledAt || ''
      return time && new Date(time) > now
    }).sort((a, b) => {
      const ta = a.startTime || a.scheduledAt || ''
      const tb = b.startTime || b.scheduledAt || ''
      return new Date(ta).getTime() - new Date(tb).getTime()
    })
  })

  // Actions
  async function fetchAppointments(filters: Record<string, any> = {}) {
    loading.value = true
    error.value = null

    try {
      const response = await api.get<any[]>(API_ENDPOINTS.APPOINTMENTS, { params: filters })
      appointments.value = (response || []).map(normalizeAppointment)
      return appointments.value
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
      const response = await api.get<any>(API_ENDPOINTS.APPOINTMENT(id))
      currentAppointment.value = normalizeAppointment(response)
      return currentAppointment.value
    } catch (err: any) {
      error.value = err.response?.data?.errors?.[0]?.message || 'Failed to fetch appointment'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function createAppointment(data: Record<string, any>) {
    loading.value = true
    error.value = null

    try {
      // Backend expects data wrapped in "appointment" key
      const response = await api.post<any>(API_ENDPOINTS.APPOINTMENTS, { appointment: data })
      const normalized = normalizeAppointment(response)
      appointments.value.push(normalized)
      return normalized
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
        appointments.value[index] = response
      }
      return response
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
