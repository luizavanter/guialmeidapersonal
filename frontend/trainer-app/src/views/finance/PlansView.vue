<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useFinanceStore } from '@/stores/financeStore'
import { formatCurrency } from '@ga-personal/shared'

const { t } = useI18n()
const financeStore = useFinanceStore()

const showAddModal = ref(false)
const isSubmitting = ref(false)
const submitError = ref('')

const newPlan = reactive({
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
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="font-display text-4xl text-lime">{{ t('finance.plans') }}</h1>
      <button @click="showAddModal = true" class="btn btn-primary">{{ t('finance.addPlan') }}</button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="plan in financeStore.plans" :key="plan.id" class="card">
        <h3 class="font-display text-2xl mb-4">{{ plan.name }}</h3>
        <p class="text-smoke/60 mb-4">{{ plan.description }}</p>
        <div class="mb-4">
          <span class="font-display text-3xl text-lime">
            {{ formatCurrency(plan.price) }}
          </span>
          <span class="text-smoke/60"> / {{ plan.duration }} {{ t(`finance.duration${plan.durationType === 'months' ? 'Months' : 'Days'}`) }}</span>
        </div>
        <div class="space-y-2 mb-4">
          <p v-for="(feature, i) in plan.features" :key="i" class="text-sm">
            ✓ {{ feature }}
          </p>
        </div>
        <span :class="['badge', plan.active ? 'badge-success' : 'badge-warning']">
          {{ plan.active ? 'Active' : 'Inactive' }}
        </span>
      </div>
    </div>

    <div v-if="financeStore.plans.length === 0" class="card text-center py-12">
      <p class="text-smoke/40">{{ t('finance.noPlans') }}</p>
    </div>

    <!-- Add Plan Modal -->
    <div v-if="showAddModal" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeModal"></div>
      <div class="relative bg-coal border border-smoke/20 rounded-xl p-6 w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-lime">{{ t('finance.addPlan') }}</h2>
          <button @click="closeModal" class="text-smoke/60 hover:text-smoke text-2xl">&times;</button>
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
            <p class="text-xs text-smoke/40 mt-1">{{ t('finance.oneFeaturePerLine') }}</p>
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
  </div>
</template>
