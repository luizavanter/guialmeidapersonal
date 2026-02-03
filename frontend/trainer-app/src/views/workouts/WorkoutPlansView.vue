<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useWorkoutsStore } from '@/stores/workoutsStore'
import { useRouter } from 'vue-router'

const { t } = useI18n()
const router = useRouter()
const workoutsStore = useWorkoutsStore()

onMounted(async () => {
  await workoutsStore.fetchWorkoutPlans()
})

function viewPlan(id: string) {
  router.push(`/workouts/plans/${id}`)
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="font-display text-4xl text-lime">{{ t('workouts.workoutPlans') }}</h1>
      <button class="btn btn-primary">
        {{ t('workouts.addPlan') }}
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        v-for="plan in workoutsStore.workoutPlans"
        :key="plan.id"
        class="card hover:border-lime/50 cursor-pointer transition-all"
        @click="viewPlan(plan.id)"
      >
        <h3 class="font-medium text-lg mb-2">{{ plan.name }}</h3>
        <p class="text-sm text-smoke/60 mb-4">{{ plan.description }}</p>
        <div class="flex items-center justify-between">
          <span class="badge badge-info">{{ plan.exercises?.length || 0 }} exercises</span>
          <span :class="[
            'badge',
            plan.status === 'active' ? 'badge-success' : 'badge-warning'
          ]">
            {{ t(`workouts.${plan.status}`) }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
