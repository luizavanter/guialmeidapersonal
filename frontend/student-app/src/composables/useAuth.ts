import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import type { LoginCredentials } from '@/types'

export const useAuth = () => {
  const authStore = useAuthStore()
  const router = useRouter()

  const user = computed(() => authStore.user)
  const isAuthenticated = computed(() => authStore.isAuthenticated)
  const isLoading = computed(() => authStore.isLoading)
  const error = computed(() => authStore.error)

  const login = async (credentials: LoginCredentials) => {
    await authStore.login(credentials)
    if (authStore.isAuthenticated && authStore.user?.role === 'student') {
      router.push('/')
    }
  }

  const logout = async () => {
    await authStore.logout()
    router.push('/login')
  }

  const checkAuth = async () => {
    await authStore.checkAuth()
  }

  return {
    user,
    isAuthenticated,
    isLoading,
    error,
    login,
    logout,
    checkAuth,
  }
}
