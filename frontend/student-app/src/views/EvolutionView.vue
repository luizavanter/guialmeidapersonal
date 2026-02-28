<template>
  <div>
    <div class="mb-8">
      <h1 class="text-display-md text-smoke mb-2">{{ t('evolution.title') }}</h1>
    </div>

    <div v-if="isLoading" class="text-center py-12">
      <p class="text-stone">{{ t('common.loading') }}</p>
    </div>

    <div v-else class="space-y-6">
      <!-- Progress Charts -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Weight Chart -->
        <Card :title="t('evolution.weight')">
          <div v-if="weightHistory.length > 0" class="h-64">
            <Line :data="weightChartData" :options="chartOptions" />
          </div>
          <div v-else class="h-64 flex items-center justify-center text-stone">
            {{ t('evolution.noAssessments') }}
          </div>
        </Card>

        <!-- Body Fat Chart -->
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
              <div>
                <p class="text-sm font-semibold text-smoke">
                  {{ formatDate(assessment.assessment_date || assessment.assessmentDate) }}
                </p>
              </div>
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

      <!-- Evolution Photos -->
      <Card :title="t('evolution.photos')">
        <div v-if="evolutionPhotos.length > 0" class="grid grid-cols-2 md:grid-cols-4 gap-4">
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
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, computed } from 'vue'
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
import { formatDate } from '@/utils/date'
import { formatWeight, formatPercentage } from '@/utils/format'
import type { Goal } from '@/types'
import Card from '@/components/ui/Card.vue'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend)

const { t } = useI18n()
const evolutionStore = useEvolutionStore()

const bodyAssessments = computed(() => evolutionStore.bodyAssessments)
const evolutionPhotos = computed(() => evolutionStore.evolutionPhotos)
const goals = computed(() => evolutionStore.goals)
const isLoading = computed(() => evolutionStore.isLoading)

const weightHistory = computed(() => evolutionStore.getWeightHistory())
const bodyFatHistory = computed(() => evolutionStore.getBodyFatHistory())

const chartOptions: ChartOptions<'line'> = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      display: false,
    },
  },
  scales: {
    x: {
      grid: {
        color: 'rgba(245, 245, 240, 0.1)',
      },
      ticks: {
        color: 'rgba(245, 245, 240, 0.6)',
      },
    },
    y: {
      grid: {
        color: 'rgba(245, 245, 240, 0.1)',
      },
      ticks: {
        color: 'rgba(245, 245, 240, 0.6)',
      },
    },
  },
}

const weightChartData = computed(() => ({
  labels: weightHistory.value.map((d) => formatDate(d.date)),
  datasets: [
    {
      label: t('evolution.weight'),
      data: weightHistory.value.map((d) => d.value),
      borderColor: '#CDFA3E',
      backgroundColor: 'rgba(196, 245, 58, 0.1)',
      tension: 0.4,
    },
  ],
}))

const bodyFatChartData = computed(() => ({
  labels: bodyFatHistory.value.map((d) => formatDate(d.date)),
  datasets: [
    {
      label: t('evolution.bodyFat'),
      data: bodyFatHistory.value.map((d) => d.value),
      borderColor: '#0EA5E9',
      backgroundColor: 'rgba(14, 165, 233, 0.1)',
      tension: 0.4,
    },
  ],
}))

const getGoalStatusClass = (status: string) => {
  const classes = {
    active: 'bg-lime/20 text-lime',
    completed: 'bg-green-500/20 text-green-500',
    abandoned: 'bg-red-500/20 text-red-500',
  }
  return classes[status as keyof typeof classes] || classes.active
}

const getGoalProgress = (goal: any) => {
  const target = parseFloat(goal.target_value || goal.targetValue)
  const current = parseFloat(goal.current_value || goal.currentValue)
  if (!target || !current) return 0
  return Math.min(Math.round((current / target) * 100), 100)
}

onMounted(async () => {
  await Promise.all([
    evolutionStore.fetchBodyAssessments(),
    evolutionStore.fetchEvolutionPhotos(),
    evolutionStore.fetchGoals(),
  ])
})
</script>
