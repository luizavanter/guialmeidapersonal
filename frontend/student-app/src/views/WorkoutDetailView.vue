<template>
  <div>
    <div class="mb-8 flex items-center gap-4">
      <router-link to="/workouts">
        <Button variant="ghost" size="sm">
          ← {{ t('common.back') }}
        </Button>
      </router-link>
    </div>

    <div v-if="isLoading" class="text-center py-12">
      <p class="text-stone">{{ t('common.loading') }}</p>
    </div>

    <div v-else-if="currentPlan">
      <div class="mb-6">
        <h1 class="text-display-md text-smoke mb-2">{{ currentPlan.name }}</h1>
        <p v-if="currentPlan.description" class="text-stone">{{ currentPlan.description }}</p>
      </div>

      <!-- Exercises grouped by day -->
      <div class="space-y-6">
        <div v-for="day in groupedExercises" :key="day.dayOfWeek">
          <Card :title="getDayName(day.dayOfWeek)">
            <div class="space-y-4">
              <div
                v-for="exercise in day.exercises"
                :key="exercise.id"
                class="p-4 bg-surface-2 rounded-lg border border-surface-3"
              >
                <div class="flex items-start justify-between mb-3">
                  <div class="flex-1">
                    <h3 class="text-lg font-semibold text-smoke">
                      {{ exercise.exercise?.name }}
                    </h3>
                    <p v-if="exercise.exercise?.description" class="text-sm text-stone mt-1">
                      {{ exercise.exercise.description }}
                    </p>
                  </div>
                  <Button
                    variant="primary"
                    size="sm"
                    @click="openLogModal(exercise)"
                  >
                    {{ t('workouts.logWorkout') }}
                  </Button>
                </div>

                <div class="grid grid-cols-2 md:grid-cols-3 gap-3 text-sm">
                  <div>
                    <span class="text-stone">{{ t('workouts.sets') }}:</span>
                    <span class="text-smoke font-mono ml-2">{{ exercise.sets }}</span>
                  </div>
                  <div>
                    <span class="text-stone">{{ t('workouts.reps') }}:</span>
                    <span class="text-smoke font-mono ml-2">{{ exercise.reps }}</span>
                  </div>
                  <div v-if="exercise.restSeconds">
                    <span class="text-stone">Descanso:</span>
                    <span class="text-smoke font-mono ml-2">{{ exercise.restSeconds }}s</span>
                  </div>
                </div>

                <p v-if="exercise.notes" class="text-sm text-stone mt-3 italic">
                  {{ exercise.notes }}
                </p>
              </div>
            </div>
          </Card>
        </div>
      </div>
    </div>

    <!-- Log Workout Modal -->
    <Modal v-model="showLogModal" :title="t('workouts.logWorkout')" size="lg">
      <form id="log-workout-form" @submit.prevent="handleLogWorkout">
        <div class="space-y-4">
          <div>
            <h4 class="text-lg font-semibold text-smoke mb-2">
              {{ selectedExercise?.exercise?.name }}
            </h4>
            <p class="text-sm text-stone">
              {{ selectedExercise?.sets }} séries × {{ selectedExercise?.reps }} reps
            </p>
          </div>

          <Input
            v-model="logForm.sets"
            type="number"
            :label="t('workouts.sets')"
            :error="logErrors.sets"
            required
            min="1"
          />

          <div>
            <label class="block text-sm font-medium text-smoke mb-2">
              {{ t('workouts.reps') }} (por série) *
            </label>
            <div class="grid grid-cols-2 gap-2">
              <Input
                v-for="i in parseInt(logForm.sets || '0')"
                :key="i"
                v-model="logForm.reps[i - 1]"
                type="number"
                :placeholder="`Série ${i}`"
                required
                min="1"
              />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-smoke mb-2">
              {{ t('workouts.weight') }} (kg, por série) *
            </label>
            <div class="grid grid-cols-2 gap-2">
              <Input
                v-for="i in parseInt(logForm.sets || '0')"
                :key="i"
                v-model="logForm.weight[i - 1]"
                type="number"
                :placeholder="`Série ${i}`"
                required
                min="0"
                step="0.5"
              />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-smoke mb-2">
              {{ t('workouts.rpe') }} (1-10, por série)
            </label>
            <div class="grid grid-cols-2 gap-2">
              <Input
                v-for="i in parseInt(logForm.sets || '0')"
                :key="i"
                v-model="logForm.rpe[i - 1]"
                type="number"
                :placeholder="`Série ${i}`"
                min="1"
                max="10"
              />
            </div>
          </div>

          <Input
            v-model="logForm.duration"
            type="number"
            :label="`${t('workouts.duration')} (segundos)`"
            min="0"
          />

          <div>
            <label class="block text-sm font-medium text-smoke mb-1">
              {{ t('workouts.notes') }}
            </label>
            <textarea
              v-model="logForm.notes"
              rows="3"
              class="block w-full rounded-lg bg-surface-2 border border-surface-3 px-4 py-2 text-smoke placeholder-stone focus:outline-none focus:ring-2 focus:border-lime focus:ring-lime"
              :placeholder="t('workouts.notes')"
            ></textarea>
          </div>

          <div v-if="logErrors.general" class="p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
            <p class="text-sm text-red-500">{{ logErrors.general }}</p>
          </div>
        </div>
      </form>

      <template #footer>
        <div class="flex justify-end gap-3">
          <Button variant="ghost" @click="showLogModal = false">
            {{ t('common.cancel') }}
          </Button>
          <Button type="submit" form="log-workout-form" variant="primary" :loading="isSubmitting">
            {{ t('common.save') }}
          </Button>
        </div>
      </template>
    </Modal>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useWorkoutsStore } from '@/stores/workouts'
import { useToast } from '@/composables/useToast'
import { getDayOfWeekName } from '@/utils/date'
import { validateSets, validateReps, validateWeight, validateRPE } from '@/utils/validation'
import type { WorkoutExercise } from '@/types'
import Card from '@/components/ui/Card.vue'
import Button from '@/components/ui/Button.vue'
import Input from '@/components/ui/Input.vue'
import Modal from '@/components/ui/Modal.vue'

const { t } = useI18n()
const route = useRoute()
const workoutsStore = useWorkoutsStore()
const toast = useToast()

const showLogModal = ref(false)
const selectedExercise = ref<WorkoutExercise | null>(null)
const isSubmitting = ref(false)

const logForm = reactive({
  sets: '',
  reps: [] as string[],
  weight: [] as string[],
  rpe: [] as string[],
  duration: '',
  notes: '',
})

const logErrors = reactive({
  sets: '',
  general: '',
})

const currentPlan = computed(() => workoutsStore.currentPlan)
const isLoading = computed(() => workoutsStore.isLoading)

const groupedExercises = computed(() => {
  if (!currentPlan.value?.exercises) return []

  const groups = new Map<number, typeof currentPlan.value.exercises>()

  currentPlan.value.exercises.forEach((exercise) => {
    const existing = groups.get(exercise.dayOfWeek) || []
    groups.set(exercise.dayOfWeek, [...existing, exercise])
  })

  return Array.from(groups.entries())
    .map(([dayOfWeek, exercises]) => ({
      dayOfWeek,
      exercises: exercises.sort((a, b) => a.orderIndex - b.orderIndex),
    }))
    .sort((a, b) => a.dayOfWeek - b.dayOfWeek)
})

const getDayName = (dayOfWeek: number) => {
  return getDayOfWeekName(dayOfWeek, 'pt-BR')
}

const openLogModal = (exercise: WorkoutExercise) => {
  selectedExercise.value = exercise
  logForm.sets = exercise.sets.toString()
  logForm.reps = []
  logForm.weight = []
  logForm.rpe = []
  logForm.duration = ''
  logForm.notes = ''
  logErrors.sets = ''
  logErrors.general = ''
  showLogModal.value = true
}

const handleLogWorkout = async () => {
  logErrors.sets = ''
  logErrors.general = ''

  // Validate
  const sets = parseInt(logForm.sets)
  if (!validateSets(sets)) {
    logErrors.sets = t('validation.required')
    return
  }

  // Convert arrays
  const reps = logForm.reps.map((r) => parseInt(r)).filter((r) => !isNaN(r))
  const weight = logForm.weight.map((w) => parseFloat(w)).filter((w) => !isNaN(w))
  const rpe = logForm.rpe.map((r) => parseInt(r)).filter((r) => !isNaN(r))

  if (reps.length !== sets || weight.length !== sets) {
    logErrors.general = 'Preencha todas as séries'
    return
  }

  // Validate individual values
  for (const r of reps) {
    if (!validateReps(r)) {
      logErrors.general = 'Repetições inválidas'
      return
    }
  }

  for (const w of weight) {
    if (!validateWeight(w)) {
      logErrors.general = 'Carga inválida'
      return
    }
  }

  for (const r of rpe) {
    if (!validateRPE(r)) {
      logErrors.general = 'RPE deve estar entre 1 e 10'
      return
    }
  }

  isSubmitting.value = true

  try {
    await workoutsStore.logWorkout({
      workoutExerciseId: selectedExercise.value!.id,
      completedAt: new Date().toISOString(),
      sets,
      reps,
      weight,
      rpe: rpe.length > 0 ? rpe : undefined,
      duration: logForm.duration ? parseInt(logForm.duration) : undefined,
      notes: logForm.notes || undefined,
    })

    toast.success(t('workouts.logSuccess'))
    showLogModal.value = false
  } catch (error) {
    logErrors.general = t('workouts.logError')
  } finally {
    isSubmitting.value = false
  }
}

watch(
  () => logForm.sets,
  (newSets) => {
    const count = parseInt(newSets) || 0
    logForm.reps = Array(count).fill('')
    logForm.weight = Array(count).fill('')
    logForm.rpe = Array(count).fill('')
  }
)

onMounted(async () => {
  const id = route.params.id as string
  if (id) {
    await workoutsStore.fetchWorkoutPlan(id)
  }
})
</script>
