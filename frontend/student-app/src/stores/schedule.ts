import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api } from '@/lib/api'
import { API_ENDPOINTS } from '@/constants/api'
import type { Appointment, AppointmentChangeRequest } from '@/types'

// Normalize backend snake_case appointment to frontend format
function normalizeAppointment(raw: any): Appointment {
  const scheduledAt = raw.scheduled_at || raw.scheduledAt || raw.startTime || ''
  const durationMinutes = raw.duration_minutes || raw.durationMinutes || 60

  let startTime = ''
  let endTime = ''
  let appointmentDate = raw.appointment_date || raw.appointmentDate || ''
  if (scheduledAt) {
    startTime = scheduledAt
    appointmentDate = appointmentDate || scheduledAt.split('T')[0]
    const startDate = new Date(scheduledAt)
    if (!isNaN(startDate.getTime())) {
      const endDate = new Date(startDate.getTime() + durationMinutes * 60000)
      endTime = endDate.toISOString()
    }
  }

  return {
    ...raw,
    id: raw.id,
    trainerId: raw.trainer_id || raw.trainerId || '',
    studentId: raw.student_id || raw.studentId || '',
    startTime,
    endTime,
    appointmentDate,
    status: raw.status || 'scheduled',
    notes: raw.notes || '',
    insertedAt: raw.inserted_at || raw.insertedAt || '',
    updatedAt: raw.updated_at || raw.updatedAt || '',
  }
}

export const useScheduleStore = defineStore('schedule', () => {
  const appointments = ref<Appointment[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  const upcomingAppointments = computed(() => {
    const now = new Date()
    return appointments.value
      .filter((a) => {
        const dateStr = a.appointmentDate || a.startTime || ''
        if (!dateStr) return false
        const appointmentDate = new Date(dateStr)
        return appointmentDate >= now && a.status === 'scheduled'
      })
      .sort((a, b) => new Date(a.appointmentDate || a.startTime).getTime() - new Date(b.appointmentDate || b.startTime).getTime())
  })

  const pastAppointments = computed(() => {
    const now = new Date()
    return appointments.value
      .filter((a) => {
        const dateStr = a.appointmentDate || a.startTime || ''
        if (!dateStr) return false
        const appointmentDate = new Date(dateStr)
        return appointmentDate < now || a.status !== 'scheduled'
      })
      .sort((a, b) => new Date(b.appointmentDate || b.startTime).getTime() - new Date(a.appointmentDate || a.startTime).getTime())
  })

  const nextAppointment = computed(() => {
    return upcomingAppointments.value[0] || null
  })

  const fetchAppointments = async () => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.get<Appointment[]>(API_ENDPOINTS.APPOINTMENTS)
      appointments.value = (response.data || []).map(normalizeAppointment)
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to fetch appointments'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const requestAppointmentChange = async (request: AppointmentChangeRequest) => {
    isLoading.value = true
    error.value = null

    try {
      await api.post(API_ENDPOINTS.APPOINTMENT_CHANGE_REQUEST, request)
      // Optionally refetch appointments
      await fetchAppointments()
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to request appointment change'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  return {
    appointments,
    upcomingAppointments,
    pastAppointments,
    nextAppointment,
    isLoading,
    error,
    fetchAppointments,
    requestAppointmentChange,
  }
})
