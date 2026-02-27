<script setup lang="ts">
import { onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useFinanceStore } from '@/stores/financeStore'
import { formatCurrency } from '@ga-personal/shared'
import { TrendingUp, Clock, AlertTriangle, Wallet, ClipboardList, Package } from 'lucide-vue-next'

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
  <div class="space-y-8">
    <h1 class="text-display-md text-smoke">{{ t('finance.title') }}</h1>

    <!-- Stats -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
      <div class="card">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-stone mb-1">{{ t('finance.monthlyRevenue') }}</p>
            <p class="text-2xl font-display font-bold text-lime">
              {{ formatCurrency(financeStore.monthRevenue) }}
            </p>
          </div>
          <div class="w-10 h-10 bg-lime/8 rounded-ga flex items-center justify-center">
            <TrendingUp :size="20" :stroke-width="1.75" class="text-lime" />
          </div>
        </div>
      </div>

      <div class="card">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-stone mb-1">{{ t('finance.pendingPayments') }}</p>
            <p class="text-2xl font-display font-bold text-yellow-400">
              {{ financeStore.pendingPayments.length }}
            </p>
          </div>
          <div class="w-10 h-10 bg-yellow-400/8 rounded-ga flex items-center justify-center">
            <Clock :size="20" :stroke-width="1.75" class="text-yellow-400" />
          </div>
        </div>
      </div>

      <div class="card">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm text-stone mb-1">{{ t('finance.overduePayments') }}</p>
            <p class="text-2xl font-display font-bold text-red-400">
              {{ financeStore.overduePayments.length }}
            </p>
          </div>
          <div class="w-10 h-10 bg-red-400/8 rounded-ga flex items-center justify-center">
            <AlertTriangle :size="20" :stroke-width="1.75" class="text-red-400" />
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Actions -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
      <div
        @click="router.push('/finance/payments')"
        class="card group hover:border-lime/30 cursor-pointer transition-all"
      >
        <div class="flex flex-col items-center text-center py-4">
          <div class="w-14 h-14 bg-lime/8 rounded-ga-lg flex items-center justify-center mb-4 group-hover:bg-lime/15 transition-colors">
            <Wallet :size="28" :stroke-width="1.5" class="text-lime" />
          </div>
          <h3 class="text-lg font-display font-semibold text-smoke mb-1">{{ t('finance.payments') }}</h3>
          <p class="text-sm text-stone">Track all payments</p>
        </div>
      </div>

      <div
        @click="router.push('/finance/subscriptions')"
        class="card group hover:border-lime/30 cursor-pointer transition-all"
      >
        <div class="flex flex-col items-center text-center py-4">
          <div class="w-14 h-14 bg-ocean/8 rounded-ga-lg flex items-center justify-center mb-4 group-hover:bg-ocean/15 transition-colors">
            <ClipboardList :size="28" :stroke-width="1.5" class="text-ocean" />
          </div>
          <h3 class="text-lg font-display font-semibold text-smoke mb-1">{{ t('finance.subscriptions') }}</h3>
          <p class="text-sm text-stone">Manage subscriptions</p>
        </div>
      </div>

      <div
        @click="router.push('/finance/plans')"
        class="card group hover:border-lime/30 cursor-pointer transition-all"
      >
        <div class="flex flex-col items-center text-center py-4">
          <div class="w-14 h-14 bg-surface-3 rounded-ga-lg flex items-center justify-center mb-4 group-hover:bg-surface-4 transition-colors">
            <Package :size="28" :stroke-width="1.5" class="text-smoke" />
          </div>
          <h3 class="text-lg font-display font-semibold text-smoke mb-1">{{ t('finance.plans') }}</h3>
          <p class="text-sm text-stone">Configure pricing plans</p>
        </div>
      </div>
    </div>
  </div>
</template>
