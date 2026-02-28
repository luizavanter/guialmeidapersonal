import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useApi } from '@ga-personal/shared'
import { API_ENDPOINTS } from '@ga-personal/shared'
import type { Student, ApiResponse } from '@ga-personal/shared'

// Normalize backend snake_case student data to frontend format
function normalizeStudent(raw: any): Student {
  const user = raw.user ? normalizeUser(raw.user) : undefined
  return {
    id: raw.id,
    userId: raw.user_id || raw.userId || '',
    trainerId: raw.trainer_id || raw.trainerId || '',
    status: raw.status || 'active',
    emergencyContact: raw.emergency_contact_name || raw.emergencyContact || undefined,
    emergencyPhone: raw.emergency_contact_phone || raw.emergencyPhone || undefined,
    medicalNotes: raw.medical_conditions || raw.medicalNotes || undefined,
    goals: raw.goals_description || raw.goals || undefined,
    createdAt: raw.inserted_at || raw.createdAt || '',
    updatedAt: raw.updated_at || raw.updatedAt || '',
    user,
  }
}

function normalizeUser(user: any) {
  if (!user) return undefined
  const fullName = user.full_name || user.fullName || ''
  const parts = fullName.trim().split(/\s+/)
  return {
    id: user.id,
    email: user.email || '',
    firstName: user.firstName || parts[0] || '',
    lastName: user.lastName || parts.slice(1).join(' ') || '',
    fullName,
    phone: user.phone || '',
    role: user.role,
    locale: user.locale,
    avatarUrl: user.avatarUrl,
    createdAt: user.created_at || user.createdAt || '',
    updatedAt: user.updated_at || user.updatedAt || '',
  }
}

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
      const response = await api.get<any[]>(API_ENDPOINTS.STUDENTS, { params: filters })
      students.value = (response || []).map(normalizeStudent)
      return students.value
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
      const response = await api.get<any>(API_ENDPOINTS.STUDENT(id))
      currentStudent.value = normalizeStudent(response)
      return currentStudent.value
    } catch (err: any) {
      error.value = err.response?.data?.errors?.[0]?.message || 'Failed to fetch student'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function createStudent(data: Record<string, any>) {
    loading.value = true
    error.value = null

    try {
      // Backend expects data wrapped in "student" key
      const response = await api.post<any>(API_ENDPOINTS.STUDENTS, { student: data })
      const normalized = normalizeStudent(response)
      students.value.push(normalized)
      return normalized
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
      const response = await api.put<any>(API_ENDPOINTS.STUDENT(id), data)
      const normalized = normalizeStudent(response)
      const index = students.value.findIndex(s => s.id === id)
      if (index > -1) {
        students.value[index] = normalized
      }
      if (currentStudent.value?.id === id) {
        currentStudent.value = normalized
      }
      return normalized
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
