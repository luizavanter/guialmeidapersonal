<template>
  <div>
    <div class="mb-8">
      <h1 class="text-display-md text-smoke mb-2">{{ t('evolution.title') }}</h1>
    </div>

    <div v-if="isLoading && !evolutionStore.bodyAssessments.length" class="text-center py-12">
      <p class="text-stone">{{ t('common.loading') }}</p>
    </div>

    <div v-else class="space-y-6">
      <!-- Progress Charts -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card :title="t('evolution.weight')">
          <div v-if="weightHistory.length > 0" class="h-64">
            <Line :data="weightChartData" :options="chartOptions" />
          </div>
          <div v-else class="h-64 flex items-center justify-center text-stone">
            {{ t('evolution.noAssessments') }}
          </div>
        </Card>

        <Card :title="t('evolution.bodyFat')">
          <div v-if="bodyFatHistory.length > 0" class="h-64">
            <Line :data="bodyFatChartData" :options="chartOptions" />
          </div>
          <div v-else class="h-64 flex items-center justify-center text-stone">
            {{ t('evolution.noAssessments') }}
          </div>
        </Card>
      </div>

      <!-- Body Assessments -->
      <Card :title="t('evolution.bodyAssessments')">
        <div v-if="bodyAssessments.length > 0" class="space-y-3">
          <div
            v-for="assessment in bodyAssessments.slice(0, 5)"
            :key="assessment.id"
            class="p-4 bg-surface-2 rounded-lg border border-surface-3"
          >
            <div class="flex items-start justify-between mb-3">
              <p class="text-sm font-semibold text-smoke">
                {{ formatDate(assessment.assessment_date || assessment.assessmentDate) }}
              </p>
            </div>

            <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
              <div v-if="assessment.weight_kg || assessment.weight">
                <span class="text-stone">{{ t('evolution.weight') }}:</span>
                <span class="text-smoke font-mono ml-2">{{ formatWeight(assessment.weight_kg || assessment.weight) }}</span>
              </div>
              <div v-if="assessment.body_fat_percentage || assessment.bodyFat">
                <span class="text-stone">{{ t('evolution.bodyFat') }}:</span>
                <span class="text-smoke font-mono ml-2">{{ formatPercentage(assessment.body_fat_percentage || assessment.bodyFat) }}</span>
              </div>
              <div v-if="assessment.muscle_mass_kg || assessment.muscleMass">
                <span class="text-stone">{{ t('evolution.muscleMass') }}:</span>
                <span class="text-smoke font-mono ml-2">{{ formatWeight(assessment.muscle_mass_kg || assessment.muscleMass) }}</span>
              </div>
              <div v-if="assessment.bmr">
                <span class="text-stone">{{ t('evolution.bmr') }}:</span>
                <span class="text-smoke font-mono ml-2">{{ assessment.bmr }} kcal</span>
              </div>
            </div>

            <p v-if="assessment.notes" class="text-sm text-stone mt-3 italic">
              {{ assessment.notes }}
            </p>
          </div>
        </div>
        <div v-else class="text-center py-8 text-stone">
          {{ t('evolution.noAssessments') }}
        </div>
      </Card>

      <!-- Goals -->
      <Card :title="t('evolution.goals')">
        <div v-if="goals.length > 0" class="space-y-4">
          <div
            v-for="goal in goals"
            :key="goal.id"
            class="p-4 bg-surface-2 rounded-lg border border-surface-3"
          >
            <div class="flex items-start justify-between mb-2">
              <h3 class="text-lg font-semibold text-smoke">{{ goal.title }}</h3>
              <span
                :class="getGoalStatusClass(goal.status)"
                class="text-xs px-2 py-1 rounded-full font-medium"
              >
                {{ t(`evolution.${goal.status}`) }}
              </span>
            </div>

            <p v-if="goal.description" class="text-sm text-stone mb-3">
              {{ goal.description }}
            </p>

            <div class="flex flex-wrap gap-4 text-sm text-stone mb-3">
              <div v-if="goal.target_date || goal.targetDate">
                <span>{{ t('evolution.targetDate') }}:</span>
                <span class="text-smoke ml-1">{{ formatDate(goal.target_date || goal.targetDate) }}</span>
              </div>
            </div>

            <div v-if="(goal.target_value || goal.targetValue) && (goal.current_value || goal.currentValue)" class="space-y-2">
              <div class="flex justify-between text-sm text-stone">
                <span>{{ t('evolution.current') }}: {{ goal.current_value || goal.currentValue }} {{ goal.target_unit || goal.targetUnit }}</span>
                <span>{{ t('evolution.target') }}: {{ goal.target_value || goal.targetValue }} {{ goal.target_unit || goal.targetUnit }}</span>
              </div>
              <div class="w-full bg-surface-3 rounded-full h-3 overflow-hidden">
                <div
                  class="h-full bg-gradient-to-r from-lime to-ocean transition-all"
                  :style="{ width: `${getGoalProgress(goal)}%` }"
                ></div>
              </div>
              <p class="text-xs text-center text-stone">
                {{ t('evolution.percentComplete', { n: getGoalProgress(goal) }) }}
              </p>
            </div>
          </div>
        </div>
        <div v-else class="text-center py-8 text-stone">
          {{ t('evolution.noGoals') }}
        </div>
      </Card>

      <!-- Evolution Photos + Upload -->
      <Card>
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold text-smoke">{{ t('evolution.photos') }}</h3>
          <Button variant="primary" size="sm" @click="showPhotoUpload = true">
            {{ t('media.uploadPhoto') }}
          </Button>
        </div>

        <!-- Photo Upload Modal -->
        <div v-if="showPhotoUpload" class="mb-4 p-4 bg-surface-2 rounded-lg border border-surface-3">
          <div class="flex items-center justify-between mb-3">
            <h4 class="font-medium text-smoke">{{ t('media.uploadPhoto') }}</h4>
            <button @click="showPhotoUpload = false" class="text-stone hover:text-smoke">&times;</button>
          </div>
          <FileUpload
            ref="photoUploadRef"
            accept="image/jpeg,image/png,image/webp"
            :max-size-mb="10"
            :uploading="mediaStore.isUploading"
            :progress="mediaStore.uploadProgress"
            @file-selected="selectedPhotoFile = $event"
            @upload-start="handlePhotoUpload"
          />
          <p v-if="uploadSuccess" class="text-lime text-sm mt-2">{{ t('media.uploadSuccess') }}</p>
          <p v-if="mediaStore.error" class="text-red-400 text-sm mt-2">{{ mediaStore.error }}</p>
        </div>

        <div v-if="evolutionPhotos.length > 0 || mediaPhotos.length > 0" class="grid grid-cols-2 md:grid-cols-4 gap-4">
          <!-- Media files (uploaded via new system) -->
          <div
            v-for="media in mediaPhotos"
            :key="'m-' + media.id"
            class="relative aspect-square rounded-lg overflow-hidden bg-surface-2 border border-surface-3 hover:border-lime/30 transition-colors group cursor-pointer"
            @click="openMediaPhoto(media)"
          >
            <img
              v-if="thumbnailUrls[media.id]"
              :src="thumbnailUrls[media.id]"
              :alt="media.original_filename"
              class="w-full h-full object-cover"
            />
            <div v-else class="w-full h-full flex items-center justify-center bg-lime/5">
              <div v-if="loadingThumbnails" class="w-6 h-6 border-2 border-lime border-t-transparent rounded-full animate-spin"></div>
              <svg v-else class="w-8 h-8 text-lime/40" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <div class="absolute inset-0 bg-surface-1/90 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center p-2">
              <p class="text-xs text-smoke font-semibold truncate w-full text-center">{{ media.original_filename }}</p>
              <p class="text-xs text-stone">{{ formatFileDate(media.inserted_at) }}</p>
            </div>
          </div>

          <!-- Legacy evolution photos -->
          <div
            v-for="photo in evolutionPhotos"
            :key="photo.id"
            class="relative aspect-square rounded-lg overflow-hidden bg-surface-2 border border-surface-3 hover:border-lime/30 transition-colors group cursor-pointer"
          >
            <img
              :src="photo.photoUrl"
              :alt="`${photo.photoType} - ${formatDate(photo.photoDate)}`"
              class="w-full h-full object-cover"
            />
            <div class="absolute inset-0 bg-surface-1/90 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center p-2">
              <p class="text-xs text-smoke font-semibold">{{ photo.photoType }}</p>
              <p class="text-xs text-stone">{{ formatDate(photo.photoDate) }}</p>
            </div>
          </div>
        </div>
        <div v-else class="text-center py-8 text-stone">
          {{ t('evolution.noPhotos') }}
        </div>
      </Card>

      <!-- Documents & Exams Upload -->
      <Card>
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold text-smoke">{{ t('media.documents') }}</h3>
          <Button variant="primary" size="sm" @click="showDocUpload = true">
            {{ t('media.uploadExam') }}
          </Button>
        </div>

        <div v-if="showDocUpload" class="mb-4 p-4 bg-surface-2 rounded-lg border border-surface-3">
          <div class="flex items-center justify-between mb-3">
            <h4 class="font-medium text-smoke">{{ t('media.uploadExam') }}</h4>
            <button @click="showDocUpload = false" class="text-stone hover:text-smoke">&times;</button>
          </div>
          <FileUpload
            ref="docUploadRef"
            accept="image/jpeg,image/png,image/webp,application/pdf"
            :max-size-mb="10"
            :uploading="mediaStore.isUploading"
            :progress="mediaStore.uploadProgress"
            @file-selected="selectedDocFile = $event"
            @upload-start="handleDocUpload"
          />
          <p v-if="docUploadSuccess" class="text-lime text-sm mt-2">{{ t('media.uploadSuccess') }}</p>
        </div>

        <div v-if="mediaDocs.length > 0" class="space-y-2">
          <div
            v-for="doc in mediaDocs"
            :key="doc.id"
            class="flex items-center justify-between p-3 bg-surface-2 rounded-lg border border-surface-3"
          >
            <div class="flex items-center gap-3 min-w-0">
              <div class="w-8 h-8 bg-ocean/10 rounded flex items-center justify-center flex-shrink-0">
                <svg class="w-4 h-4 text-ocean" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <div class="min-w-0">
                <p class="text-sm text-smoke truncate">{{ doc.original_filename }}</p>
                <p class="text-xs text-stone">{{ formatFileDate(doc.inserted_at) }}</p>
              </div>
            </div>
            <button
              @click="downloadFile(doc.id)"
              class="text-ocean hover:text-ocean-light text-sm flex-shrink-0 ml-2"
            >
              {{ t('media.download') }}
            </button>
          </div>
        </div>
        <div v-else-if="!showDocUpload" class="text-center py-8 text-stone">
          {{ t('media.noFiles') }}
        </div>
      </Card>

      <!-- AI Analyses (shared by trainer) -->
      <Card :title="t('ai.analyses')">
        <div v-if="aiAnalyses.length > 0" class="space-y-4">
          <div
            v-for="analysis in aiAnalyses"
            :key="analysis.id"
            class="p-4 bg-surface-2 rounded-lg border border-surface-3"
          >
            <div class="flex items-start justify-between mb-3">
              <div>
                <p class="text-sm font-semibold text-smoke">
                  {{ getAnalysisTypeLabel(analysis.analysis_type) }}
                </p>
                <p class="text-xs text-stone">{{ formatFileDate(analysis.inserted_at) }}</p>
              </div>
              <span :class="getStatusClass(analysis.status)" class="text-xs px-2 py-1 rounded-full font-medium">
                {{ t(`ai.${analysis.status}`) }}
              </span>
            </div>

            <!-- Analysis Results -->
            <div v-if="analysis.status === 'completed' && analysis.result" class="space-y-2">
              <div v-if="analysis.result.body_composition" class="text-sm">
                <span class="text-stone">{{ t('ai.bodyComposition') }}:</span>
                <p class="text-smoke/90 ml-2">{{ analysis.result.body_composition }}</p>
              </div>
              <div v-if="analysis.result.muscle_development" class="text-sm">
                <span class="text-stone">{{ t('ai.muscleDevelopment') }}:</span>
                <p class="text-smoke/90 ml-2">{{ analysis.result.muscle_development }}</p>
              </div>
              <div v-if="analysis.result.overall_notes || analysis.result.summary" class="text-sm">
                <span class="text-stone">{{ t('ai.overallNotes') }}:</span>
                <p class="text-smoke/90 ml-2">{{ analysis.result.overall_notes || analysis.result.summary }}</p>
              </div>
              <div v-if="analysis.result.focus_areas" class="text-sm">
                <span class="text-stone">{{ t('ai.focusAreas') }}:</span>
                <p class="text-smoke/90 ml-2">{{ Array.isArray(analysis.result.focus_areas) ? analysis.result.focus_areas.join(', ') : analysis.result.focus_areas }}</p>
              </div>
            </div>

            <!-- Trainer Review -->
            <div v-if="analysis.trainer_review" class="mt-3 p-3 bg-lime/5 border border-lime/20 rounded-lg">
              <p class="text-xs text-lime font-medium mb-1">{{ t('ai.trainerReview') }}</p>
              <p class="text-sm text-smoke/90">{{ analysis.trainer_review }}</p>
            </div>

            <div v-if="analysis.confidence_score" class="mt-2 text-xs text-stone">
              {{ t('ai.confidence') }}: {{ Math.round(analysis.confidence_score * 100) }}%
            </div>
          </div>
        </div>
        <div v-else class="text-center py-8 text-stone">
          {{ t('ai.noAnalyses') }}
        </div>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { Line } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  type ChartOptions,
} from 'chart.js'
import { useEvolutionStore } from '@/stores/evolution'
import { useMediaStore } from '@/stores/media'
import { formatDate } from '@/utils/date'
import { formatWeight, formatPercentage } from '@/utils/format'
import Card from '@/components/ui/Card.vue'
import Button from '@/components/ui/Button.vue'
import FileUpload from '@/components/ui/FileUpload.vue'
import type { MediaFile } from '@/types'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend)

const { t } = useI18n()
const evolutionStore = useEvolutionStore()
const mediaStore = useMediaStore()

const bodyAssessments = computed(() => evolutionStore.bodyAssessments)
const evolutionPhotos = computed(() => evolutionStore.evolutionPhotos)
const goals = computed(() => evolutionStore.goals)
const isLoading = computed(() => evolutionStore.isLoading)
const aiAnalyses = computed(() => mediaStore.aiAnalyses)

const mediaPhotos = computed(() =>
  mediaStore.mediaFiles.filter((f) => f.file_type === 'evolution_photo' || f.content_type?.startsWith('image/'))
)
const mediaDocs = computed(() =>
  mediaStore.mediaFiles.filter((f) => f.file_type === 'medical_document' || f.file_type === 'bioimpedance_report' || f.content_type === 'application/pdf')
)

const showPhotoUpload = ref(false)
const showDocUpload = ref(false)
const selectedPhotoFile = ref<File | null>(null)
const selectedDocFile = ref<File | null>(null)
const uploadSuccess = ref(false)
const docUploadSuccess = ref(false)
const photoUploadRef = ref<InstanceType<typeof FileUpload>>()
const docUploadRef = ref<InstanceType<typeof FileUpload>>()
const thumbnailUrls = ref<Record<string, string>>({})
const loadingThumbnails = ref(false)

const weightHistory = computed(() => evolutionStore.getWeightHistory())
const bodyFatHistory = computed(() => evolutionStore.getBodyFatHistory())

const chartOptions: ChartOptions<'line'> = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { display: false } },
  scales: {
    x: { grid: { color: 'rgba(245, 245, 240, 0.1)' }, ticks: { color: 'rgba(245, 245, 240, 0.6)' } },
    y: { grid: { color: 'rgba(245, 245, 240, 0.1)' }, ticks: { color: 'rgba(245, 245, 240, 0.6)' } },
  },
}

const weightChartData = computed(() => ({
  labels: weightHistory.value.map((d) => formatDate(d.date)),
  datasets: [{
    label: t('evolution.weight'),
    data: weightHistory.value.map((d) => d.value),
    borderColor: '#CDFA3E',
    backgroundColor: 'rgba(196, 245, 58, 0.1)',
    tension: 0.4,
  }],
}))

const bodyFatChartData = computed(() => ({
  labels: bodyFatHistory.value.map((d) => formatDate(d.date)),
  datasets: [{
    label: t('evolution.bodyFat'),
    data: bodyFatHistory.value.map((d) => d.value),
    borderColor: '#0EA5E9',
    backgroundColor: 'rgba(14, 165, 233, 0.1)',
    tension: 0.4,
  }],
}))

const getGoalStatusClass = (status: string) => {
  const classes: Record<string, string> = {
    active: 'bg-lime/20 text-lime',
    completed: 'bg-green-500/20 text-green-500',
    abandoned: 'bg-red-500/20 text-red-500',
  }
  return classes[status] || classes.active
}

const getStatusClass = (status: string) => {
  const classes: Record<string, string> = {
    completed: 'bg-green-500/20 text-green-500',
    processing: 'bg-ocean/20 text-ocean',
    queued: 'bg-stone/20 text-stone',
    error: 'bg-red-500/20 text-red-500',
  }
  return classes[status] || 'bg-stone/20 text-stone'
}

const getGoalProgress = (goal: any) => {
  const target = parseFloat(goal.target_value || goal.targetValue)
  const current = parseFloat(goal.current_value || goal.currentValue)
  if (!target || !current) return 0
  return Math.min(Math.round((current / target) * 100), 100)
}

function getAnalysisTypeLabel(type: string) {
  const labels: Record<string, string> = {
    visual_body: t('ai.visualBody'),
    numeric_trends: t('ai.numericTrends'),
    medical_document: t('ai.medicalDocument'),
  }
  return labels[type] || type
}

function formatFileDate(dateStr: string) {
  if (!dateStr) return ''
  return new Date(dateStr).toLocaleDateString()
}

async function handlePhotoUpload() {
  if (!selectedPhotoFile.value) return
  uploadSuccess.value = false
  try {
    await mediaStore.uploadFile(selectedPhotoFile.value, 'evolution_photo')
    uploadSuccess.value = true
    selectedPhotoFile.value = null
    photoUploadRef.value?.clearFile()
    setTimeout(() => { showPhotoUpload.value = false; uploadSuccess.value = false }, 2000)
  } catch {
    // error shown from store
  }
}

async function handleDocUpload() {
  if (!selectedDocFile.value) return
  docUploadSuccess.value = false
  try {
    await mediaStore.uploadFile(selectedDocFile.value, 'medical_document')
    docUploadSuccess.value = true
    selectedDocFile.value = null
    docUploadRef.value?.clearFile()
    setTimeout(() => { showDocUpload.value = false; docUploadSuccess.value = false }, 2000)
  } catch {
    // error shown from store
  }
}

async function downloadFile(fileId: string) {
  try {
    const url = await mediaStore.getDownloadUrl(fileId)
    window.open(url, '_blank')
  } catch {
    // silent fail
  }
}

async function openMediaPhoto(media: MediaFile) {
  try {
    const url = thumbnailUrls.value[media.id] || await mediaStore.getDownloadUrl(media.id)
    window.open(url, '_blank')
  } catch {
    // silent fail
  }
}

async function loadThumbnails() {
  const photos = mediaPhotos.value
  if (!photos.length) return
  loadingThumbnails.value = true
  try {
    await Promise.all(
      photos.map(async (photo) => {
        try {
          const url = await mediaStore.getDownloadUrl(photo.id)
          thumbnailUrls.value[photo.id] = url
        } catch {
          // skip failed thumbnails
        }
      })
    )
  } finally {
    loadingThumbnails.value = false
  }
}

onMounted(async () => {
  await Promise.all([
    evolutionStore.fetchBodyAssessments(),
    evolutionStore.fetchEvolutionPhotos(),
    evolutionStore.fetchGoals(),
    mediaStore.fetchMyMedia().catch(() => {}),
    mediaStore.fetchAIAnalyses().catch(() => {}),
  ])
  // Load photo thumbnails after media is fetched
  await loadThumbnails()
})
</script>
