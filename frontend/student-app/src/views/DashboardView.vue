<template>
  <div>
    <div class="mb-8">
      <h1 class="text-3xl font-display text-lime mb-2">{{ t('dashboard.title') }}</h1>
      <p class="text-smoke/60">{{ t('dashboard.welcome', { name: user?.name?.split(' ')[0] || '' }) }}</p>
    </div>

    <div v-if="isLoading" class="text-center py-12">
      <p class="text-smoke/60">{{ t('common.loading') }}</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <!-- Next Appointment -->
      <Card :title="t('dashboard.nextAppointment')">
        <div v-if="stats?.nextAppointment" class="space-y-3">
          <div class="flex items-center gap-2 text-lime">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            <span class="font-mono text-lg">{{ formatDate(stats.nextAppointment.appointmentDate) }}</span>
          </div>
          <div class="flex items-center gap-2 text-smoke">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span class="font-mono">{{ formatTime(stats.nextAppointment.startTime) }}</span>
          </div>
          <router-link to="/schedule" class="inline-block text-sm text-ocean hover:text-ocean/80 transition-colors mt-2">
            Ver agenda →
          </router-link>
        </div>
        <div v-else class="text-smoke/60 text-sm">
          {{ t('dashboard.noAppointments') }}
        </div>
      </Card>

      <!-- Current Workout Plan -->
      <Card :title="t('dashboard.currentWorkout')">
        <div v-if="stats?.activeWorkoutPlan" class="space-y-3">
          <h3 class="text-lg font-semibold text-smoke">{{ stats.activeWorkoutPlan.name }}</h3>
          <p class="text-sm text-smoke/60 line-clamp-2">{{ stats.activeWorkoutPlan.description }}</p>
          <div class="flex items-center gap-2 text-lime text-sm">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
            </svg>
            <span>{{ stats.activeWorkoutPlan.exercises?.length || 0 }} exercícios</span>
          </div>
          <router-link :to="`/workouts/${stats.activeWorkoutPlan.id}`" class="inline-block text-sm text-ocean hover:text-ocean/80 transition-colors mt-2">
            Ver treino →
          </router-link>
        </div>
        <div v-else class="text-smoke/60 text-sm">
          {{ t('dashboard.noWorkoutPlan') }}
        </div>
      </Card>

      <!-- Recent Progress -->
      <Card :title="t('dashboard.recentProgress')">
        <div class="space-y-3">
          <div class="flex items-center justify-between">
            <span class="text-smoke/60 text-sm">{{ t('dashboard.completedWorkouts') }}</span>
            <span class="text-2xl font-bold text-lime font-mono">{{ stats?.recentProgress?.completedWorkoutsThisWeek || 0 }}</span>
          </div>
          <div v-if="stats?.recentProgress?.lastAssessment" class="pt-3 border-t border-smoke/10">
            <p class="text-smoke/60 text-xs mb-2">{{ t('dashboard.lastAssessment') }}</p>
            <div class="grid grid-cols-2 gap-2 text-sm">
              <div v-if="stats.recentProgress.lastAssessment.weight">
                <span class="text-smoke/60">Peso:</span>
                <span class="text-smoke font-mono ml-1">{{ formatWeight(stats.recentProgress.lastAssessment.weight) }}</span>
              </div>
              <div v-if="stats.recentProgress.lastAssessment.bodyFat">
                <span class="text-smoke/60">Gordura:</span>
                <span class="text-smoke font-mono ml-1">{{ formatPercentage(stats.recentProgress.lastAssessment.bodyFat) }}</span>
              </div>
            </div>
          </div>
        </div>
      </Card>

      <!-- Active Goals -->
      <Card :title="t('dashboard.activeGoals')" class="md:col-span-2">
        <div v-if="stats?.activeGoals && stats.activeGoals.length > 0" class="space-y-4">
          <div v-for="goal in stats.activeGoals.slice(0, 3)" :key="goal.id" class="p-4 bg-coal/50 rounded-lg border border-smoke/10">
            <div class="flex items-start justify-between mb-2">
              <h4 class="text-sm font-semibold text-smoke">{{ goal.title }}</h4>
              <span class="text-xs text-lime font-mono">{{ goal.status }}</span>
            </div>
            <p v-if="goal.description" class="text-xs text-smoke/60 mb-3">{{ goal.description }}</p>
            <div v-if="goal.targetValue && goal.currentValue" class="space-y-1">
              <div class="flex justify-between text-xs text-smoke/60">
                <span>{{ t('evolution.current') }}: {{ goal.currentValue }} {{ goal.targetUnit }}</span>
                <span>{{ t('evolution.target') }}: {{ goal.targetValue }} {{ goal.targetUnit }}</span>
              </div>
              <div class="w-full bg-coal/50 rounded-full h-2 overflow-hidden">
                <div
                  class="h-full bg-gradient-to-r from-lime to-ocean transition-all"
                  :style="{ width: `${Math.min((goal.currentValue / goal.targetValue) * 100, 100)}%` }"
                ></div>
              </div>
            </div>
          </div>
          <router-link to="/evolution" class="inline-block text-sm text-ocean hover:text-ocean/80 transition-colors">
            Ver todas as metas →
          </router-link>
        </div>
        <div v-else class="text-smoke/60 text-sm">
          {{ t('evolution.noGoals') }}
        </div>
      </Card>

      <!-- Messages -->
      <Card :title="t('nav.messages')">
        <div class="space-y-3">
          <div class="flex items-center gap-3">
            <div class="flex-shrink-0 w-12 h-12 bg-ocean/20 rounded-full flex items-center justify-center">
              <svg class="w-6 h-6 text-ocean" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
            </div>
            <div>
              <p class="text-2xl font-bold text-smoke font-mono">{{ stats?.unreadMessages || 0 }}</p>
              <p class="text-sm text-smoke/60">{{ t('dashboard.unreadMessages') }}</p>
            </div>
          </div>
          <router-link to="/messages" class="inline-block text-sm text-ocean hover:text-ocean/80 transition-colors">
            Ver mensagens →
          </router-link>
        </div>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth'
import { useDashboardStore } from '@/stores/dashboard'
import { formatDate, formatTime } from '@/utils/date'
import { formatWeight, formatPercentage } from '@/utils/format'
import Card from '@/components/ui/Card.vue'

const { t } = useI18n()
const authStore = useAuthStore()
const dashboardStore = useDashboardStore()

const user = computed(() => authStore.user)
const stats = computed(() => dashboardStore.stats)
const isLoading = computed(() => dashboardStore.isLoading)

onMounted(async () => {
  await dashboardStore.fetchDashboard()
})
</script>
