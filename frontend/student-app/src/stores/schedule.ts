import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api } from '@/lib/api'
import { API_ENDPOINTS } from '@/constants/api'
import type { Appointment, AppointmentChangeRequest } from '@/types'

export const useScheduleStore = defineStore('schedule', () => {
  const appointments = ref<Appointment[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  const upcomingAppointments = computed(() => {
    const now = new Date()
    return appointments.value
      .filter((a) => {
        const appointmentDate = new Date(a.appointmentDate)
        return appointmentDate >= now && a.status === 'scheduled'
      })
      .sort((a, b) => new Date(a.appointmentDate).getTime() - new Date(b.appointmentDate).getTime())
  })

  const pastAppointments = computed(() => {
    const now = new Date()
    return appointments.value
      .filter((a) => {
        const appointmentDate = new Date(a.appointmentDate)
        return appointmentDate < now || a.status !== 'scheduled'
      })
      .sort((a, b) => new Date(b.appointmentDate).getTime() - new Date(a.appointmentDate).getTime())
  })

  const nextAppointment = computed(() => {
    return upcomingAppointments.value[0] || null
  })

  const fetchAppointments = async () => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.get<Appointment[]>(API_ENDPOINTS.APPOINTMENTS)
      appointments.value = response.data
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
