<template>
  <div>
    <div class="mb-8">
      <h1 class="text-3xl font-display text-lime mb-2">{{ t('workouts.title') }}</h1>
    </div>

    <div v-if="isLoading" class="text-center py-12">
      <p class="text-smoke/60">{{ t('common.loading') }}</p>
    </div>

    <div v-else>
      <!-- Current Workout Plan -->
      <Card v-if="currentPlan" :title="t('workouts.currentPlan')" class="mb-6">
        <div class="space-y-4">
          <div>
            <h2 class="text-2xl font-semibold text-smoke mb-2">{{ currentPlan.name }}</h2>
            <p v-if="currentPlan.description" class="text-smoke/60">{{ currentPlan.description }}</p>
          </div>

          <div class="flex flex-wrap gap-4 text-sm">
            <div class="flex items-center gap-2 text-smoke/60">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <span>{{ formatDate(currentPlan.startDate) }}</span>
            </div>
            <div v-if="currentPlan.endDate" class="flex items-center gap-2 text-smoke/60">
              <span>até</span>
              <span>{{ formatDate(currentPlan.endDate) }}</span>
            </div>
          </div>

          <router-link :to="`/workouts/${currentPlan.id}`">
            <Button variant="primary">
              Ver Detalhes do Treino
            </Button>
          </router-link>
        </div>
      </Card>

      <div v-else class="text-center py-12 bg-coal/30 border border-smoke/10 rounded-lg">
        <p class="text-smoke/60">{{ t('workouts.noActivePlan') }}</p>
      </div>

      <!-- Workout History -->
      <Card :title="t('workouts.workoutHistory')" class="mt-6">
        <div v-if="workoutLogs.length > 0" class="space-y-3">
          <div
            v-for="log in workoutLogs.slice(0, 10)"
            :key="log.id"
            class="p-4 bg-coal/50 rounded-lg border border-smoke/10 hover:border-lime/30 transition-colors"
          >
            <div class="flex items-start justify-between mb-2">
              <div class="flex-1">
                <h4 class="text-sm font-semibold text-smoke">
                  {{ log.workoutExercise?.exercise?.name || 'Exercício' }}
                </h4>
                <p class="text-xs text-smoke/60 mt-1">
                  {{ formatDateTime(log.completedAt) }}
                </p>
              </div>
              <span class="text-xs text-lime bg-lime/10 px-2 py-1 rounded">
                {{ log.sets }} séries
              </span>
            </div>

            <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-xs">
              <div>
                <span class="text-smoke/60">Reps:</span>
                <span class="text-smoke font-mono ml-1">{{ log.reps.join(', ') }}</span>
              </div>
              <div>
                <span class="text-smoke/60">Carga:</span>
                <span class="text-smoke font-mono ml-1">{{ log.weight.join(', ') }} kg</span>
              </div>
              <div v-if="log.rpe && log.rpe.length > 0">
                <span class="text-smoke/60">RPE:</span>
                <span class="text-smoke font-mono ml-1">{{ log.rpe.join(', ') }}</span>
              </div>
              <div v-if="log.duration">
                <span class="text-smoke/60">Duração:</span>
                <span class="text-smoke font-mono ml-1">{{ formatDuration(log.duration) }}</span>
              </div>
            </div>

            <p v-if="log.notes" class="text-xs text-smoke/60 mt-2 italic">
              {{ log.notes }}
            </p>
          </div>
        </div>
        <div v-else class="text-center py-8 text-smoke/60">
          Nenhum treino registrado ainda
        </div>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useWorkoutsStore } from '@/stores/workouts'
import { formatDate, formatDateTime } from '@/utils/date'
import { formatDuration } from '@/utils/format'
import Card from '@/components/ui/Card.vue'
import Button from '@/components/ui/Button.vue'

const { t } = useI18n()
const workoutsStore = useWorkoutsStore()

const currentPlan = computed(() => workoutsStore.currentPlan)
const workoutLogs = computed(() => workoutsStore.workoutLogs)
const isLoading = computed(() => workoutsStore.isLoading)

onMounted(async () => {
  await Promise.all([
    workoutsStore.fetchWorkoutPlans(),
    workoutsStore.fetchWorkoutLogs(),
  ])
})
</script>
