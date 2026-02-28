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
      // Fetch all data in parallel from individual endpoints
      const [appointmentsRes, workoutPlansRes, goalsRes, assessmentsRes, messagesRes] = await Promise.allSettled([
        api.get(API_ENDPOINTS.APPOINTMENTS),
        api.get(API_ENDPOINTS.WORKOUT_PLANS),
        api.get(API_ENDPOINTS.GOALS),
        api.get(API_ENDPOINTS.BODY_ASSESSMENTS),
        api.get(API_ENDPOINTS.MESSAGES),
      ])

      const appointments = appointmentsRes.status === 'fulfilled' ? appointmentsRes.value.data || [] : []
      const workoutPlans = workoutPlansRes.status === 'fulfilled' ? workoutPlansRes.value.data || [] : []
      const goals = goalsRes.status === 'fulfilled' ? goalsRes.value.data || [] : []
      const assessments = assessmentsRes.status === 'fulfilled' ? assessmentsRes.value.data || [] : []
      const messages = messagesRes.status === 'fulfilled' ? messagesRes.value.data || [] : []

      // Find next upcoming appointment
      const now = new Date()
      const upcomingAppointments = appointments
        .filter((a: any) => new Date(a.scheduled_at) > now && a.status !== 'cancelled')
        .sort((a: any, b: any) => new Date(a.scheduled_at).getTime() - new Date(b.scheduled_at).getTime())

      const nextAppointment = upcomingAppointments[0]
        ? {
            ...upcomingAppointments[0],
            appointmentDate: upcomingAppointments[0].scheduled_at,
            startTime: upcomingAppointments[0].scheduled_at,
          }
        : undefined

      // Find active workout plan
      const activeWorkoutPlan = workoutPlans.find((p: any) => p.status === 'active') || undefined

      // Find active goals
      const activeGoals = goals.filter((g: any) => g.status === 'active' || g.status === 'in_progress')

      // Get last assessment
      const sortedAssessments = [...assessments].sort(
        (a: any, b: any) => new Date(b.assessment_date).getTime() - new Date(a.assessment_date).getTime()
      )
      const lastAssessment = sortedAssessments[0]
        ? {
            ...sortedAssessments[0],
            weight: sortedAssessments[0].weight_kg,
            bodyFat: sortedAssessments[0].body_fat_percentage,
          }
        : undefined

      // Count unread messages
      const unreadMessages = messages.filter((m: any) => !m.read_at).length

      stats.value = {
        nextAppointment,
        activeWorkoutPlan: activeWorkoutPlan
          ? { ...activeWorkoutPlan, exercises: activeWorkoutPlan.workout_exercises }
          : undefined,
        recentProgress: {
          lastAssessment,
          completedWorkoutsThisWeek: 0,
        },
        activeGoals: activeGoals.map((g: any) => ({
          ...g,
          targetUnit: g.unit,
          currentValue: g.current_value,
          targetValue: g.target_value,
        })),
        unreadMessages,
      }
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to fetch dashboard'
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
