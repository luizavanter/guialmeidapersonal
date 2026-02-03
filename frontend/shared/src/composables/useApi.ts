/**
 * API composable with axios interceptors
 */

import axios, { AxiosInstance, AxiosRequestConfig, AxiosError } from 'axios'
import { ref, Ref } from 'vue'
import { API_BASE_URL, API_VERSION, API_TIMEOUT, STORAGE_KEYS } from '@/constants'
import type { ApiResponse, ApiError } from '@/types'

export interface UseApiOptions {
  baseURL?: string
  timeout?: number
  withAuth?: boolean
}

export interface ApiState {
  loading: Ref<boolean>
  error: Ref<ApiError | null>
}

let apiInstance: AxiosInstance | null = null

export const createApiInstance = (options: UseApiOptions = {}): AxiosInstance => {
  const instance = axios.create({
    baseURL: options.baseURL || `${API_BASE_URL}/api/${API_VERSION}`,
    timeout: options.timeout || API_TIMEOUT,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  })

  // Request interceptor
  instance.interceptors.request.use(
    (config) => {
      if (options.withAuth !== false) {
        const token = localStorage.getItem(STORAGE_KEYS.ACCESS_TOKEN)
        if (token) {
          config.headers.Authorization = `Bearer ${token}`
        }
      }

      // Add locale header
      const locale = localStorage.getItem(STORAGE_KEYS.LOCALE) || 'pt-BR'
      config.headers['Accept-Language'] = locale

      return config
    },
    (error) => {
      return Promise.reject(error)
    }
  )

  // Response interceptor
  instance.interceptors.response.use(
    (response) => {
      return response
    },
    async (error: AxiosError) => {
      const originalRequest = error.config as AxiosRequestConfig & { _retry?: boolean }

      // Handle 401 - Unauthorized
      if (error.response?.status === 401 && !originalRequest._retry) {
        originalRequest._retry = true

        try {
          const refreshToken = localStorage.getItem(STORAGE_KEYS.REFRESH_TOKEN)
          if (refreshToken) {
            const response = await axios.post(
              `${API_BASE_URL}/api/${API_VERSION}/auth/refresh`,
              { refreshToken }
            )

            const { accessToken } = response.data.data
            localStorage.setItem(STORAGE_KEYS.ACCESS_TOKEN, accessToken)

            // Retry original request
            if (originalRequest.headers) {
              originalRequest.headers.Authorization = `Bearer ${accessToken}`
            }
            return instance(originalRequest)
          }
        } catch (refreshError) {
          // Refresh failed, logout user
          localStorage.removeItem(STORAGE_KEYS.ACCESS_TOKEN)
          localStorage.removeItem(STORAGE_KEYS.REFRESH_TOKEN)
          localStorage.removeItem(STORAGE_KEYS.USER)
          window.location.href = '/login'
          return Promise.reject(refreshError)
        }
      }

      return Promise.reject(error)
    }
  )

  return instance
}

export const useApi = (options: UseApiOptions = {}) => {
  if (!apiInstance) {
    apiInstance = createApiInstance(options)
  }

  const loading = ref(false)
  const error = ref<ApiError | null>(null)

  const handleError = (err: any): ApiError => {
    if (axios.isAxiosError(err)) {
      const axiosError = err as AxiosError<ApiResponse<any>>

      if (axiosError.response?.data?.errors?.[0]) {
        return axiosError.response.data.errors[0]
      }

      if (axiosError.response?.status === 404) {
        return { message: 'Resource not found', code: '404' }
      }

      if (axiosError.response?.status === 403) {
        return { message: 'Access forbidden', code: '403' }
      }

      if (axiosError.response?.status === 500) {
        return { message: 'Server error', code: '500' }
      }

      if (axiosError.message === 'Network Error') {
        return { message: 'Network error. Please check your connection.', code: 'NETWORK_ERROR' }
      }

      return { message: axiosError.message, code: 'UNKNOWN' }
    }

    return { message: 'An unexpected error occurred', code: 'UNKNOWN' }
  }

  const request = async <T>(
    config: AxiosRequestConfig
  ): Promise<T> => {
    loading.value = true
    error.value = null

    try {
      const response = await apiInstance!.request<ApiResponse<T>>(config)
      return response.data.data
    } catch (err) {
      error.value = handleError(err)
      throw error.value
    } finally {
      loading.value = false
    }
  }

  const get = async <T>(url: string, config?: AxiosRequestConfig): Promise<T> => {
    return request<T>({ ...config, method: 'GET', url })
  }

  const post = async <T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> => {
    return request<T>({ ...config, method: 'POST', url, data })
  }

  const put = async <T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> => {
    return request<T>({ ...config, method: 'PUT', url, data })
  }

  const patch = async <T>(url: string, data?: any, config?: AxiosRequestConfig): Promise<T> => {
    return request<T>({ ...config, method: 'PATCH', url, data })
  }

  const del = async <T>(url: string, config?: AxiosRequestConfig): Promise<T> => {
    return request<T>({ ...config, method: 'DELETE', url })
  }

  return {
    loading,
    error,
    request,
    get,
    post,
    put,
    patch,
    delete: del,
    instance: apiInstance,
  }
}
