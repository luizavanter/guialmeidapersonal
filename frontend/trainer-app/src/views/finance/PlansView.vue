<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useFinanceStore } from '@/stores/financeStore'
import { formatCurrency } from '@ga-personal/shared'

import { Pencil, Trash2 } from 'lucide-vue-next'

const { t } = useI18n()
const financeStore = useFinanceStore()

const showAddModal = ref(false)
const showEditModal = ref(false)
const showDeleteConfirm = ref(false)
const isSubmitting = ref(false)
const submitError = ref('')
const selectedPlan = ref<any>(null)

const newPlan = reactive({
  name: '',
  description: '',
  price: '',
  duration: '1',
  durationType: 'months',
  features: '',
  active: true
})

const editPlan = reactive({
  id: '',
  name: '',
  description: '',
  price: '',
  duration: '1',
  durationType: 'months',
  features: '',
  active: true
})

onMounted(async () => {
  await financeStore.fetchPlans()
})

function closeModal() {
  showAddModal.value = false
  submitError.value = ''
  newPlan.name = ''
  newPlan.description = ''
  newPlan.price = ''
  newPlan.duration = '1'
  newPlan.durationType = 'months'
  newPlan.features = ''
  newPlan.active = true
}

async function handleAddPlan() {
  if (!newPlan.name || !newPlan.price) {
    submitError.value = t('common.requiredFields')
    return
  }

  isSubmitting.value = true
  submitError.value = ''

  try {
    const features = newPlan.features
      ? newPlan.features.split('\n').filter(f => f.trim())
      : []

    // Backend expects price_cents (integer cents) and duration_days
    const durationDays = newPlan.durationType === 'months'
      ? parseInt(newPlan.duration) * 30
      : parseInt(newPlan.duration)

    await financeStore.createPlan({
      name: newPlan.name,
      description: newPlan.description || null,
      price_cents: Math.round(parseFloat(newPlan.price) * 100),
      currency: 'BRL',
      duration_days: durationDays,
      features: features,
      is_active: newPlan.active
    })
    closeModal()
    await financeStore.fetchPlans()
  } catch (err: any) {
    submitError.value = err.message || t('common.error')
  } finally {
    isSubmitting.value = false
  }
}

function openEditModal(plan: any) {
  selectedPlan.value = plan
  editPlan.id = plan.id
  editPlan.name = plan.name || ''
  editPlan.description = plan.description || ''
  editPlan.price = plan.price ? (plan.price / 100).toString() : ''
  // Calculate duration from durationDays
  if (plan.durationDays) {
    if (plan.durationDays >= 30 && plan.durationDays % 30 === 0) {
      editPlan.duration = (plan.durationDays / 30).toString()
      editPlan.durationType = 'months'
    } else {
      editPlan.duration = plan.durationDays.toString()
      editPlan.durationType = 'days'
    }
  } else {
    editPlan.duration = plan.duration?.toString() || '1'
    editPlan.durationType = plan.durationType || 'months'
  }
  editPlan.features = Array.isArray(plan.features) ? plan.features.join('\n') : ''
  editPlan.active = plan.active !== false && plan.isActive !== false
  showEditModal.value = true
}

function closeEditModal() {
  showEditModal.value = false
  submitError.value = ''
  selectedPlan.value = null
}

async function handleEditPlan() {
  if (!editPlan.name || !editPlan.price) {
    submitError.value = t('common.requiredFields')
    return
  }

  isSubmitting.value = true
  submitError.value = ''

  try {
    const features = editPlan.features
      ? editPlan.features.split('\n').filter(f => f.trim())
      : []

    const durationDays = editPlan.durationType === 'months'
      ? parseInt(editPlan.duration) * 30
      : parseInt(editPlan.duration)

    await financeStore.updatePlan(editPlan.id, {
      name: editPlan.name,
      description: editPlan.description || null,
      price_cents: Math.round(parseFloat(editPlan.price) * 100),
      currency: 'BRL',
      duration_days: durationDays,
      features: features,
      is_active: editPlan.active
    })
    closeEditModal()
    await financeStore.fetchPlans()
  } catch (err: any) {
    submitError.value = err.message || t('common.error')
  } finally {
    isSubmitting.value = false
  }
}

function openDeleteConfirm(plan: any) {
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
    await financeStore.deletePlan(selectedPlan.value.id)
    closeDeleteConfirm()
    await financeStore.fetchPlans()
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
      <h1 class="text-display-sm text-smoke">{{ t('finance.plans') }}</h1>
      <button @click="showAddModal = true" class="btn btn-primary">{{ t('finance.addPlan') }}</button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="plan in financeStore.plans" :key="plan.id" class="card">
        <div class="flex items-start justify-between mb-4">
          <h3 class="font-display text-2xl">{{ plan.name }}</h3>
          <div class="flex space-x-2">
            <button
              @click="openEditModal(plan)"
              class="p-2 text-stone hover:text-lime hover:bg-surface-3 rounded-lg transition-colors"
              :title="t('common.edit')"
            >
              <Pencil class="w-4 h-4" />
            </button>
            <button
              @click="openDeleteConfirm(plan)"
              class="p-2 text-stone hover:text-red-500 hover:bg-surface-3 rounded-lg transition-colors"
              :title="t('common.delete')"
            >
              <Trash2 class="w-4 h-4" />
            </button>
          </div>
        </div>
        <p class="text-stone mb-4">{{ plan.description }}</p>
        <div class="mb-4">
          <span class="font-display text-3xl text-lime">
            {{ formatCurrency(plan.price) }}
          </span>
          <span class="text-stone"> / {{ plan.duration }} {{ t(`finance.duration${plan.durationType === 'months' ? 'Months' : 'Days'}`) }}</span>
        </div>
        <div class="space-y-2 mb-4">
          <p v-for="(feature, i) in plan.features" :key="i" class="text-sm">
            <span class="text-lime mr-2">&#10003;</span> {{ feature }}
          </p>
        </div>
        <span :class="['badge', plan.active ? 'badge-success' : 'badge-warning']">
          {{ plan.active ? t('finance.active') : t('students.inactive') }}
        </span>
      </div>
    </div>

    <div v-if="financeStore.plans.length === 0" class="card text-center py-12">
      <p class="text-stone">{{ t('finance.noPlans') }}</p>
    </div>

    <!-- Add Plan Modal -->
    <div v-if="showAddModal" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeModal"></div>
      <div class="relative bg-surface-1 border border-surface-3 rounded-xl p-6 w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-lg font-display font-semibold text-smoke">{{ t('finance.addPlan') }}</h2>
          <button @click="closeModal" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>

        <form @submit.prevent="handleAddPlan" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.name') }} *</label>
            <input v-model="newPlan.name" type="text" class="input w-full" required />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.description') }}</label>
            <textarea v-model="newPlan.description" class="input w-full" rows="2"></textarea>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('finance.price') }} *</label>
            <input v-model="newPlan.price" type="number" step="0.01" min="0" class="input w-full" required />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-2">{{ t('finance.duration') }}</label>
              <input v-model="newPlan.duration" type="number" min="1" class="input w-full" />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">{{ t('finance.durationType') }}</label>
              <select v-model="newPlan.durationType" class="input w-full">
                <option value="days">{{ t('finance.durationDays') }}</option>
                <option value="months">{{ t('finance.durationMonths') }}</option>
              </select>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('finance.features') }}</label>
            <textarea v-model="newPlan.features" class="input w-full" rows="4" :placeholder="t('finance.featuresPlaceholder')"></textarea>
            <p class="text-xs text-stone mt-1">{{ t('finance.oneFeaturePerLine') }}</p>
          </div>

          <div class="flex items-center space-x-2">
            <input type="checkbox" v-model="newPlan.active" id="active" class="w-4 h-4" />
            <label for="active" class="text-sm">{{ t('finance.activeStatus') }}</label>
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
      <div class="relative bg-surface-1 border border-surface-3 rounded-xl p-6 w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-lg font-display font-semibold text-smoke">{{ t('finance.editPlan') }}</h2>
          <button @click="closeEditModal" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>

        <form @submit.prevent="handleEditPlan" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.name') }} *</label>
            <input v-model="editPlan.name" type="text" class="input w-full" required />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.description') }}</label>
            <textarea v-model="editPlan.description" class="input w-full" rows="2"></textarea>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('finance.price') }} *</label>
            <input v-model="editPlan.price" type="number" step="0.01" min="0" class="input w-full" required />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-2">{{ t('finance.duration') }}</label>
              <input v-model="editPlan.duration" type="number" min="1" class="input w-full" />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">{{ t('finance.durationType') }}</label>
              <select v-model="editPlan.durationType" class="input w-full">
                <option value="days">{{ t('finance.durationDays') }}</option>
                <option value="months">{{ t('finance.durationMonths') }}</option>
              </select>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('finance.features') }}</label>
            <textarea v-model="editPlan.features" class="input w-full" rows="4" :placeholder="t('finance.featuresPlaceholder')"></textarea>
            <p class="text-xs text-stone mt-1">{{ t('finance.oneFeaturePerLine') }}</p>
          </div>

          <div class="flex items-center space-x-2">
            <input type="checkbox" v-model="editPlan.active" id="editActive" class="w-4 h-4" />
            <label for="editActive" class="text-sm">{{ t('finance.activeStatus') }}</label>
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
          <h2 class="font-display text-2xl text-red-500">{{ t('finance.deletePlan') }}</h2>
          <button @click="closeDeleteConfirm" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>

        <p class="text-smoke/90 mb-6">
          {{ t('finance.deletePlanConfirmation') }}
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
