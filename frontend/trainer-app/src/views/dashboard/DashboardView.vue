<script setup lang="ts">
import { onMounted, computed, markRaw } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuth } from '@ga-personal/shared'
import { useStudentsStore } from '@/stores/studentsStore'
import { useAppointmentsStore } from '@/stores/appointmentsStore'
import { useFinanceStore } from '@/stores/financeStore'
import { formatCurrency, formatTime } from '@ga-personal/shared'
import { Users, Calendar, Wallet, TrendingUp } from 'lucide-vue-next'

const { t } = useI18n()
const { user } = useAuth()
const studentsStore = useStudentsStore()
const appointmentsStore = useAppointmentsStore()
const financeStore = useFinanceStore()

onMounted(async () => {
  await Promise.all([
    studentsStore.fetchStudents(),
    appointmentsStore.fetchAppointments(),
    financeStore.fetchPayments(),
  ])
})

const stats = computed(() => [
  {
    label: t('dashboard.activeStudents'),
    value: studentsStore.activeStudents.length,
    icon: markRaw(Users),
    accent: 'text-lime',
    bg: 'bg-lime/8',
  },
  {
    label: t('dashboard.todayAppointments'),
    value: appointmentsStore.todayAppointments.length,
    icon: markRaw(Calendar),
    accent: 'text-ocean',
    bg: 'bg-ocean/8',
  },
  {
    label: t('dashboard.pendingPayments'),
    value: financeStore.pendingPayments.length,
    icon: markRaw(Wallet),
    accent: 'text-yellow-400',
    bg: 'bg-yellow-400/8',
  },
  {
    label: t('dashboard.monthRevenue'),
    value: formatCurrency(financeStore.monthRevenue),
    icon: markRaw(TrendingUp),
    accent: 'text-lime',
    bg: 'bg-lime/8',
  },
])
</script>

<template>
  <div class="space-y-8">
    <!-- Header -->
    <div>
      <h1 class="text-display-md text-smoke mb-1">
        {{ t('dashboard.welcome') }}, {{ user?.firstName }}
      </h1>
      <p class="text-stone text-sm">
        {{ t('dashboard.todayAppointments') }}: {{ appointmentsStore.todayAppointments.length }}
      </p>
    </div>

    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
      <div v-for="stat in stats" :key="stat.label" class="card group">
        <div class="flex items-start justify-between mb-4">
          <div :class="['w-10 h-10 rounded-ga flex items-center justify-center', stat.bg]">
            <component :is="stat.icon" :size="20" :stroke-width="1.75" :class="stat.accent" />
          </div>
          <span :class="['text-2xl font-display font-bold', stat.accent]">
            {{ stat.value }}
          </span>
        </div>
        <p class="text-sm text-stone">{{ stat.label }}</p>
      </div>
    </div>

    <!-- Today's Schedule -->
    <div class="card">
      <h2 class="text-display-sm text-smoke mb-5">{{ t('dashboard.todayAppointments') }}</h2>

      <div v-if="appointmentsStore.todayAppointments.length === 0" class="text-center py-10 text-stone">
        {{ t('agenda.noAppointments') }}
      </div>

      <div v-else class="space-y-2">
        <div
          v-for="appointment in appointmentsStore.todayAppointments"
          :key="appointment.id"
          class="flex items-center justify-between p-4 bg-surface-2 rounded-ga hover:bg-surface-3 transition-colors"
        >
          <div class="flex items-center space-x-4">
            <div class="w-10 h-10 bg-lime/15 border border-lime/20 rounded-full flex items-center justify-center text-lime text-sm font-semibold">
              {{ appointment.student?.user?.firstName?.[0] }}
            </div>
            <div>
              <p class="font-medium text-sm text-smoke">
                {{ appointment.student?.user?.firstName }} {{ appointment.student?.user?.lastName }}
              </p>
              <p class="text-xs text-stone">
                {{ formatTime(appointment.startTime) }} - {{ formatTime(appointment.endTime) }}
              </p>
            </div>
          </div>
          <span :class="[
            'text-xs font-medium px-2.5 py-1 rounded-full',
            appointment.status === 'completed'
              ? 'bg-lime/10 text-lime'
              : 'bg-ocean/10 text-ocean'
          ]">
            {{ t(`appointments.${appointment.status}`) }}
          </span>
        </div>
      </div>
    </div>

    <!-- Recent Activity -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Pending Payments -->
      <div class="card">
        <h2 class="text-display-sm text-smoke mb-5">{{ t('finance.pendingPayments') }}</h2>

        <div v-if="financeStore.pendingPayments.length === 0" class="text-center py-10 text-stone">
          {{ t('common.noData') }}
        </div>

        <div v-else class="space-y-2">
          <div
            v-for="payment in financeStore.pendingPayments.slice(0, 5)"
            :key="payment.id"
            class="flex items-center justify-between p-3 bg-surface-2 rounded-ga"
          >
            <div>
              <p class="font-medium text-sm text-smoke">{{ payment.student?.user?.firstName }}</p>
              <p class="text-xs text-stone">{{ t('finance.dueDate') }}: {{ payment.dueDate }}</p>
            </div>
            <span class="font-mono text-sm text-lime">
              {{ formatCurrency(payment.amount) }}
            </span>
          </div>
        </div>
      </div>

      <!-- Active Students -->
      <div class="card">
        <h2 class="text-display-sm text-smoke mb-5">{{ t('students.active') }}</h2>

        <div v-if="studentsStore.activeStudents.length === 0" class="text-center py-10 text-stone">
          {{ t('students.noStudentsFound') }}
        </div>

        <div v-else class="space-y-2">
          <div
            v-for="student in studentsStore.activeStudents.slice(0, 5)"
            :key="student.id"
            class="flex items-center space-x-3 p-3 bg-surface-2 rounded-ga hover:bg-surface-3 transition-colors cursor-pointer"
            @click="$router.push(`/students/${student.id}`)"
          >
            <div class="w-9 h-9 bg-ocean/15 border border-ocean/20 rounded-full flex items-center justify-center text-ocean text-sm font-semibold">
              {{ student.user?.firstName?.[0] }}
            </div>
            <div class="flex-1 min-w-0">
              <p class="font-medium text-sm text-smoke truncate">
                {{ student.user?.firstName }} {{ student.user?.lastName }}
              </p>
              <p class="text-xs text-stone truncate">{{ student.user?.email }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
