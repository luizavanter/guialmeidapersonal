<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useWorkoutsStore } from '@/stores/workoutsStore'
import { useRouter } from 'vue-router'

const { t } = useI18n()
const router = useRouter()
const workoutsStore = useWorkoutsStore()

const showAddModal = ref(false)
const isSubmitting = ref(false)
const submitError = ref('')

const newPlan = reactive({
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
  </div>
</template>
