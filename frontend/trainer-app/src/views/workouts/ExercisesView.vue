<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useWorkoutsStore } from '@/stores/workoutsStore'

import { Pencil, Trash2 } from 'lucide-vue-next'

const { t } = useI18n()
const workoutsStore = useWorkoutsStore()

const searchQuery = ref('')
const showAddModal = ref(false)
const showEditModal = ref(false)
const showDeleteConfirm = ref(false)
const isSubmitting = ref(false)
const submitError = ref('')
const selectedExercise = ref<any>(null)

const newExercise = reactive({
  name: '',
  muscleGroup: '',
  equipment: '',
  difficulty: 'beginner',
  description: '',
  videoUrl: ''
})

const editExercise = reactive({
  id: '',
  name: '',
  muscleGroup: '',
  equipment: '',
  difficulty: 'beginner',
  description: '',
  videoUrl: ''
})

const muscleGroups = ['chest', 'back', 'shoulders', 'arms', 'legs', 'core', 'cardio', 'full_body']
const difficultyLevels = ['beginner', 'intermediate', 'advanced']

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

function closeModal() {
  showAddModal.value = false
  submitError.value = ''
  newExercise.name = ''
  newExercise.muscleGroup = ''
  newExercise.equipment = ''
  newExercise.difficulty = 'beginner'
  newExercise.description = ''
  newExercise.videoUrl = ''
}

async function handleAddExercise() {
  if (!newExercise.name || !newExercise.muscleGroup) {
    submitError.value = t('common.requiredFields')
    return
  }

  isSubmitting.value = true
  submitError.value = ''

  try {
    await workoutsStore.createExercise({
      name: newExercise.name,
      category: newExercise.muscleGroup,
      muscle_groups: [newExercise.muscleGroup],
      equipment_needed: newExercise.equipment || null,
      difficulty_level: newExercise.difficulty,
      description: newExercise.description || null,
      video_url: newExercise.videoUrl || null,
      is_public: false
    })
    closeModal()
    await workoutsStore.fetchExercises()
  } catch (err: any) {
    submitError.value = err.message || t('common.error')
  } finally {
    isSubmitting.value = false
  }
}

function openEditModal(exercise: any) {
  selectedExercise.value = exercise
  editExercise.id = exercise.id
  editExercise.name = exercise.name || ''
  editExercise.muscleGroup = exercise.muscleGroup || exercise.category || ''
  editExercise.equipment = exercise.equipment || exercise.equipmentNeeded || ''
  editExercise.difficulty = exercise.difficulty || exercise.difficultyLevel || 'beginner'
  editExercise.description = exercise.description || ''
  editExercise.videoUrl = exercise.videoUrl || ''
  showEditModal.value = true
}

function closeEditModal() {
  showEditModal.value = false
  submitError.value = ''
  selectedExercise.value = null
}

async function handleEditExercise() {
  if (!editExercise.name || !editExercise.muscleGroup) {
    submitError.value = t('common.requiredFields')
    return
  }

  isSubmitting.value = true
  submitError.value = ''

  try {
    await workoutsStore.updateExercise(editExercise.id, {
      exercise: {
        name: editExercise.name,
        category: editExercise.muscleGroup,
        muscle_groups: [editExercise.muscleGroup],
        equipment_needed: editExercise.equipment || null,
        difficulty_level: editExercise.difficulty,
        description: editExercise.description || null,
        video_url: editExercise.videoUrl || null
      }
    })
    closeEditModal()
    await workoutsStore.fetchExercises()
  } catch (err: any) {
    submitError.value = err.message || t('common.error')
  } finally {
    isSubmitting.value = false
  }
}

function openDeleteConfirm(exercise: any) {
  selectedExercise.value = exercise
  showDeleteConfirm.value = true
}

function closeDeleteConfirm() {
  showDeleteConfirm.value = false
  selectedExercise.value = null
}

async function handleDeleteExercise() {
  if (!selectedExercise.value) return

  isSubmitting.value = true

  try {
    await workoutsStore.deleteExercise(selectedExercise.value.id)
    closeDeleteConfirm()
    await workoutsStore.fetchExercises()
  } catch (err: any) {
    submitError.value = err.message || t('common.error')
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <h1 class="text-display-md text-smoke">{{ t('workouts.exerciseLibrary') }}</h1>
      <button @click="showAddModal = true" class="btn btn-primary">
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
          <div v-if="exercise.thumbnailUrl" class="w-full h-40 bg-surface-2 rounded-lg mb-4"></div>
          <h3 class="font-medium text-lg">{{ exercise.name }}</h3>
          <p class="text-sm text-stone">{{ exercise.muscleGroup }}</p>
        </div>
        <div class="flex items-center justify-between">
          <div class="flex space-x-2">
            <span class="badge badge-info">{{ exercise.equipment || 'Body weight' }}</span>
            <span class="badge badge-warning">{{ t(`workouts.${exercise.difficulty}`) }}</span>
          </div>
          <div class="flex space-x-2">
            <button
              @click="openEditModal(exercise)"
              class="p-2 text-stone hover:text-lime hover:bg-surface-3 rounded-lg transition-colors"
              :title="t('common.edit')"
            >
              <Pencil class="w-4 h-4" />
              </svg>
            </button>
            <button
              @click="openDeleteConfirm(exercise)"
              class="p-2 text-stone hover:text-red-500 hover:bg-surface-3 rounded-lg transition-colors"
              :title="t('common.delete')"
            >
              <Trash2 class="w-4 h-4" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-if="filteredExercises.length === 0" class="card text-center py-12">
      <p class="text-stone">{{ t('workouts.noExercisesFound') }}</p>
    </div>

    <!-- Add Exercise Modal -->
    <div v-if="showAddModal" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeModal"></div>
      <div class="relative bg-surface-1 border border-surface-3 rounded-xl p-6 w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-lime">{{ t('workouts.addExercise') }}</h2>
          <button @click="closeModal" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>

        <form @submit.prevent="handleAddExercise" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.name') }} *</label>
            <input v-model="newExercise.name" type="text" class="input w-full" required />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('workouts.muscleGroup') }} *</label>
            <select v-model="newExercise.muscleGroup" class="input w-full" required>
              <option value="">{{ t('common.select') }}</option>
              <option v-for="group in muscleGroups" :key="group" :value="group">
                {{ t(`workouts.muscles.${group}`) || group }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('workouts.equipment') }}</label>
            <input v-model="newExercise.equipment" type="text" class="input w-full" :placeholder="t('workouts.bodyweight')" />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('workouts.difficulty') }}</label>
            <select v-model="newExercise.difficulty" class="input w-full">
              <option v-for="level in difficultyLevels" :key="level" :value="level">
                {{ t(`workouts.${level}`) }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.description') }}</label>
            <textarea v-model="newExercise.description" class="input w-full" rows="3"></textarea>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('workouts.videoUrl') }}</label>
            <input v-model="newExercise.videoUrl" type="url" class="input w-full" placeholder="https://..." />
          </div>

          <div v-if="submitError" class="p-3 bg-red-500/20 text-red-400 rounded-lg text-sm">
            {{ submitError }}
          </div>

          <div class="flex justify-end space-x-3 pt-4">
            <button type="button" @click="closeModal" class="btn btn-secondary">
              {{ t('common.cancel') }}
            </button>
            <button type="submit" :disabled="isSubmitting" class="btn btn-primary">
              {{ isSubmitting ? t('common.loading') : t('common.save') }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Edit Exercise Modal -->
    <div v-if="showEditModal" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeEditModal"></div>
      <div class="relative bg-surface-1 border border-surface-3 rounded-xl p-6 w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-lime">{{ t('workouts.editExercise') }}</h2>
          <button @click="closeEditModal" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>

        <form @submit.prevent="handleEditExercise" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.name') }} *</label>
            <input v-model="editExercise.name" type="text" class="input w-full" required />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('workouts.muscleGroup') }} *</label>
            <select v-model="editExercise.muscleGroup" class="input w-full" required>
              <option value="">{{ t('common.select') }}</option>
              <option v-for="group in muscleGroups" :key="group" :value="group">
                {{ t(`workouts.muscles.${group}`) || group }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('workouts.equipment') }}</label>
            <input v-model="editExercise.equipment" type="text" class="input w-full" :placeholder="t('workouts.bodyweight')" />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('workouts.difficulty') }}</label>
            <select v-model="editExercise.difficulty" class="input w-full">
              <option v-for="level in difficultyLevels" :key="level" :value="level">
                {{ t(`workouts.${level}`) }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.description') }}</label>
            <textarea v-model="editExercise.description" class="input w-full" rows="3"></textarea>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('workouts.videoUrl') }}</label>
            <input v-model="editExercise.videoUrl" type="url" class="input w-full" placeholder="https://..." />
          </div>

          <div v-if="submitError" class="p-3 bg-red-500/20 text-red-400 rounded-lg text-sm">
            {{ submitError }}
          </div>

          <div class="flex justify-end space-x-3 pt-4">
            <button type="button" @click="closeEditModal" class="btn btn-secondary">
              {{ t('common.cancel') }}
            </button>
            <button type="submit" :disabled="isSubmitting" class="btn btn-primary">
              {{ isSubmitting ? t('common.loading') : t('common.save') }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div v-if="showDeleteConfirm" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeDeleteConfirm"></div>
      <div class="relative bg-surface-1 border border-surface-3 rounded-xl p-6 w-full max-w-md mx-4">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-red-500">{{ t('workouts.deleteExercise') }}</h2>
          <button @click="closeDeleteConfirm" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>

        <p class="text-smoke/90 mb-6">
          {{ t('workouts.deleteExerciseConfirmation') || 'Are you sure you want to delete this exercise?' }}
          <strong class="block mt-2 text-smoke">{{ selectedExercise?.name }}</strong>
        </p>

        <div class="flex justify-end space-x-3">
          <button @click="closeDeleteConfirm" class="btn btn-secondary">
            {{ t('common.cancel') }}
          </button>
          <button @click="handleDeleteExercise" :disabled="isSubmitting" class="btn bg-red-600 hover:bg-red-700 text-white">
            {{ isSubmitting ? t('common.loading') : t('common.delete') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
