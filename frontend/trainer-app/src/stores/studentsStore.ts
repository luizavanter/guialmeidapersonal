import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useApi } from '@ga-personal/shared'
import { API_ENDPOINTS } from '@ga-personal/shared'
import type { Student, ApiResponse } from '@ga-personal/shared'

export const useStudentsStore = defineStore('students', () => {
  const api = useApi()

  // State
  const students = ref<Student[]>([])
  const currentStudent = ref<Student | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Getters
  const activeStudents = computed(() =>
    students.value.filter(s => s.status === 'active')
  )

  const inactiveStudents = computed(() =>
    students.value.filter(s => s.status === 'inactive')
  )

  const totalStudents = computed(() => students.value.length)

  // Actions
  async function fetchStudents(filters: Record<string, any> = {}) {
    loading.value = true
    error.value = null

    try {
      const response = await api.get<Student[]>(API_ENDPOINTS.STUDENTS, { params: filters })
      students.value = response
      return response
    } catch (err: any) {
      error.value = err.response?.data?.errors?.[0]?.message || 'Failed to fetch students'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function fetchStudent(id: string) {
    loading.value = true
    error.value = null

    try {
      const response = await api.get<Student>(API_ENDPOINTS.STUDENT(id))
      currentStudent.value = response
      return response
    } catch (err: any) {
      error.value = err.response?.data?.errors?.[0]?.message || 'Failed to fetch student'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function createStudent(data: Partial<Student>) {
    loading.value = true
    error.value = null

    try {
      const response = await api.post<Student>(API_ENDPOINTS.STUDENTS, data)
      students.value.push(response)
      return response
    } catch (err: any) {
      error.value = err.response?.data?.errors?.[0]?.message || 'Failed to create student'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function updateStudent(id: string, data: Partial<Student>) {
    loading.value = true
    error.value = null

    try {
      const response = await api.put<Student>(API_ENDPOINTS.STUDENT(id), data)
      const index = students.value.findIndex(s => s.id === id)
      if (index > -1) {
        students.value[index] = response
      }
      if (currentStudent.value?.id === id) {
        currentStudent.value = response
      }
      return response
    } catch (err: any) {
      error.value = err.response?.data?.errors?.[0]?.message || 'Failed to update student'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function deleteStudent(id: string) {
    loading.value = true
    error.value = null

    try {
      await api.delete(API_ENDPOINTS.STUDENT(id))
      students.value = students.value.filter(s => s.id !== id)
      if (currentStudent.value?.id === id) {
        currentStudent.value = null
      }
    } catch (err: any) {
      error.value = err.response?.data?.errors?.[0]?.message || 'Failed to delete student'
      throw err
    } finally {
      loading.value = false
    }
  }

  function clearCurrent() {
    currentStudent.value = null
  }

  function clearError() {
    error.value = null
  }

  return {
    students,
    currentStudent,
    loading,
    error,
    activeStudents,
    inactiveStudents,
    totalStudents,
    fetchStudents,
    fetchStudent,
    createStudent,
    updateStudent,
    deleteStudent,
    clearCurrent,
    clearError,
  }
})
