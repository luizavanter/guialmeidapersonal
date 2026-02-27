<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { Dumbbell, ClipboardList } from 'lucide-vue-next'

const { t } = useI18n()
const router = useRouter()
</script>

<template>
  <div class="space-y-8">
    <div>
      <h1 class="text-display-md text-smoke mb-1">{{ t('workouts.title') }}</h1>
      <p class="text-stone text-sm">{{ t('workouts.exerciseLibrary') }}</p>
    </div>

    <!-- Quick Actions -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
      <div
        @click="router.push('/workouts/exercises')"
        class="card group hover:border-lime/30 cursor-pointer transition-all"
      >
        <div class="flex flex-col items-center text-center py-4">
          <div class="w-14 h-14 bg-lime/8 rounded-ga-lg flex items-center justify-center mb-4 group-hover:bg-lime/15 transition-colors">
            <Dumbbell :size="28" :stroke-width="1.5" class="text-lime" />
          </div>
          <h3 class="text-lg font-display font-semibold text-smoke mb-1">{{ t('workouts.exercises') }}</h3>
          <p class="text-sm text-stone">{{ t('workouts.exerciseLibrary') }}</p>
        </div>
      </div>

      <div
        @click="router.push('/workouts/plans')"
        class="card group hover:border-lime/30 cursor-pointer transition-all"
      >
        <div class="flex flex-col items-center text-center py-4">
          <div class="w-14 h-14 bg-ocean/8 rounded-ga-lg flex items-center justify-center mb-4 group-hover:bg-ocean/15 transition-colors">
            <ClipboardList :size="28" :stroke-width="1.5" class="text-ocean" />
          </div>
          <h3 class="text-lg font-display font-semibold text-smoke mb-1">{{ t('workouts.workoutPlans') }}</h3>
          <p class="text-sm text-stone">{{ t('workouts.planDetails') }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
