<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useWorkoutsStore } from '@/stores/workoutsStore'

const { t } = useI18n()
const workoutsStore = useWorkoutsStore()

const searchQuery = ref('')

onMounted(async () => {
  await workoutsStore.fetchExercises()
})

const filteredExercises = computed(() => {
  if (!searchQuery.value) return workoutsStore.exercises

  const query = searchQuery.value.toLowerCase()
  return workoutsStore.exercises.filter(e =>
    e.name.toLowerCase().includes(query) ||
    e.muscleGroup.toLowerCase().includes(query)
  )
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <h1 class="font-display text-4xl text-lime">{{ t('workouts.exerciseLibrary') }}</h1>
      <button class="btn btn-primary">
        {{ t('workouts.addExercise') }}
      </button>
    </div>

    <!-- Search -->
    <div class="card">
      <input
        v-model="searchQuery"
        type="text"
        class="input"
        :placeholder="t('workouts.searchExercises')"
      />
    </div>

    <!-- Exercises Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        v-for="exercise in filteredExercises"
        :key="exercise.id"
        class="card hover:border-lime/50 transition-all"
      >
        <div class="mb-4">
          <div v-if="exercise.thumbnailUrl" class="w-full h-40 bg-smoke/5 rounded-lg mb-4"></div>
          <h3 class="font-medium text-lg">{{ exercise.name }}</h3>
          <p class="text-sm text-smoke/60">{{ exercise.muscleGroup }}</p>
        </div>
        <div class="flex items-center justify-between">
          <span class="badge badge-info">{{ exercise.equipment || 'Body weight' }}</span>
          <span class="badge badge-warning">{{ t(`workouts.${exercise.difficulty}`) }}</span>
        </div>
      </div>
    </div>

    <div v-if="filteredExercises.length === 0" class="card text-center py-12">
      <p class="text-smoke/40">{{ t('workouts.noExercisesFound') }}</p>
    </div>
  </div>
</template>
