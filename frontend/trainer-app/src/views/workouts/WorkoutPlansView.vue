<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useWorkoutsStore } from '@/stores/workoutsStore'
import { useRouter } from 'vue-router'

const { t } = useI18n()
const router = useRouter()
const workoutsStore = useWorkoutsStore()

const showAddModal = ref(false)
const showEditModal = ref(false)
const showDeleteConfirm = ref(false)
const isSubmitting = ref(false)
const submitError = ref('')
const selectedPlan = ref<any>(null)

const newPlan = reactive({
  name: '',
  description: '',
  status: 'active'
})

const editPlan = reactive({
  id: '',
  name: '',
  description: '',
  status: 'active'
})

onMounted(async () => {
  await workoutsStore.fetchWorkoutPlans()
})

function viewPlan(id: string) {
  router.push(`/workouts/plans/${id}`)
}

function closeModal() {
  showAddModal.value = false
  submitError.value = ''
  newPlan.name = ''
  newPlan.description = ''
  newPlan.status = 'active'
}

async function handleAddPlan() {
  if (!newPlan.name) {
    submitError.value = t('common.requiredFields')
    return
  }

  isSubmitting.value = true
  submitError.value = ''

  try {
    await workoutsStore.createWorkoutPlan({
      name: newPlan.name,
      description: newPlan.description || null,
      status: newPlan.status,
      is_template: true
    })
    closeModal()
    await workoutsStore.fetchWorkoutPlans()
  } catch (err: any) {
    submitError.value = err.message || t('common.error')
  } finally {
    isSubmitting.value = false
  }
}

function openEditModal(plan: any, event: Event) {
  event.stopPropagation()
  selectedPlan.value = plan
  editPlan.id = plan.id
  editPlan.name = plan.name || ''
  editPlan.description = plan.description || ''
  editPlan.status = plan.status || 'active'
  showEditModal.value = true
}

function closeEditModal() {
  showEditModal.value = false
  submitError.value = ''
  selectedPlan.value = null
}

async function handleEditPlan() {
  if (!editPlan.name) {
    submitError.value = t('common.requiredFields')
    return
  }

  isSubmitting.value = true
  submitError.value = ''

  try {
    await workoutsStore.updateWorkoutPlan(editPlan.id, {
      workout_plan: {
        name: editPlan.name,
        description: editPlan.description || null,
        status: editPlan.status
      }
    })
    closeEditModal()
    await workoutsStore.fetchWorkoutPlans()
  } catch (err: any) {
    submitError.value = err.message || t('common.error')
  } finally {
    isSubmitting.value = false
  }
}

function openDeleteConfirm(plan: any, event: Event) {
  event.stopPropagation()
  selectedPlan.value = plan
  showDeleteConfirm.value = true
}

function closeDeleteConfirm() {
  showDeleteConfirm.value = false
  selectedPlan.value = null
}

async function handleDeletePlan() {
  if (!selectedPlan.value) return

  isSubmitting.value = true

  try {
    await workoutsStore.deleteWorkoutPlan(selectedPlan.value.id)
    closeDeleteConfirm()
    await workoutsStore.fetchWorkoutPlans()
  } catch (err: any) {
    submitError.value = err.message || t('common.error')
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="font-display text-4xl text-lime">{{ t('workouts.workoutPlans') }}</h1>
      <button @click="showAddModal = true" class="btn btn-primary">
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
          <div class="flex space-x-2">
            <span class="badge badge-info">{{ plan.exercises?.length || 0 }} exercises</span>
            <span :class="[
              'badge',
              plan.status === 'active' ? 'badge-success' : 'badge-warning'
            ]">
              {{ t(`workouts.${plan.status}`) }}
            </span>
          </div>
          <div class="flex space-x-2">
            <button
              @click="openEditModal(plan, $event)"
              class="p-2 text-smoke/60 hover:text-lime hover:bg-smoke/10 rounded-lg transition-colors"
              :title="t('common.edit')"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
              </svg>
            </button>
            <button
              @click="openDeleteConfirm(plan, $event)"
              class="p-2 text-smoke/60 hover:text-red-500 hover:bg-smoke/10 rounded-lg transition-colors"
              :title="t('common.delete')"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-if="workoutsStore.workoutPlans.length === 0" class="card text-center py-12">
      <p class="text-smoke/40">{{ t('workouts.noPlansFound') }}</p>
    </div>

    <!-- Add Plan Modal -->
    <div v-if="showAddModal" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeModal"></div>
      <div class="relative bg-coal border border-smoke/20 rounded-xl p-6 w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-lime">{{ t('workouts.addPlan') }}</h2>
          <button @click="closeModal" class="text-smoke/60 hover:text-smoke text-2xl">&times;</button>
        </div>

        <form @submit.prevent="handleAddPlan" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.name') }} *</label>
            <input v-model="newPlan.name" type="text" class="input w-full" required />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.description') }}</label>
            <textarea v-model="newPlan.description" class="input w-full" rows="3"></textarea>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">Status</label>
            <select v-model="newPlan.status" class="input w-full">
              <option value="active">{{ t('workouts.active') }}</option>
              <option value="inactive">{{ t('workouts.inactive') }}</option>
            </select>
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

    <!-- Edit Plan Modal -->
    <div v-if="showEditModal" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeEditModal"></div>
      <div class="relative bg-coal border border-smoke/20 rounded-xl p-6 w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-lime">{{ t('workouts.editPlan') }}</h2>
          <button @click="closeEditModal" class="text-smoke/60 hover:text-smoke text-2xl">&times;</button>
        </div>

        <form @submit.prevent="handleEditPlan" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.name') }} *</label>
            <input v-model="editPlan.name" type="text" class="input w-full" required />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.description') }}</label>
            <textarea v-model="editPlan.description" class="input w-full" rows="3"></textarea>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">Status</label>
            <select v-model="editPlan.status" class="input w-full">
              <option value="active">{{ t('workouts.active') }}</option>
              <option value="inactive">{{ t('workouts.inactive') }}</option>
            </select>
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
      <div class="relative bg-coal border border-smoke/20 rounded-xl p-6 w-full max-w-md mx-4">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-red-500">{{ t('workouts.deletePlan') }}</h2>
          <button @click="closeDeleteConfirm" class="text-smoke/60 hover:text-smoke text-2xl">&times;</button>
        </div>

        <p class="text-smoke/80 mb-6">
          {{ t('workouts.deletePlanConfirmation') || 'Are you sure you want to delete this workout plan?' }}
          <strong class="block mt-2 text-smoke">{{ selectedPlan?.name }}</strong>
        </p>

        <div class="flex justify-end space-x-3">
          <button @click="closeDeleteConfirm" class="btn btn-secondary">
            {{ t('common.cancel') }}
          </button>
          <button @click="handleDeletePlan" :disabled="isSubmitting" class="btn bg-red-600 hover:bg-red-700 text-white">
            {{ isSubmitting ? t('common.loading') : t('common.delete') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
