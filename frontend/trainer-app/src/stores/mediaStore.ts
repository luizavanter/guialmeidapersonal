import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useApi } from '@ga-personal/shared'
import { API_ENDPOINTS } from '@ga-personal/shared'
import type { MediaFile, UploadUrlResponse } from '@ga-personal/shared'

export const useMediaStore = defineStore('media', () => {
  const api = useApi()

  const mediaFiles = ref<MediaFile[]>([])
  const isLoading = ref(false)
  const isUploading = ref(false)
  const uploadProgress = ref(0)
  const error = ref<string | null>(null)

  async function fetchStudentMedia(studentId: string, fileType?: string) {
    isLoading.value = true
    error.value = null
    try {
      const params = fileType ? { params: { file_type: fileType } } : undefined
      const response = await api.get<MediaFile[]>(API_ENDPOINTS.STUDENT_MEDIA(studentId), params)
      mediaFiles.value = response as any
      return mediaFiles.value
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch media'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  async function uploadFile(file: File, fileType: string, studentId: string): Promise<MediaFile> {
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
          student_id: studentId,
        },
      })
      const data = urlResponse as any
      const upload_url = data.upload_url
      const file_id = data.file_id

      // Step 2: Upload directly to GCS
      uploadProgress.value = 30
      await fetch(upload_url, {
        method: 'PUT',
        headers: { 'Content-Type': file.type },
        body: file,
      })

      // Step 3: Confirm upload
      uploadProgress.value = 80
      const mediaFile = await api.post<MediaFile>(API_ENDPOINTS.MEDIA_CONFIRM, {
        media: { file_id },
      })
      uploadProgress.value = 100

      mediaFiles.value.unshift(mediaFile as any)
      return mediaFile as any
    } catch (err: any) {
      error.value = err.message || 'Upload failed'
      throw err
    } finally {
      isUploading.value = false
    }
  }

  async function getDownloadUrl(fileId: string): Promise<string> {
    const response = await api.get<{ download_url: string }>(API_ENDPOINTS.MEDIA_DOWNLOAD(fileId))
    return (response as any).download_url
  }

  async function deleteFile(fileId: string) {
    try {
      await api.delete(API_ENDPOINTS.MEDIA_DELETE(fileId))
      mediaFiles.value = mediaFiles.value.filter((f) => f.id !== fileId)
    } catch (err: any) {
      error.value = err.message || 'Failed to delete file'
      throw err
    }
  }

  return {
    mediaFiles,
    isLoading,
    isUploading,
    uploadProgress,
    error,
    fetchStudentMedia,
    uploadFile,
    getDownloadUrl,
    deleteFile,
  }
})
