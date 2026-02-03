<script setup lang="ts">
import { onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useFinanceStore } from '@/stores/financeStore'
import { formatCurrency } from '@ga-personal/shared'

const { t } = useI18n()
const financeStore = useFinanceStore()

onMounted(async () => {
  await financeStore.fetchPlans()
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="font-display text-4xl text-lime">{{ t('finance.plans') }}</h1>
      <button class="btn btn-primary">{{ t('finance.addPlan') }}</button>
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
  </div>
</template>
