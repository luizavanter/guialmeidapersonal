import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useApi } from '@ga-personal/shared'
import { API_ENDPOINTS } from '@ga-personal/shared'
import type { Payment, Subscription, Plan } from '@ga-personal/shared'

export const useFinanceStore = defineStore('finance', () => {
  const api = useApi()

  // State
  const payments = ref<Payment[]>([])
  const subscriptions = ref<Subscription[]>([])
  const plans = ref<Plan[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Getters
  const pendingPayments = computed(() =>
    payments.value.filter(p => p.status === 'pending')
  )

  const overduePayments = computed(() => {
    const now = new Date()
    return payments.value.filter(p =>
      p.status === 'pending' && new Date(p.dueDate) < now
    )
  })

  const monthRevenue = computed(() => {
    const now = new Date()
    const month = now.getMonth()
    const year = now.getFullYear()

    return payments.value
      .filter(p => {
        if (p.status !== 'paid' || !p.paidAt) return false
        const paidDate = new Date(p.paidAt)
        return paidDate.getMonth() === month && paidDate.getFullYear() === year
      })
      .reduce((sum, p) => sum + p.amount, 0)
  })

  // Actions - Payments
  async function fetchPayments(filters: Record<string, any> = {}) {
    loading.value = true
    try {
      const response = await api.get<Payment[]>(API_ENDPOINTS.PAYMENTS, { params: filters })
      payments.value = response.data
      return response.data
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  async function createPayment(data: Partial<Payment>) {
    loading.value = true
    try {
      const response = await api.post<Payment>(API_ENDPOINTS.PAYMENTS, data)
      payments.value.push(response.data)
      return response.data
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  async function updatePayment(id: string, data: Partial<Payment>) {
    loading.value = true
    try {
      const response = await api.put<Payment>(API_ENDPOINTS.PAYMENT(id), data)
      const index = payments.value.findIndex(p => p.id === id)
      if (index > -1) payments.value[index] = response.data
      return response.data
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  // Actions - Subscriptions
  async function fetchSubscriptions(filters: Record<string, any> = {}) {
    loading.value = true
    try {
      const response = await api.get<Subscription[]>(API_ENDPOINTS.SUBSCRIPTIONS, { params: filters })
      subscriptions.value = response.data
      return response.data
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  async function createSubscription(data: Partial<Subscription>) {
    loading.value = true
    try {
      const response = await api.post<Subscription>(API_ENDPOINTS.SUBSCRIPTIONS, data)
      subscriptions.value.push(response.data)
      return response.data
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  // Actions - Plans
  async function fetchPlans() {
    loading.value = true
    try {
      const response = await api.get<Plan[]>(API_ENDPOINTS.PLANS)
      plans.value = response.data
      return response.data
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  async function createPlan(data: Partial<Plan>) {
    loading.value = true
    try {
      const response = await api.post<Plan>(API_ENDPOINTS.PLANS, data)
      plans.value.push(response.data)
      return response.data
    } catch (err: any) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  return {
    payments,
    subscriptions,
    plans,
    loading,
    error,
    pendingPayments,
    overduePayments,
    monthRevenue,
    fetchPayments,
    createPayment,
    updatePayment,
    fetchSubscriptions,
    createSubscription,
    fetchPlans,
    createPlan,
  }
})
