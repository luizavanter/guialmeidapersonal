<template>
  <div>
    <div class="mb-8">
      <h1 class="text-display-md text-smoke">{{ t('dashboard.title') }}</h1>
      <p class="text-stone mt-1">{{ t('dashboard.welcome', { name: user?.name?.split(' ')[0] || '' }) }}</p>
    </div>

    <div v-if="isLoading" class="text-center py-12">
      <p class="text-stone">{{ t('common.loading') }}</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <!-- Next Appointment -->
      <Card :title="t('dashboard.nextAppointment')">
        <div v-if="stats?.nextAppointment" class="space-y-3">
          <div class="flex items-center gap-2 text-lime">
            <CalendarIcon class="w-5 h-5" />
            <span class="font-mono text-lg">{{ formatDate(stats.nextAppointment.appointmentDate) }}</span>
          </div>
          <div class="flex items-center gap-2 text-smoke">
            <Clock class="w-5 h-5" />
            <span class="font-mono">{{ formatTime(stats.nextAppointment.startTime) }}</span>
          </div>
          <router-link to="/schedule" class="inline-block text-sm text-ocean hover:text-ocean/80 transition-colors mt-2">
            Ver agenda →
          </router-link>
        </div>
        <div v-else class="text-stone text-sm">
          {{ t('dashboard.noAppointments') }}
        </div>
      </Card>

      <!-- Current Workout Plan -->
      <Card :title="t('dashboard.currentWorkout')">
        <div v-if="stats?.activeWorkoutPlan" class="space-y-3">
          <h3 class="text-lg font-semibold text-smoke">{{ stats.activeWorkoutPlan.name }}</h3>
          <p class="text-sm text-stone line-clamp-2">{{ stats.activeWorkoutPlan.description }}</p>
          <div class="flex items-center gap-2 text-lime text-sm">
            <CheckCircle class="w-4 h-4" />
            <span>{{ stats.activeWorkoutPlan.exercises?.length || 0 }} exercícios</span>
          </div>
          <router-link :to="`/workouts/${stats.activeWorkoutPlan.id}`" class="inline-block text-sm text-ocean hover:text-ocean/80 transition-colors mt-2">
            Ver treino →
          </router-link>
        </div>
        <div v-else class="text-stone text-sm">
          {{ t('dashboard.noWorkoutPlan') }}
        </div>
      </Card>

      <!-- Recent Progress -->
      <Card :title="t('dashboard.recentProgress')">
        <div class="space-y-3">
          <div class="flex items-center justify-between">
            <span class="text-stone text-sm">{{ t('dashboard.completedWorkouts') }}</span>
            <span class="text-2xl font-bold text-lime font-mono">{{ stats?.recentProgress?.completedWorkoutsThisWeek || 0 }}</span>
          </div>
          <div v-if="stats?.recentProgress?.lastAssessment" class="pt-3 border-t border-surface-3">
            <p class="text-stone text-xs mb-2">{{ t('dashboard.lastAssessment') }}</p>
            <div class="grid grid-cols-2 gap-2 text-sm">
              <div v-if="stats.recentProgress.lastAssessment.weight">
                <span class="text-stone">Peso:</span>
                <span class="text-smoke font-mono ml-1">{{ formatWeight(stats.recentProgress.lastAssessment.weight) }}</span>
              </div>
              <div v-if="stats.recentProgress.lastAssessment.bodyFat">
                <span class="text-stone">Gordura:</span>
                <span class="text-smoke font-mono ml-1">{{ formatPercentage(stats.recentProgress.lastAssessment.bodyFat) }}</span>
              </div>
            </div>
          </div>
        </div>
      </Card>

      <!-- Active Goals -->
      <Card :title="t('dashboard.activeGoals')" class="md:col-span-2">
        <div v-if="stats?.activeGoals && stats.activeGoals.length > 0" class="space-y-4">
          <div v-for="goal in stats.activeGoals.slice(0, 3)" :key="goal.id" class="p-4 bg-surface-2 rounded-lg border border-surface-3">
            <div class="flex items-start justify-between mb-2">
              <h4 class="text-sm font-semibold text-smoke">{{ goal.title }}</h4>
              <span class="text-xs text-lime font-mono">{{ goal.status }}</span>
            </div>
            <p v-if="goal.description" class="text-xs text-stone mb-3">{{ goal.description }}</p>
            <div v-if="goal.targetValue && goal.currentValue" class="space-y-1">
              <div class="flex justify-between text-xs text-stone">
                <span>{{ t('evolution.current') }}: {{ goal.currentValue }} {{ goal.targetUnit }}</span>
                <span>{{ t('evolution.target') }}: {{ goal.targetValue }} {{ goal.targetUnit }}</span>
              </div>
              <div class="w-full bg-surface-3 rounded-full h-2 overflow-hidden">
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
        <div v-else class="text-stone text-sm">
          {{ t('evolution.noGoals') }}
        </div>
      </Card>

      <!-- Messages -->
      <Card :title="t('nav.messages')">
        <div class="space-y-3">
          <div class="flex items-center gap-3">
            <div class="flex-shrink-0 w-12 h-12 bg-ocean/10 rounded-full flex items-center justify-center">
              <MessageSquare class="w-6 h-6 text-ocean" />
            </div>
            <div>
              <p class="text-2xl font-bold text-smoke font-mono">{{ stats?.unreadMessages || 0 }}</p>
              <p class="text-sm text-stone">{{ t('dashboard.unreadMessages') }}</p>
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
import { Calendar as CalendarIcon, Clock, CheckCircle, MessageSquare } from 'lucide-vue-next'

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
