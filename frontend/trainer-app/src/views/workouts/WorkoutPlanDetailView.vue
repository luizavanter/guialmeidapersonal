<script setup lang="ts">
import { onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useWorkoutsStore } from '@/stores/workoutsStore'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const workoutsStore = useWorkoutsStore()

onMounted(async () => {
  const planId = route.params.id as string
  await workoutsStore.fetchWorkoutPlan(planId)
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center space-x-4">
      <button @click="router.back()" class="btn btn-ghost">
        ← {{ t('common.back') }}
      </button>
      <div class="flex-1">
        <h1 class="text-display-md text-smoke">
          {{ workoutsStore.currentPlan?.name }}
        </h1>
        <p class="text-stone">{{ workoutsStore.currentPlan?.description }}</p>
      </div>
      <button class="btn btn-primary">
        {{ t('workouts.addExerciseToPlan') }}
      </button>
    </div>

    <div class="card">
      <h2 class="font-display text-2xl mb-4">{{ t('workouts.exercises') }}</h2>
      <div class="space-y-3">
        <div
          v-for="(workoutEx, index) in workoutsStore.currentPlan?.exercises"
          :key="workoutEx.id"
          class="flex items-center justify-between p-4 bg-surface-2 rounded-lg"
        >
          <div class="flex items-center space-x-4">
            <span class="w-8 h-8 flex items-center justify-center bg-lime text-coal rounded-full font-bold">
              {{ index + 1 }}
            </span>
            <div>
              <p class="font-medium">{{ workoutEx.exercise?.name }}</p>
              <p class="text-sm text-stone">
                {{ workoutEx.sets }} sets × {{ workoutEx.reps }} reps
                <span v-if="workoutEx.rest"> • {{ workoutEx.rest }}s rest</span>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
