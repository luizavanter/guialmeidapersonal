import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '@/lib/api'
import { API_ENDPOINTS } from '@/constants/api'
import type { MediaFile, UploadUrlResponse, AIAnalysis } from '@/types'

export const useMediaStore = defineStore('media', () => {
  const mediaFiles = ref<MediaFile[]>([])
  const aiAnalyses = ref<AIAnalysis[]>([])
  const isLoading = ref(false)
  const isUploading = ref(false)
  const uploadProgress = ref(0)
  const error = ref<string | null>(null)

  const fetchMyMedia = async (fileType?: string) => {
    isLoading.value = true
    error.value = null
    try {
      const params = fileType ? { file_type: fileType } : undefined
      const response = await api.get<MediaFile[]>(API_ENDPOINTS.MY_MEDIA, params)
      mediaFiles.value = response.data
    } catch (err: any) {
      error.value = api.handleError(err)[0]?.message || 'Failed to fetch media'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const uploadFile = async (file: File, fileType: string): Promise<MediaFile> => {
    isUploading.value = true
    uploadProgress.value = 0
    error.value = null

    try {
      // Step 1: Get signed upload URL
      uploadProgress.value = 10
      const urlResponse = await api.post<UploadUrlResponse>(API_ENDPOINTS.MEDIA_UPLOAD_URL, {
        media: {
          file_type: fileType,
          content_type: file.type,
          original_filename: file.name,
          file_size_bytes: file.size,
        },
      })
      const { upload_url, file_id } = urlResponse.data

      // Step 2: Upload directly to GCS
      uploadProgress.value = 30
      await fetch(upload_url, {
        method: 'PUT',
        headers: { 'Content-Type': file.type },
        body: file,
      })

      // Step 3: Confirm upload
      uploadProgress.value = 80
      const confirmResponse = await api.post<MediaFile>(API_ENDPOINTS.MEDIA_CONFIRM, {
        media: { file_id },
      })
      uploadProgress.value = 100

      const mediaFile = confirmResponse.data
      mediaFiles.value.unshift(mediaFile)
      return mediaFile
    } catch (err: any) {
      error.value = api.handleError(err)[0]?.message || 'Upload failed'
      throw err
    } finally {
      isUploading.value = false
    }
  }

  const getDownloadUrl = async (fileId: string): Promise<string> => {
    const response = await api.get<{ download_url: string }>(API_ENDPOINTS.MEDIA_DOWNLOAD(fileId))
    return response.data.download_url
  }

  const fetchAIAnalyses = async () => {
    isLoading.value = true
    error.value = null
    try {
      const response = await api.get<AIAnalysis[]>(API_ENDPOINTS.AI_ANALYSES)
      aiAnalyses.value = response.data
    } catch (err: any) {
      error.value = api.handleError(err)[0]?.message || 'Failed to fetch analyses'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  return {
    mediaFiles,
    aiAnalyses,
    isLoading,
    isUploading,
    uploadProgress,
    error,
    fetchMyMedia,
    uploadFile,
    getDownloadUrl,
    fetchAIAnalyses,
  }
})
