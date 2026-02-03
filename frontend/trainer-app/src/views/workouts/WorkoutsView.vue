<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'

const { t } = useI18n()
const router = useRouter()
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="font-display text-4xl text-lime mb-2">{{ t('workouts.title') }}</h1>
      <p class="text-smoke/60">{{ t('workouts.exerciseLibrary') }}</p>
    </div>

    <!-- Quick Actions -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        @click="router.push('/workouts/exercises')"
        class="card hover:border-lime/50 cursor-pointer transition-all"
      >
        <div class="text-center">
          <div class="text-6xl mb-4">🏋️</div>
          <h3 class="font-display text-2xl mb-2">{{ t('workouts.exercises') }}</h3>
          <p class="text-smoke/60">{{ t('workouts.exerciseLibrary') }}</p>
        </div>
      </div>

      <div
        @click="router.push('/workouts/plans')"
        class="card hover:border-lime/50 cursor-pointer transition-all"
      >
        <div class="text-center">
          <div class="text-6xl mb-4">📋</div>
          <h3 class="font-display text-2xl mb-2">{{ t('workouts.workoutPlans') }}</h3>
          <p class="text-smoke/60">{{ t('workouts.planDetails') }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
