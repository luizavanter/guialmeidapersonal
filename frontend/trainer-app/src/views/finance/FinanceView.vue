<script setup lang="ts">
import { onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useFinanceStore } from '@/stores/financeStore'
import { formatCurrency } from '@ga-personal/shared'

const { t } = useI18n()
const router = useRouter()
const financeStore = useFinanceStore()

onMounted(async () => {
  await Promise.all([
    financeStore.fetchPayments(),
    financeStore.fetchSubscriptions(),
    financeStore.fetchPlans(),
  ])
})
</script>

<template>
  <div class="space-y-6">
    <h1 class="font-display text-4xl text-lime">{{ t('finance.title') }}</h1>

    <!-- Stats -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="card">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-smoke/60">{{ t('finance.monthlyRevenue') }}</p>
            <p class="font-display text-3xl text-lime">
              {{ formatCurrency(financeStore.monthRevenue) }}
            </p>
          </div>
          <span class="text-4xl">📈</span>
        </div>
      </div>

      <div class="card">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-smoke/60">{{ t('finance.pendingPayments') }}</p>
            <p class="font-display text-3xl text-yellow-500">
              {{ financeStore.pendingPayments.length }}
            </p>
          </div>
          <span class="text-4xl">⏳</span>
        </div>
      </div>

      <div class="card">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-smoke/60">{{ t('finance.overduePayments') }}</p>
            <p class="font-display text-3xl text-red-500">
              {{ financeStore.overduePayments.length }}
            </p>
          </div>
          <span class="text-4xl">⚠️</span>
        </div>
      </div>
    </div>

    <!-- Quick Actions -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div
        @click="router.push('/finance/payments')"
        class="card hover:border-lime/50 cursor-pointer transition-all"
      >
        <div class="text-center">
          <div class="text-6xl mb-4">💰</div>
          <h3 class="font-display text-2xl mb-2">{{ t('finance.payments') }}</h3>
          <p class="text-smoke/60">Track all payments</p>
        </div>
      </div>

      <div
        @click="router.push('/finance/subscriptions')"
        class="card hover:border-lime/50 cursor-pointer transition-all"
      >
        <div class="text-center">
          <div class="text-6xl mb-4">📋</div>
          <h3 class="font-display text-2xl mb-2">{{ t('finance.subscriptions') }}</h3>
          <p class="text-smoke/60">Manage subscriptions</p>
        </div>
      </div>

      <div
        @click="router.push('/finance/plans')"
        class="card hover:border-lime/50 cursor-pointer transition-all"
      >
        <div class="text-center">
          <div class="text-6xl mb-4">📦</div>
          <h3 class="font-display text-2xl mb-2">{{ t('finance.plans') }}</h3>
          <p class="text-smoke/60">Configure pricing plans</p>
        </div>
      </div>
    </div>
  </div>
</template>
