<script setup lang="ts">
import { onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useFinanceStore } from '@/stores/financeStore'
import { formatDate } from '@ga-personal/shared'

const { t } = useI18n()
const financeStore = useFinanceStore()

onMounted(async () => {
  await financeStore.fetchSubscriptions()
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="font-display text-4xl text-lime">{{ t('finance.subscriptions') }}</h1>
      <button class="btn btn-primary">Add Subscription</button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        v-for="sub in financeStore.subscriptions"
        :key="sub.id"
        class="card"
      >
        <div class="flex items-center justify-between mb-4">
          <h3 class="font-medium text-lg">
            {{ sub.student?.user?.firstName }} {{ sub.student?.user?.lastName }}
          </h3>
          <span :class="[
            'badge',
            sub.status === 'active' ? 'badge-success' : 'badge-warning'
          ]">
            {{ t(`finance.${sub.status}`) }}
          </span>
        </div>
        <div class="space-y-2 text-sm text-smoke/60">
          <p>Plan: {{ sub.plan?.name }}</p>
          <p>Start: {{ formatDate(sub.startDate) }}</p>
          <p>End: {{ formatDate(sub.endDate) }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
