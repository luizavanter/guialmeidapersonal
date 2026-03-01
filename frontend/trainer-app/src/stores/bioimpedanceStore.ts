import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useApi } from '@ga-personal/shared'
import { API_ENDPOINTS } from '@ga-personal/shared'
import type { BioimpedanceImport } from '@ga-personal/shared'

export const useBioimpedanceStore = defineStore('bioimpedance', () => {
  const api = useApi()

  const imports = ref<BioimpedanceImport[]>([])
  const currentImport = ref<BioimpedanceImport | null>(null)
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  async function extractFromMedia(mediaFileId: string, deviceType: string, studentId: string) {
    isLoading.value = true
    error.value = null
    try {
      const result = await api.post<BioimpedanceImport>(API_ENDPOINTS.BIOIMPEDANCE_EXTRACT, {
        bioimpedance: {
          media_file_id: mediaFileId,
          device_type: deviceType,
          student_id: studentId,
        },
      })
      const importData = result as any
      imports.value.unshift(importData)
      return importData
    } catch (err: any) {
      error.value = err.message || 'Extraction failed'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  async function fetchImports(filters?: Record<string, any>) {
    isLoading.value = true
    error.value = null
    try {
      const response = await api.get<BioimpedanceImport[]>(
        API_ENDPOINTS.BIOIMPEDANCE_IMPORTS,
        filters ? { params: filters } : undefined,
      )
      imports.value = response as any
      return imports.value
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch imports'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  async function fetchImport(id: string) {
    isLoading.value = true
    error.value = null
    try {
      const response = await api.get<BioimpedanceImport>(API_ENDPOINTS.BIOIMPEDANCE_IMPORT(id))
      currentImport.value = response as any
      return currentImport.value
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch import'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  async function updateImport(id: string, data: Partial<BioimpedanceImport>) {
    try {
      const response = await api.put<BioimpedanceImport>(API_ENDPOINTS.BIOIMPEDANCE_IMPORT(id), {
        bioimpedance: data,
      })
      const updated = response as any
      const idx = imports.value.findIndex((i) => i.id === id)
      if (idx > -1) imports.value[idx] = updated
      if (currentImport.value?.id === id) currentImport.value = updated
      return updated
    } catch (err: any) {
      error.value = err.message || 'Update failed'
      throw err
    }
  }

  async function applyImport(id: string) {
    try {
      const response = await api.post<BioimpedanceImport>(API_ENDPOINTS.BIOIMPEDANCE_APPLY(id))
      const updated = response as any
      const idx = imports.value.findIndex((i) => i.id === id)
      if (idx > -1) imports.value[idx] = updated
      if (currentImport.value?.id === id) currentImport.value = updated
      return updated
    } catch (err: any) {
      error.value = err.message || 'Apply failed'
      throw err
    }
  }

  async function rejectImport(id: string, notes?: string) {
    try {
      const response = await api.post<BioimpedanceImport>(API_ENDPOINTS.BIOIMPEDANCE_REJECT(id), {
        bioimpedance: notes ? { trainer_notes: notes } : undefined,
      })
      const updated = response as any
      const idx = imports.value.findIndex((i) => i.id === id)
      if (idx > -1) imports.value[idx] = updated
      if (currentImport.value?.id === id) currentImport.value = updated
      return updated
    } catch (err: any) {
      error.value = err.message || 'Reject failed'
      throw err
    }
  }

  return {
    imports,
    currentImport,
    isLoading,
    error,
    extractFromMedia,
    fetchImports,
    fetchImport,
    updateImport,
    applyImport,
    rejectImport,
  }
})
