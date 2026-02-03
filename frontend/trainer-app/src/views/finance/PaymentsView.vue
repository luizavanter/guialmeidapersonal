<script setup lang="ts">
import { onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useFinanceStore } from '@/stores/financeStore'
import { formatCurrency, formatDate } from '@ga-personal/shared'

const { t } = useI18n()
const financeStore = useFinanceStore()

onMounted(async () => {
  await financeStore.fetchPayments()
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="font-display text-4xl text-lime">{{ t('finance.payments') }}</h1>
      <button class="btn btn-primary">
        {{ t('finance.addPayment') }}
      </button>
    </div>

    <div class="card">
      <div class="overflow-x-auto">
        <table class="w-full">
          <thead>
            <tr class="border-b border-smoke/10">
              <th class="text-left py-3">{{ t('students.title') }}</th>
              <th class="text-left py-3">{{ t('finance.amount') }}</th>
              <th class="text-left py-3">{{ t('finance.dueDate') }}</th>
              <th class="text-left py-3">{{ t('finance.status') }}</th>
              <th class="text-left py-3">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="payment in financeStore.payments"
              :key="payment.id"
              class="border-b border-smoke/5 hover:bg-smoke/5"
            >
              <td class="py-3">
                {{ payment.student?.user?.firstName }} {{ payment.student?.user?.lastName }}
              </td>
              <td class="py-3 font-mono">{{ formatCurrency(payment.amount) }}</td>
              <td class="py-3">{{ formatDate(payment.dueDate) }}</td>
              <td class="py-3">
                <span :class="[
                  'badge',
                  payment.status === 'paid' ? 'badge-success' :
                  payment.status === 'pending' ? 'badge-warning' :
                  'badge-error'
                ]">
                  {{ t(`finance.${payment.status}`) }}
                </span>
              </td>
              <td class="py-3">
                <button class="btn btn-ghost btn-sm">{{ t('common.view') }}</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
