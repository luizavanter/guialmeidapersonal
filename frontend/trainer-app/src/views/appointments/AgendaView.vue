<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAppointmentsStore } from '@/stores/appointmentsStore'
import { formatDate, formatTime } from '@ga-personal/shared'

const { t } = useI18n()
const appointmentsStore = useAppointmentsStore()

const view = ref<'day' | 'week' | 'month'>('week')
const currentDate = ref(new Date())

onMounted(async () => {
  await appointmentsStore.fetchAppointments()
})

const displayDate = computed(() => {
  return formatDate(currentDate.value)
})

function previousPeriod() {
  const date = new Date(currentDate.value)
  if (view.value === 'day') date.setDate(date.getDate() - 1)
  else if (view.value === 'week') date.setDate(date.getDate() - 7)
  else date.setMonth(date.getMonth() - 1)
  currentDate.value = date
}

function nextPeriod() {
  const date = new Date(currentDate.value)
  if (view.value === 'day') date.setDate(date.getDate() + 1)
  else if (view.value === 'week') date.setDate(date.getDate() + 7)
  else date.setMonth(date.getMonth() + 1)
  currentDate.value = date
}

function today() {
  currentDate.value = new Date()
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <h1 class="font-display text-4xl text-lime">{{ t('agenda.title') }}</h1>
      <button class="btn btn-primary">
        {{ t('agenda.createAppointment') }}
      </button>
    </div>

    <!-- Controls -->
    <div class="card">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <button @click="previousPeriod" class="btn btn-ghost">←</button>
          <button @click="today" class="btn btn-secondary">{{ t('agenda.today') }}</button>
          <button @click="nextPeriod" class="btn btn-ghost">→</button>
          <span class="font-display text-xl ml-4">{{ displayDate }}</span>
        </div>

        <div class="flex space-x-2">
          <button
            v-for="v in ['day', 'week', 'month']"
            :key="v"
            @click="view = v"
            :class="[
              'btn',
              view === v ? 'btn-primary' : 'btn-ghost'
            ]"
          >
            {{ t(`agenda.${v}`) }}
          </button>
        </div>
      </div>
    </div>

    <!-- Calendar View -->
    <div class="card">
      <div class="space-y-4">
        <div
          v-for="appointment in appointmentsStore.appointments"
          :key="appointment.id"
          class="flex items-center justify-between p-4 bg-smoke/5 rounded-lg hover:bg-smoke/10 transition-colors"
        >
          <div class="flex items-center space-x-4">
            <div class="text-center">
              <div class="font-display text-2xl text-lime">
                {{ formatTime(appointment.startTime) }}
              </div>
              <div class="text-sm text-smoke/60">
                {{ formatTime(appointment.endTime) }}
              </div>
            </div>
            <div>
              <p class="font-medium">
                {{ appointment.student?.user?.firstName }} {{ appointment.student?.user?.lastName }}
              </p>
              <p class="text-sm text-smoke/60">{{ appointment.notes || '-' }}</p>
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

      <div v-if="appointmentsStore.appointments.length === 0" class="text-center py-12 text-smoke/40">
        {{ t('agenda.noAppointments') }}
      </div>
    </div>
  </div>
</template>
