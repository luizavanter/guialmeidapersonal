/**
 * Authentication composable
 */

import { ref, computed, Ref } from 'vue'
import { useApi } from './useApi'
import { API_ENDPOINTS, STORAGE_KEYS } from '@/constants'
import type { User, LoginCredentials, AuthResponse } from '@/types'

const currentUser: Ref<User | null> = ref(null)
const isInitialized = ref(false)

export const useAuth = () => {
  const api = useApi()

  const user = computed(() => currentUser.value)
  const isAuthenticated = computed(() => !!currentUser.value)
  const isTrainer = computed(() => currentUser.value?.role === 'trainer')
  const isStudent = computed(() => currentUser.value?.role === 'student')
  const isAdmin = computed(() => currentUser.value?.role === 'admin')

  const initAuth = () => {
    if (isInitialized.value) return

    const storedUser = localStorage.getItem(STORAGE_KEYS.USER)
    const accessToken = localStorage.getItem(STORAGE_KEYS.ACCESS_TOKEN)

    if (storedUser && accessToken) {
      try {
        currentUser.value = JSON.parse(storedUser)
      } catch (e) {
        console.error('Failed to parse stored user:', e)
        clearAuth()
      }
    }

    isInitialized.value = true
  }

  const setAuth = (authData: AuthResponse) => {
    currentUser.value = authData.user
    localStorage.setItem(STORAGE_KEYS.ACCESS_TOKEN, authData.tokens.accessToken)
    localStorage.setItem(STORAGE_KEYS.REFRESH_TOKEN, authData.tokens.refreshToken)
    localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(authData.user))
  }

  const clearAuth = () => {
    currentUser.value = null
    localStorage.removeItem(STORAGE_KEYS.ACCESS_TOKEN)
    localStorage.removeItem(STORAGE_KEYS.REFRESH_TOKEN)
    localStorage.removeItem(STORAGE_KEYS.USER)
  }

  const login = async (credentials: LoginCredentials): Promise<User> => {
    try {
      const response = await api.post<AuthResponse>(API_ENDPOINTS.LOGIN, credentials)
      setAuth(response)
      return response.user
    } catch (error) {
      clearAuth()
      throw error
    }
  }

  const logout = async (): Promise<void> => {
    try {
      const refreshToken = localStorage.getItem(STORAGE_KEYS.REFRESH_TOKEN)
      if (refreshToken) {
        await api.post(API_ENDPOINTS.LOGOUT, { refreshToken })
      }
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      clearAuth()
    }
  }

  const refreshToken = async (): Promise<void> => {
    const refreshTokenValue = localStorage.getItem(STORAGE_KEYS.REFRESH_TOKEN)

    if (!refreshTokenValue) {
      throw new Error('No refresh token available')
    }

    try {
      const response = await api.post<AuthResponse>(API_ENDPOINTS.REFRESH, {
        refreshToken: refreshTokenValue,
      })
      setAuth(response)
    } catch (error) {
      clearAuth()
      throw error
    }
  }

  const register = async (userData: {
    email: string
    password: string
    firstName: string
    lastName: string
    phone?: string
  }): Promise<User> => {
    try {
      const response = await api.post<AuthResponse>(API_ENDPOINTS.REGISTER, userData)
      setAuth(response)
      return response.user
    } catch (error) {
      throw error
    }
  }

  const updateProfile = async (data: Partial<User>): Promise<User> => {
    if (!currentUser.value) {
      throw new Error('No user logged in')
    }

    try {
      const updatedUser = await api.put<User>(`/users/${currentUser.value.id}`, data)
      currentUser.value = updatedUser
      localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(updatedUser))
      return updatedUser
    } catch (error) {
      throw error
    }
  }

  const checkAuth = (): boolean => {
    const token = localStorage.getItem(STORAGE_KEYS.ACCESS_TOKEN)
    const storedUser = localStorage.getItem(STORAGE_KEYS.USER)
    return !!(token && storedUser)
  }

  const requireAuth = () => {
    if (!checkAuth()) {
      throw new Error('Authentication required')
    }
  }

  const requireRole = (role: User['role'] | User['role'][]) => {
    requireAuth()

    const roles = Array.isArray(role) ? role : [role]
    if (!currentUser.value || !roles.includes(currentUser.value.role)) {
      throw new Error('Insufficient permissions')
    }
  }

  // Initialize on first use
  if (!isInitialized.value) {
    initAuth()
  }

  return {
    user,
    isAuthenticated,
    isTrainer,
    isStudent,
    isAdmin,
    loading: api.loading,
    error: api.error,
    login,
    logout,
    register,
    refreshToken,
    updateProfile,
    checkAuth,
    requireAuth,
    requireRole,
    initAuth,
  }
}
