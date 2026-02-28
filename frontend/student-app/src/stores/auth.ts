import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api } from '@/lib/api'
import { API_ENDPOINTS, STORAGE_KEYS } from '@/constants/api'
import type { User, LoginCredentials, AuthResponse } from '@/types'

// Normalize backend user (full_name -> name)
function normalizeUser(raw: any): User {
  return {
    id: raw.id,
    email: raw.email,
    name: raw.name || raw.full_name || raw.fullName || [raw.firstName, raw.lastName].filter(Boolean).join(' ') || '',
    role: raw.role,
    locale: raw.locale || 'pt-BR',
    avatarUrl: raw.avatar_url || raw.avatarUrl,
    insertedAt: raw.inserted_at || raw.insertedAt || '',
    updatedAt: raw.updated_at || raw.updatedAt || '',
  }
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  const isAuthenticated = computed(() => !!user.value)

  const login = async (credentials: LoginCredentials) => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.post<AuthResponse>(API_ENDPOINTS.LOGIN, credentials)

      if (response.data.user.role !== 'student') {
        throw new Error('Access denied. Students only.')
      }

      const normalized = normalizeUser(response.data.user)
      user.value = normalized
      localStorage.setItem(STORAGE_KEYS.ACCESS_TOKEN, response.data.tokens.accessToken)
      localStorage.setItem(STORAGE_KEYS.REFRESH_TOKEN, response.data.tokens.refreshToken)
      localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(normalized))
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Login failed'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const logout = async () => {
    try {
      await api.post(API_ENDPOINTS.LOGOUT)
    } catch (err) {
      // Ignore errors on logout
    } finally {
      user.value = null
      localStorage.removeItem(STORAGE_KEYS.ACCESS_TOKEN)
      localStorage.removeItem(STORAGE_KEYS.REFRESH_TOKEN)
      localStorage.removeItem(STORAGE_KEYS.USER)
    }
  }

  const checkAuth = async () => {
    const token = localStorage.getItem(STORAGE_KEYS.ACCESS_TOKEN)
    const userStr = localStorage.getItem(STORAGE_KEYS.USER)

    if (!token || !userStr) {
      return
    }

    try {
      user.value = normalizeUser(JSON.parse(userStr))
      // Verify token is still valid
      const response = await api.get<User>(API_ENDPOINTS.ME)
      const normalized = normalizeUser(response.data)
      user.value = normalized
      localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(normalized))
    } catch (err) {
      // Token invalid, clear storage
      user.value = null
      localStorage.removeItem(STORAGE_KEYS.ACCESS_TOKEN)
      localStorage.removeItem(STORAGE_KEYS.REFRESH_TOKEN)
      localStorage.removeItem(STORAGE_KEYS.USER)
    }
  }

  return {
    user,
    isLoading,
    error,
    isAuthenticated,
    login,
    logout,
    checkAuth,
  }
})
