import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useApi } from '@ga-personal/shared'
import { API_ENDPOINTS } from '@ga-personal/shared'
import type { AIAnalysis, AIUsage } from '@ga-personal/shared'

export const useAIAnalysisStore = defineStore('aiAnalysis', () => {
  const api = useApi()

  const analyses = ref<AIAnalysis[]>([])
  const currentAnalysis = ref<AIAnalysis | null>(null)
  const usage = ref<AIUsage | null>(null)
  const isLoading = ref(false)
  const isAnalyzing = ref(false)
  const error = ref<string | null>(null)

  async function analyzeVisual(mediaFileId: string, studentId: string) {
    isAnalyzing.value = true
    error.value = null
    try {
      const result = await api.post<AIAnalysis>(API_ENDPOINTS.AI_ANALYZE_VISUAL, {
        analysis: { media_file_id: mediaFileId, student_id: studentId },
      })
      const analysis = result as any
      analyses.value.unshift(analysis)
      return analysis
    } catch (err: any) {
      error.value = err.message || 'Analysis failed'
      throw err
    } finally {
      isAnalyzing.value = false
    }
  }

  async function analyzeTrends(studentId: string) {
    isAnalyzing.value = true
    error.value = null
    try {
      const result = await api.post<AIAnalysis>(API_ENDPOINTS.AI_ANALYZE_TRENDS, {
        analysis: { student_id: studentId },
      })
      const analysis = result as any
      analyses.value.unshift(analysis)
      return analysis
    } catch (err: any) {
      error.value = err.message || 'Analysis failed'
      throw err
    } finally {
      isAnalyzing.value = false
    }
  }

  async function analyzeDocument(mediaFileId: string, studentId: string) {
    isAnalyzing.value = true
    error.value = null
    try {
      const result = await api.post<AIAnalysis>(API_ENDPOINTS.AI_ANALYZE_DOCUMENT, {
        analysis: { media_file_id: mediaFileId, student_id: studentId },
      })
      const analysis = result as any
      analyses.value.unshift(analysis)
      return analysis
    } catch (err: any) {
      error.value = err.message || 'Analysis failed'
      throw err
    } finally {
      isAnalyzing.value = false
    }
  }

  async function fetchAnalyses(filters?: Record<string, any>) {
    isLoading.value = true
    error.value = null
    try {
      const response = await api.get<AIAnalysis[]>(API_ENDPOINTS.AI_ANALYSES, filters ? { params: filters } : undefined)
      analyses.value = response as any
      return analyses.value
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch analyses'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  async function fetchAnalysis(id: string) {
    isLoading.value = true
    error.value = null
    try {
      const response = await api.get<AIAnalysis>(API_ENDPOINTS.AI_ANALYSIS(id))
      currentAnalysis.value = response as any
      return currentAnalysis.value
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch analysis'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  async function reviewAnalysis(id: string, reviewText: string) {
    try {
      const response = await api.put<AIAnalysis>(API_ENDPOINTS.AI_REVIEW(id), {
        review: { trainer_review: reviewText },
      })
      const updated = response as any
      const idx = analyses.value.findIndex((a) => a.id === id)
      if (idx > -1) analyses.value[idx] = updated
      if (currentAnalysis.value?.id === id) currentAnalysis.value = updated
      return updated
    } catch (err: any) {
      error.value = err.message || 'Review failed'
      throw err
    }
  }

  async function shareWithStudent(id: string) {
    try {
      const response = await api.post<AIAnalysis>(API_ENDPOINTS.AI_SHARE(id))
      const updated = response as any
      const idx = analyses.value.findIndex((a) => a.id === id)
      if (idx > -1) analyses.value[idx] = updated
      if (currentAnalysis.value?.id === id) currentAnalysis.value = updated
      return updated
    } catch (err: any) {
      error.value = err.message || 'Share failed'
      throw err
    }
  }

  async function fetchUsage() {
    try {
      const response = await api.get<AIUsage>(API_ENDPOINTS.AI_USAGE)
      usage.value = response as any
      return usage.value
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch usage'
      throw err
    }
  }

  return {
    analyses,
    currentAnalysis,
    usage,
    isLoading,
    isAnalyzing,
    error,
    analyzeVisual,
    analyzeTrends,
    analyzeDocument,
    fetchAnalyses,
    fetchAnalysis,
    reviewAnalysis,
    shareWithStudent,
    fetchUsage,
  }
})
