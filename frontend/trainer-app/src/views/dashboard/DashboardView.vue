<script setup lang="ts">
import { onMounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuth } from '@ga-personal/shared'
import { useStudentsStore } from '@/stores/studentsStore'
import { useAppointmentsStore } from '@/stores/appointmentsStore'
import { useFinanceStore } from '@/stores/financeStore'
import { formatCurrency, formatTime } from '@ga-personal/shared'

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
    icon: '👥',
    color: 'lime',
  },
  {
    label: t('dashboard.todayAppointments'),
    value: appointmentsStore.todayAppointments.length,
    icon: '📅',
    color: 'ocean',
  },
  {
    label: t('dashboard.pendingPayments'),
    value: financeStore.pendingPayments.length,
    icon: '💰',
    color: 'yellow-500',
  },
  {
    label: t('dashboard.monthRevenue'),
    value: formatCurrency(financeStore.monthRevenue),
    icon: '📈',
    color: 'lime',
  },
])
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="font-display text-4xl text-lime mb-2">
        {{ t('dashboard.welcome') }}, {{ user?.firstName }}!
      </h1>
      <p class="text-smoke/60">
        {{ t('dashboard.todayAppointments') }}: {{ appointmentsStore.todayAppointments.length }}
      </p>
    </div>

    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <div v-for="stat in stats" :key="stat.label" class="card">
        <div class="flex items-center justify-between mb-4">
          <span class="text-3xl">{{ stat.icon }}</span>
          <span :class="`text-${stat.color} text-2xl font-display`">
            {{ stat.value }}
          </span>
        </div>
        <p class="text-sm text-smoke/60">{{ stat.label }}</p>
      </div>
    </div>

    <!-- Today's Schedule -->
    <div class="card">
      <h2 class="font-display text-2xl mb-4">{{ t('dashboard.todayAppointments') }}</h2>

      <div v-if="appointmentsStore.todayAppointments.length === 0" class="text-center py-8 text-smoke/40">
        {{ t('agenda.noAppointments') }}
      </div>

      <div v-else class="space-y-3">
        <div
          v-for="appointment in appointmentsStore.todayAppointments"
          :key="appointment.id"
          class="flex items-center justify-between p-4 bg-smoke/5 rounded-lg hover:bg-smoke/10 transition-colors"
        >
          <div class="flex items-center space-x-4">
            <div class="w-12 h-12 bg-lime rounded-full flex items-center justify-center text-coal font-bold">
              {{ appointment.student?.user?.firstName?.[0] }}
            </div>
            <div>
              <p class="font-medium">
                {{ appointment.student?.user?.firstName }} {{ appointment.student?.user?.lastName }}
              </p>
              <p class="text-sm text-smoke/60">
                {{ formatTime(appointment.startTime) }} - {{ formatTime(appointment.endTime) }}
              </p>
            </div>
          </div>
          <span :class="[
            'badge',
            appointment.status === 'completed' ? 'badge-success' : 'badge-info'
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
        <h2 class="font-display text-2xl mb-4">{{ t('finance.pendingPayments') }}</h2>

        <div v-if="financeStore.pendingPayments.length === 0" class="text-center py-8 text-smoke/40">
          {{ t('common.noData') }}
        </div>

        <div v-else class="space-y-3">
          <div
            v-for="payment in financeStore.pendingPayments.slice(0, 5)"
            :key="payment.id"
            class="flex items-center justify-between p-3 bg-smoke/5 rounded-lg"
          >
            <div>
              <p class="font-medium">{{ payment.student?.user?.firstName }}</p>
              <p class="text-sm text-smoke/60">Due: {{ payment.dueDate }}</p>
            </div>
            <span class="font-mono text-lime">
              {{ formatCurrency(payment.amount) }}
            </span>
          </div>
        </div>
      </div>

      <!-- Active Students -->
      <div class="card">
        <h2 class="font-display text-2xl mb-4">{{ t('students.active') }}</h2>

        <div v-if="studentsStore.activeStudents.length === 0" class="text-center py-8 text-smoke/40">
          {{ t('students.noStudentsFound') }}
        </div>

        <div v-else class="space-y-3">
          <div
            v-for="student in studentsStore.activeStudents.slice(0, 5)"
            :key="student.id"
            class="flex items-center space-x-3 p-3 bg-smoke/5 rounded-lg hover:bg-smoke/10 transition-colors cursor-pointer"
            @click="$router.push(`/students/${student.id}`)"
          >
            <div class="w-10 h-10 bg-ocean rounded-full flex items-center justify-center text-white font-bold">
              {{ student.user?.firstName?.[0] }}
            </div>
            <div class="flex-1">
              <p class="font-medium">
                {{ student.user?.firstName }} {{ student.user?.lastName }}
              </p>
              <p class="text-sm text-smoke/60">{{ student.user?.email }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
