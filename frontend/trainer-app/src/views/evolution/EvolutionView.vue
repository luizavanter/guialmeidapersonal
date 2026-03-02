<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import { useStudentsStore } from '@/stores/studentsStore'
import { useMediaStore } from '@/stores/mediaStore'
import { useAIAnalysisStore } from '@/stores/aiAnalysisStore'
import { useBioimpedanceStore } from '@/stores/bioimpedanceStore'
import { FileUpload } from '@ga-personal/shared'
import { Activity, Camera, Target, Upload, Brain, FileText, TrendingUp, Share2, CheckCircle, XCircle, ArrowLeft, Trash2 } from 'lucide-vue-next'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const studentsStore = useStudentsStore()
const mediaStore = useMediaStore()
const aiStore = useAIAnalysisStore()
const bioStore = useBioimpedanceStore()

const studentId = computed(() => route.params.studentId as string)

// UI state
const showPhotoUpload = ref(false)
const showDocUpload = ref(false)
const showBioUpload = ref(false)
const selectedPhotoFile = ref<File | null>(null)
const selectedDocFile = ref<File | null>(null)
const selectedBioFile = ref<File | null>(null)
const selectedDeviceType = ref('anovator')
const showReviewModal = ref(false)
const reviewText = ref('')
const reviewingAnalysisId = ref('')
const uploadSuccess = ref('')
const photoUploadRef = ref<InstanceType<typeof FileUpload>>()
const docUploadRef = ref<InstanceType<typeof FileUpload>>()
const bioUploadRef = ref<InstanceType<typeof FileUpload>>()

const thumbnailUrls = ref<Record<string, string>>({})
const loadingThumbnails = ref(false)
const analysisError = ref('')
const analysisSuccess = ref('')

const deviceTypes = [
  { value: 'anovator', label: 'Anovator' },
  { value: 'relaxmedic', label: 'Relaxmedic Intelligence Plus' },
  { value: 'inbody', label: 'InBody' },
  { value: 'tanita', label: 'Tanita' },
  { value: 'omron', label: 'Omron' },
  { value: 'other', label: t('bioimpedance.other') },
]

const mediaPhotos = computed(() =>
  mediaStore.mediaFiles.filter((f: any) => f.file_type === 'evolution_photo' || (f.content_type?.startsWith('image/') && f.file_type !== 'document'))
)
const mediaDocs = computed(() =>
  mediaStore.mediaFiles.filter((f: any) => f.file_type === 'document' || f.file_type === 'medical_document' || f.content_type === 'application/pdf')
)

const currentStudent = computed(() =>
  studentsStore.students.find((s: any) => s.id === studentId.value)
)

onMounted(async () => {
  await studentsStore.fetchStudents()
  if (studentId.value) {
    loadStudentData()
  }
})

watch(studentId, (newId) => {
  if (newId) loadStudentData()
})

async function loadStudentData() {
  await Promise.all([
    mediaStore.fetchStudentMedia(studentId.value).catch(() => {}),
    aiStore.fetchAnalyses({ student_id: studentId.value }).catch(() => {}),
    bioStore.fetchImports({ student_id: studentId.value }).catch(() => {}),
    aiStore.fetchUsage().catch(() => {}),
  ])
  loadThumbnails()
}

async function loadThumbnails() {
  const photos = mediaPhotos.value
  if (!photos.length) return
  loadingThumbnails.value = true
  try {
    await Promise.all(
      photos.map(async (photo: any) => {
        try {
          const url = await mediaStore.getDownloadUrl(photo.id)
          thumbnailUrls.value[photo.id] = url
        } catch { /* skip failed thumbnails */ }
      })
    )
  } finally {
    loadingThumbnails.value = false
  }
}

function selectStudent(id: string) {
  router.push(`/evolution/${id}`)
}

function goBack() {
  router.push('/evolution')
}

// Photo upload
async function handlePhotoUpload() {
  if (!selectedPhotoFile.value) return
  try {
    const mediaFile = await mediaStore.uploadFile(selectedPhotoFile.value, 'evolution_photo', studentId.value)
    uploadSuccess.value = 'photo'
    selectedPhotoFile.value = null
    photoUploadRef.value?.clearFile()
    setTimeout(() => { showPhotoUpload.value = false; uploadSuccess.value = '' }, 2000)
  } catch { /* error from store */ }
}

// Document upload
async function handleDocUpload() {
  if (!selectedDocFile.value) return
  try {
    await mediaStore.uploadFile(selectedDocFile.value, 'medical_document', studentId.value)
    uploadSuccess.value = 'doc'
    selectedDocFile.value = null
    docUploadRef.value?.clearFile()
    setTimeout(() => { showDocUpload.value = false; uploadSuccess.value = '' }, 2000)
  } catch { /* error from store */ }
}

// Bioimpedance upload + extract
async function handleBioUpload() {
  if (!selectedBioFile.value) return
  try {
    const mediaFile = await mediaStore.uploadFile(selectedBioFile.value, 'bioimpedance_report', studentId.value)
    await bioStore.extractFromMedia(mediaFile.id, selectedDeviceType.value, studentId.value)
    uploadSuccess.value = 'bio'
    selectedBioFile.value = null
    bioUploadRef.value?.clearFile()
    setTimeout(() => { showBioUpload.value = false; uploadSuccess.value = '' }, 2000)
  } catch { /* error from store */ }
}

// AI actions
async function analyzeVisual(mediaFileId: string) {
  analysisError.value = ''
  analysisSuccess.value = ''
  try {
    await aiStore.analyzeVisual(mediaFileId, studentId.value)
    analysisSuccess.value = t('ai.analyzing')
    setTimeout(() => { analysisSuccess.value = '' }, 5000)
  } catch (err: any) {
    analysisError.value = err.message || 'Analysis failed'
    setTimeout(() => { analysisError.value = '' }, 5000)
  }
}

async function analyzeAllPhotos() {
  if (!mediaPhotos.value.length) return
  analysisError.value = ''
  analysisSuccess.value = ''
  try {
    for (const photo of mediaPhotos.value) {
      await aiStore.analyzeVisual(photo.id, studentId.value)
    }
    analysisSuccess.value = `${mediaPhotos.value.length} foto(s) enviadas para análise`
    setTimeout(() => { analysisSuccess.value = '' }, 5000)
  } catch (err: any) {
    analysisError.value = err.message || 'Analysis failed'
    setTimeout(() => { analysisError.value = '' }, 5000)
  }
}

async function analyzeAllDocs() {
  if (!mediaDocs.value.length) return
  analysisError.value = ''
  analysisSuccess.value = ''
  try {
    for (const doc of mediaDocs.value) {
      await aiStore.analyzeDocument(doc.id, studentId.value)
    }
    analysisSuccess.value = `${mediaDocs.value.length} documento(s) enviados para análise`
    setTimeout(() => { analysisSuccess.value = '' }, 5000)
  } catch (err: any) {
    analysisError.value = err.message || 'Analysis failed'
    setTimeout(() => { analysisError.value = '' }, 5000)
  }
}

async function analyzeTrends() {
  analysisError.value = ''
  analysisSuccess.value = ''
  try {
    await aiStore.analyzeTrends(studentId.value)
    analysisSuccess.value = t('ai.analyzing')
    setTimeout(() => { analysisSuccess.value = '' }, 5000)
  } catch (err: any) {
    analysisError.value = err.message || 'Analysis failed'
    setTimeout(() => { analysisError.value = '' }, 5000)
  }
}

async function analyzeDocument(mediaFileId: string) {
  analysisError.value = ''
  analysisSuccess.value = ''
  try {
    await aiStore.analyzeDocument(mediaFileId, studentId.value)
    analysisSuccess.value = t('ai.analyzing')
    setTimeout(() => { analysisSuccess.value = '' }, 5000)
  } catch (err: any) {
    analysisError.value = err.message || 'Analysis failed'
    setTimeout(() => { analysisError.value = '' }, 5000)
  }
}

function openReviewModal(analysisId: string) {
  reviewingAnalysisId.value = analysisId
  const existing = aiStore.analyses.find((a: any) => a.id === analysisId)
  reviewText.value = existing?.trainer_review || ''
  showReviewModal.value = true
}

async function submitReview() {
  if (!reviewingAnalysisId.value) return
  await aiStore.reviewAnalysis(reviewingAnalysisId.value, reviewText.value)
  showReviewModal.value = false
  reviewText.value = ''
}

async function shareAnalysis(id: string) {
  await aiStore.shareWithStudent(id)
}

async function applyBioImport(id: string) {
  await bioStore.applyImport(id)
}

async function rejectBioImport(id: string) {
  await bioStore.rejectImport(id)
}

async function downloadFile(fileId: string) {
  try {
    const url = await mediaStore.getDownloadUrl(fileId)
    window.open(url, '_blank')
  } catch { /* silent */ }
}

async function deleteMedia(fileId: string) {
  if (!confirm(t('common.confirmDelete') || 'Tem certeza que deseja excluir?')) return
  try {
    await mediaStore.deleteFile(fileId)
    if (studentId.value) {
      await mediaStore.fetchStudentMedia(studentId.value)
      loadThumbnails()
    }
  } catch { /* silent */ }
}

async function deleteAIAnalysis(analysisId: string) {
  if (!confirm(t('common.confirmDelete') || 'Tem certeza que deseja excluir?')) return
  try {
    await aiStore.deleteAnalysis(analysisId)
  } catch { /* silent */ }
}

function getStatusClass(status: string) {
  const classes: Record<string, string> = {
    completed: 'bg-green-500/20 text-green-500',
    processing: 'bg-ocean/20 text-ocean',
    queued: 'bg-stone/20 text-stone',
    error: 'bg-red-500/20 text-red-500',
    failed: 'bg-red-500/20 text-red-500',
    extracted: 'bg-lime/20 text-lime',
    applied: 'bg-green-500/20 text-green-500',
    rejected: 'bg-red-500/20 text-red-500',
    extracting: 'bg-ocean/20 text-ocean',
    pending_extraction: 'bg-stone/20 text-stone',
  }
  return classes[status] || 'bg-stone/20 text-stone'
}

function getAnalysisTypeLabel(type: string) {
  const labels: Record<string, string> = {
    visual_body: t('ai.analyzeVisual'),
    numeric_trends: t('ai.analyzeTrends'),
    medical_document: t('ai.analyzeDocument'),
  }
  return labels[type] || type
}

function formatFileDate(dateStr: string) {
  if (!dateStr) return ''
  return new Date(dateStr).toLocaleDateString()
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center gap-4">
      <button v-if="studentId" @click="goBack" class="p-2 text-stone hover:text-smoke rounded-lg hover:bg-surface-2 transition-colors">
        <ArrowLeft :size="20" />
      </button>
      <h1 class="text-display-md text-smoke">{{ t('evolution.title') }}</h1>
      <span v-if="currentStudent" class="text-stone text-lg">
        — {{ currentStudent.user?.firstName }} {{ currentStudent.user?.lastName }}
      </span>
    </div>

    <!-- Student Selection -->
    <div v-if="!studentId">
      <p class="text-stone mb-6">{{ t('evolution.selectStudent') }}</p>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        <div
          v-for="student in studentsStore.students"
          :key="student.id"
          @click="selectStudent(student.id)"
          class="card hover:border-lime/30 cursor-pointer transition-all"
        >
          <div class="flex items-center space-x-4">
            <div class="w-10 h-10 bg-ocean/15 border border-ocean/20 rounded-full flex items-center justify-center text-ocean text-sm font-semibold">
              {{ student.user?.firstName?.[0] }}{{ student.user?.lastName?.[0] }}
            </div>
            <div>
              <h3 class="font-medium text-sm text-smoke">{{ student.user?.firstName }} {{ student.user?.lastName }}</h3>
              <p class="text-xs text-stone">{{ student.user?.email }}</p>
            </div>
          </div>
        </div>
      </div>

      <div v-if="studentsStore.students.length === 0" class="card text-center py-12">
        <p class="text-stone">{{ t('students.noStudentsFound') }}</p>
      </div>
    </div>

    <!-- Student Evolution Dashboard -->
    <div v-else class="space-y-6">

      <!-- Photos Section -->
      <div class="card">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-3">
            <Camera :size="20" class="text-ocean" />
            <h2 class="font-display text-xl text-smoke">{{ t('evolution.photos') }}</h2>
          </div>
          <div class="flex items-center gap-2">
            <button
              v-if="mediaPhotos.length > 0"
              @click="analyzeAllPhotos"
              :disabled="aiStore.isAnalyzing"
              class="btn btn-ghost text-sm border border-lime/30 text-lime hover:bg-lime/10"
            >
              <Brain :size="16" class="mr-1" /> Analisar Todas ({{ mediaPhotos.length }})
            </button>
            <button @click="showPhotoUpload = !showPhotoUpload" class="btn btn-primary text-sm">
              <Upload :size="16" class="mr-1" /> {{ t('media.uploadPhoto') }}
            </button>
          </div>
        </div>

        <div v-if="showPhotoUpload" class="mb-4 p-4 bg-surface-2 rounded-lg border border-surface-3">
          <FileUpload
            ref="photoUploadRef"
            accept="image/jpeg,image/png,image/webp"
            :max-size-mb="10"
            :uploading="mediaStore.isUploading"
            :progress="mediaStore.uploadProgress"
            @file-selected="selectedPhotoFile = $event"
            @upload-start="handlePhotoUpload"
          />
          <p v-if="uploadSuccess === 'photo'" class="text-lime text-sm mt-2">{{ t('media.uploadSuccess') }}</p>
          <p v-if="mediaStore.error" class="text-red-400 text-sm mt-2">{{ mediaStore.error }}</p>
        </div>

        <div v-if="mediaPhotos.length > 0" class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-3">
          <div
            v-for="photo in mediaPhotos"
            :key="photo.id"
            class="relative aspect-square rounded-lg overflow-hidden bg-surface-2 border border-surface-3 group"
          >
            <div class="w-full h-full flex items-center justify-center cursor-pointer" @click="downloadFile(photo.id)">
              <img
                v-if="thumbnailUrls[photo.id]"
                :src="thumbnailUrls[photo.id]"
                :alt="photo.original_filename"
                class="w-full h-full object-cover"
              />
              <div v-else-if="loadingThumbnails" class="w-6 h-6 border-2 border-lime border-t-transparent rounded-full animate-spin"></div>
              <Camera v-else :size="24" class="text-lime/40" />
            </div>
            <div class="absolute bottom-0 left-0 right-0 bg-surface-1/90 p-2">
              <p class="text-xs text-smoke truncate">{{ photo.original_filename }}</p>
              <div class="flex items-center justify-between mt-1">
                <p class="text-xs text-stone">{{ formatFileDate(photo.inserted_at) }}</p>
                <button
                  @click.stop="deleteMedia(photo.id)"
                  class="text-xs text-red-400 hover:text-red-300"
                  :title="t('common.delete')"
                >
                  <Trash2 :size="14" />
                </button>
              </div>
            </div>
          </div>
        </div>
        <p v-else class="text-center py-6 text-stone">{{ t('evolution.noPhotos') || t('media.noFiles') }}</p>
      </div>

      <!-- Bioimpedance Section -->
      <div class="card">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-3">
            <Activity :size="20" class="text-lime" />
            <h2 class="font-display text-xl text-smoke">{{ t('bioimpedance.import') }}</h2>
          </div>
          <button @click="showBioUpload = !showBioUpload" class="btn btn-primary text-sm">
            <Upload :size="16" class="mr-1" /> {{ t('media.uploadExam') }}
          </button>
        </div>

        <div v-if="showBioUpload" class="mb-4 p-4 bg-surface-2 rounded-lg border border-surface-3 space-y-3">
          <div>
            <label class="block text-sm font-medium text-smoke mb-1">{{ t('bioimpedance.deviceType') }}</label>
            <select v-model="selectedDeviceType" class="input w-full">
              <option v-for="device in deviceTypes" :key="device.value" :value="device.value">
                {{ device.label }}
              </option>
            </select>
          </div>
          <FileUpload
            ref="bioUploadRef"
            accept="image/jpeg,image/png,image/webp,application/pdf"
            :max-size-mb="10"
            :uploading="mediaStore.isUploading"
            :progress="mediaStore.uploadProgress"
            @file-selected="selectedBioFile = $event"
            @upload-start="handleBioUpload"
          />
          <p v-if="uploadSuccess === 'bio'" class="text-lime text-sm">{{ t('media.uploadSuccess') }}</p>
        </div>

        <div v-if="bioStore.imports.length > 0" class="space-y-3">
          <div
            v-for="imp in bioStore.imports"
            :key="imp.id"
            class="p-4 bg-surface-2 rounded-lg border border-surface-3"
          >
            <div class="flex items-start justify-between mb-2">
              <div>
                <p class="text-sm font-medium text-smoke">{{ imp.device_type }} — {{ formatFileDate(imp.inserted_at) }}</p>
              </div>
              <span :class="getStatusClass(imp.status)" class="text-xs px-2 py-1 rounded-full font-medium">
                {{ t(`bioimpedance.${imp.status}`) || imp.status }}
              </span>
            </div>

            <!-- Extracted data preview -->
            <div v-if="imp.status === 'extracted' && imp.extracted_data" class="mt-3 p-3 bg-[#1a1a1a] rounded-lg">
              <p class="text-xs font-medium text-smoke mb-2">{{ t('bioimpedance.reviewData') }}</p>
              <div class="grid grid-cols-2 md:grid-cols-4 gap-2 text-xs">
                <div v-for="(value, key) in imp.extracted_data" :key="key">
                  <span class="text-stone">{{ key }}:</span>
                  <span class="text-smoke ml-1 font-mono">{{ value }}</span>
                </div>
              </div>
              <div class="flex gap-2 mt-3">
                <button @click="applyBioImport(imp.id)" class="btn btn-primary text-xs px-3 py-1">
                  <CheckCircle :size="14" class="mr-1" /> {{ t('bioimpedance.apply') }}
                </button>
                <button @click="rejectBioImport(imp.id)" class="btn btn-ghost text-xs px-3 py-1 text-red-400">
                  <XCircle :size="14" class="mr-1" /> {{ t('bioimpedance.reject') }}
                </button>
              </div>
            </div>

            <div v-if="imp.confidence_score" class="mt-2 text-xs text-stone">
              {{ t('ai.confidence') }}: {{ Math.round(imp.confidence_score * 100) }}%
            </div>
          </div>
        </div>
        <p v-else-if="!showBioUpload" class="text-center py-6 text-stone">{{ t('bioimpedance.noImports') }}</p>
      </div>

      <!-- Documents Section -->
      <div class="card">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-3">
            <FileText :size="20" class="text-ocean" />
            <h2 class="font-display text-xl text-smoke">{{ t('media.documents') }}</h2>
          </div>
          <div class="flex items-center gap-2">
            <button
              v-if="mediaDocs.length > 0"
              @click="analyzeAllDocs"
              :disabled="aiStore.isAnalyzing"
              class="btn btn-ghost text-sm border border-lime/30 text-lime hover:bg-lime/10"
            >
              <Brain :size="16" class="mr-1" /> Analisar Todos ({{ mediaDocs.length }})
            </button>
            <button @click="showDocUpload = !showDocUpload" class="btn btn-primary text-sm">
              <Upload :size="16" class="mr-1" /> {{ t('media.uploadDocument') }}
            </button>
          </div>
        </div>

        <div v-if="showDocUpload" class="mb-4 p-4 bg-surface-2 rounded-lg border border-surface-3">
          <FileUpload
            ref="docUploadRef"
            accept="image/jpeg,image/png,image/webp,application/pdf"
            :max-size-mb="10"
            :uploading="mediaStore.isUploading"
            :progress="mediaStore.uploadProgress"
            @file-selected="selectedDocFile = $event"
            @upload-start="handleDocUpload"
          />
          <p v-if="uploadSuccess === 'doc'" class="text-lime text-sm mt-2">{{ t('media.uploadSuccess') }}</p>
        </div>

        <div v-if="mediaDocs.length > 0" class="space-y-2">
          <div
            v-for="doc in mediaDocs"
            :key="doc.id"
            class="flex items-center justify-between p-3 bg-surface-2 rounded-lg border border-surface-3"
          >
            <div class="flex items-center gap-3 min-w-0">
              <div class="w-8 h-8 bg-ocean/10 rounded flex items-center justify-center flex-shrink-0">
                <FileText :size="16" class="text-ocean" />
              </div>
              <div class="min-w-0">
                <p class="text-sm text-smoke truncate">{{ doc.original_filename }}</p>
                <p class="text-xs text-stone">{{ formatFileDate(doc.inserted_at) }}</p>
              </div>
            </div>
            <div class="flex items-center gap-2 flex-shrink-0 ml-2">
              <button @click="downloadFile(doc.id)" class="text-ocean hover:text-ocean-light text-sm">
                {{ t('media.download') }}
              </button>
              <button @click="deleteMedia(doc.id)" class="text-red-400 hover:text-red-300 text-sm" :title="t('common.delete')">
                <Trash2 :size="16" />
              </button>
            </div>
          </div>
        </div>
        <p v-else-if="!showDocUpload" class="text-center py-6 text-stone">{{ t('media.noFiles') }}</p>
      </div>

      <!-- Trends Analysis -->
      <div class="card">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-3">
            <TrendingUp :size="20" class="text-lime" />
            <h2 class="font-display text-xl text-smoke">{{ t('ai.analyzeTrends') }}</h2>
          </div>
          <button @click="analyzeTrends" :disabled="aiStore.isAnalyzing" class="btn btn-primary text-sm">
            <Brain :size="16" class="mr-1" />
            {{ aiStore.isAnalyzing ? t('ai.analyzing') : t('ai.generateTrends') }}
          </button>
        </div>
        <p class="text-sm text-stone">Analisa dados numéricos do aluno (avaliações corporais, bioimpedância, peso, gordura) para identificar tendências de progresso, alertas de saúde e recomendações de treino.</p>
        <p v-if="analysisSuccess" class="text-lime text-sm mt-2">{{ analysisSuccess }}</p>
        <p v-if="analysisError" class="text-red-400 text-sm mt-2">{{ analysisError }}</p>
        <p v-if="aiStore.error" class="text-red-400 text-sm mt-2">{{ aiStore.error }}</p>
      </div>

      <!-- AI Analyses List -->
      <div class="card">
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-3">
            <Brain :size="20" class="text-lime" />
            <h2 class="font-display text-xl text-smoke">{{ t('ai.analyses') }}</h2>
          </div>
          <div v-if="aiStore.usage" class="text-xs text-stone bg-surface-2 px-3 py-1 rounded-full">
            Créditos IA: {{ aiStore.usage.rate_limit?.limit ? (aiStore.usage.rate_limit.limit - (aiStore.usage.rate_limit.used ?? 0)) : 10 }} restantes/hora
          </div>
        </div>

        <div v-if="aiStore.analyses.length > 0" class="space-y-4">
          <div
            v-for="analysis in aiStore.analyses"
            :key="analysis.id"
            class="p-4 bg-surface-2 rounded-lg border border-surface-3"
          >
            <div class="flex items-start justify-between mb-2">
              <div>
                <p class="text-sm font-medium text-smoke">{{ getAnalysisTypeLabel(analysis.analysis_type) }}</p>
                <p class="text-xs text-stone">{{ formatFileDate(analysis.inserted_at) }}</p>
              </div>
              <span :class="getStatusClass(analysis.status)" class="text-xs px-2 py-1 rounded-full font-medium">
                {{ t(`ai.${analysis.status}`) || analysis.status }}
              </span>
            </div>

            <!-- Failed status message -->
            <div v-if="analysis.status === 'failed'" class="mt-2 p-2 bg-red-500/10 border border-red-500/20 rounded text-sm text-red-400">
              {{ analysis.result?.error || 'Análise falhou. Tente novamente.' }}
            </div>

            <!-- Results -->
            <div v-if="analysis.status === 'completed' && analysis.result" class="mt-3 space-y-2 text-sm">
              <div v-if="analysis.result.body_composition">
                <span class="text-stone font-medium">{{ t('ai.bodyComposition') }}:</span>
                <template v-if="typeof analysis.result.body_composition === 'object'">
                  <p v-for="(val, key) in analysis.result.body_composition" :key="key" class="text-smoke/90 ml-2">{{ val }}</p>
                </template>
                <p v-else class="text-smoke/90 ml-2">{{ analysis.result.body_composition }}</p>
              </div>
              <div v-if="analysis.result.muscle_development">
                <span class="text-stone font-medium">{{ t('ai.muscleDevelopment') }}:</span>
                <template v-if="typeof analysis.result.muscle_development === 'object'">
                  <div v-for="(val, key) in analysis.result.muscle_development" :key="key" class="ml-2">
                    <template v-if="Array.isArray(val)">
                      <ul class="list-disc list-inside text-smoke/90">
                        <li v-for="(item, i) in val" :key="i">{{ item }}</li>
                      </ul>
                    </template>
                    <p v-else class="text-smoke/90">{{ val }}</p>
                  </div>
                </template>
                <p v-else class="text-smoke/90 ml-2">{{ analysis.result.muscle_development }}</p>
              </div>
              <div v-if="analysis.result.posture_alignment">
                <span class="text-stone font-medium">{{ t('ai.postureAlignment') }}:</span>
                <template v-if="typeof analysis.result.posture_alignment === 'object'">
                  <div v-for="(val, key) in analysis.result.posture_alignment" :key="key" class="ml-2">
                    <template v-if="Array.isArray(val)">
                      <ul class="list-disc list-inside text-smoke/90">
                        <li v-for="(item, i) in val" :key="i">{{ item }}</li>
                      </ul>
                    </template>
                    <p v-else class="text-smoke/90">{{ val }}</p>
                  </div>
                </template>
                <p v-else class="text-smoke/90 ml-2">{{ analysis.result.posture_alignment }}</p>
              </div>
              <div v-if="analysis.result.overall_notes || analysis.result.summary">
                <span class="text-stone font-medium">{{ t('ai.overallNotes') }}:</span>
                <p class="text-smoke/90 ml-2">{{ analysis.result.overall_notes || analysis.result.summary }}</p>
              </div>
              <div v-if="analysis.result.focus_areas">
                <span class="text-stone font-medium">{{ t('ai.focusAreas') }}:</span>
                <ul v-if="Array.isArray(analysis.result.focus_areas)" class="list-disc list-inside text-smoke/90 ml-2">
                  <li v-for="(area, i) in analysis.result.focus_areas" :key="i">{{ area }}</li>
                </ul>
                <p v-else class="text-smoke/90 ml-2">{{ analysis.result.focus_areas }}</p>
              </div>
              <div v-if="analysis.result.confidence" class="text-xs text-stone mt-1">
                {{ t('ai.confidence') }}: {{ Math.round(analysis.result.confidence * 100) }}%
              </div>

              <!-- Document analysis results (extraction + analysis) -->
              <template v-if="analysis.result.extraction || analysis.result.analysis">
                <div v-if="analysis.result.extraction?.values?.length" class="mt-2">
                  <span class="text-stone font-medium">Valores Extraídos:</span>
                  <div class="mt-1 grid grid-cols-1 sm:grid-cols-2 gap-1 ml-2">
                    <div v-for="(val, i) in analysis.result.extraction.values" :key="i" class="text-xs">
                      <span class="text-smoke">{{ val.name }}:</span>
                      <span class="font-medium" :class="val.status === 'normal' ? 'text-green-400' : val.status === 'critical' ? 'text-red-400' : 'text-yellow-400'">
                        {{ val.value }} {{ val.unit }}
                      </span>
                      <span v-if="val.reference_range" class="text-stone/60"> (ref: {{ val.reference_range }})</span>
                    </div>
                  </div>
                </div>
                <div v-if="analysis.result.analysis?.fitness_relevant_observations?.length">
                  <span class="text-stone font-medium">Observações Fitness:</span>
                  <ul class="list-disc list-inside text-smoke/90 ml-2">
                    <li v-for="(obs, i) in analysis.result.analysis.fitness_relevant_observations" :key="i">{{ obs }}</li>
                  </ul>
                </div>
                <div v-if="analysis.result.analysis?.exercise_considerations?.length">
                  <span class="text-stone font-medium">Considerações para Exercício:</span>
                  <ul class="list-disc list-inside text-smoke/90 ml-2">
                    <li v-for="(c, i) in analysis.result.analysis.exercise_considerations" :key="i">{{ c }}</li>
                  </ul>
                </div>
                <div v-if="analysis.result.analysis?.nutritional_indicators?.length">
                  <span class="text-stone font-medium">Indicadores Nutricionais:</span>
                  <ul class="list-disc list-inside text-smoke/90 ml-2">
                    <li v-for="(n, i) in analysis.result.analysis.nutritional_indicators" :key="i">{{ n }}</li>
                  </ul>
                </div>
                <div v-if="analysis.result.analysis?.requires_medical_attention?.length" class="p-2 bg-red-500/10 border border-red-500/20 rounded">
                  <span class="text-red-400 font-medium">Requer Atenção Médica:</span>
                  <ul class="list-disc list-inside text-red-300 ml-2">
                    <li v-for="(a, i) in analysis.result.analysis.requires_medical_attention" :key="i">{{ a }}</li>
                  </ul>
                </div>
                <div v-if="analysis.result.analysis?.overall_fitness_clearance">
                  <span class="text-stone font-medium">Liberação Fitness:</span>
                  <span :class="{
                    'text-green-400': analysis.result.analysis.overall_fitness_clearance === 'cleared',
                    'text-yellow-400': analysis.result.analysis.overall_fitness_clearance === 'caution',
                    'text-red-400': analysis.result.analysis.overall_fitness_clearance === 'needs_review'
                  }" class="ml-1 font-medium">
                    {{ analysis.result.analysis.overall_fitness_clearance === 'cleared' ? 'Liberado' : analysis.result.analysis.overall_fitness_clearance === 'caution' ? 'Cautela' : 'Necessita Revisão' }}
                  </span>
                </div>
              </template>
            </div>

            <!-- Trainer review -->
            <div v-if="analysis.trainer_review" class="mt-3 p-3 bg-lime/5 border border-lime/20 rounded-lg">
              <p class="text-xs text-lime font-medium mb-1">{{ t('ai.trainerReview') }}</p>
              <p class="text-sm text-smoke/90">{{ analysis.trainer_review }}</p>
            </div>

            <!-- Actions -->
            <div class="flex items-center gap-3 mt-3 pt-3 border-t border-surface-3">
              <template v-if="analysis.status === 'completed'">
                <button @click="openReviewModal(analysis.id)" class="text-sm text-ocean hover:text-ocean-light flex items-center gap-1">
                  <FileText :size="14" /> {{ t('ai.review') }}
                </button>
                <button
                  v-if="!analysis.visible_to_student"
                  @click="shareAnalysis(analysis.id)"
                  class="text-sm text-lime hover:text-lime-dark flex items-center gap-1"
                >
                  <Share2 :size="14" /> {{ t('ai.share') }}
                </button>
                <span v-else class="text-xs text-green-500 flex items-center gap-1">
                  <CheckCircle :size="14" /> {{ t('ai.sharedWithStudent') }}
                </span>
                <span v-if="analysis.confidence_score" class="text-xs text-stone ml-auto">
                  {{ t('ai.confidence') }}: {{ Math.round(analysis.confidence_score * 100) }}%
                </span>
              </template>
              <button
                @click="deleteAIAnalysis(analysis.id)"
                class="text-sm text-red-400 hover:text-red-300 flex items-center gap-1"
                :class="{ 'ml-auto': analysis.status !== 'completed' }"
              >
                <Trash2 :size="14" /> {{ t('common.delete') }}
              </button>
            </div>
          </div>
        </div>
        <p v-else class="text-center py-6 text-stone">{{ t('ai.noAnalyses') }}</p>
      </div>
    </div>

    <!-- Review Modal -->
    <div v-if="showReviewModal" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="showReviewModal = false"></div>
      <div class="relative bg-surface-1 border border-surface-3 rounded-xl p-6 w-full max-w-lg mx-4">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-lime">{{ t('ai.review') }}</h2>
          <button @click="showReviewModal = false" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-smoke mb-2">{{ t('ai.trainerReview') }}</label>
            <textarea
              v-model="reviewText"
              class="input w-full"
              rows="6"
              :placeholder="t('ai.trainerReview')"
            ></textarea>
          </div>
          <div class="flex justify-end gap-3">
            <button @click="showReviewModal = false" class="btn btn-ghost">{{ t('common.cancel') }}</button>
            <button @click="submitReview" class="btn btn-primary">{{ t('common.save') }}</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
