<template>
  <div>
    <div class="mb-8">
      <h1 class="text-display-md text-smoke mb-2">{{ t('schedule.title') }}</h1>
    </div>

    <div v-if="isLoading" class="text-center py-12">
      <p class="text-stone">{{ t('common.loading') }}</p>
    </div>

    <div v-else class="space-y-6">
      <!-- Upcoming Appointments -->
      <Card :title="t('schedule.upcomingAppointments')">
        <div v-if="upcomingAppointments.length > 0" class="space-y-3">
          <div
            v-for="appointment in upcomingAppointments"
            :key="appointment.id"
            class="p-4 bg-surface-2 rounded-lg border border-surface-3 hover:border-lime/30 transition-colors"
          >
            <div class="flex items-start justify-between mb-3">
              <div class="flex-1">
                <div class="flex items-center gap-2 text-lime mb-2">
                  <CalendarIcon class="w-5 h-5" />
                  <span class="font-mono text-lg">{{ formatDate(appointment.appointmentDate) }}</span>
                </div>
                <div class="flex items-center gap-2 text-smoke">
                  <Clock class="w-4 h-4" />
                  <span class="font-mono">{{ formatTime(appointment.startTime) }} - {{ formatTime(appointment.endTime) }}</span>
                </div>
                <p v-if="appointment.notes" class="text-sm text-stone mt-2 italic">
                  {{ appointment.notes }}
                </p>
              </div>
              <Button
                variant="ghost"
                size="sm"
                @click="openChangeRequestModal(appointment)"
              >
                {{ t('schedule.requestChange') }}
              </Button>
            </div>
          </div>
        </div>
        <div v-else class="text-center py-8 text-stone">
          {{ t('schedule.noUpcoming') }}
        </div>
      </Card>

      <!-- Past Appointments -->
      <Card :title="t('schedule.pastAppointments')">
        <div v-if="pastAppointments.length > 0" class="space-y-3">
          <div
            v-for="appointment in pastAppointments.slice(0, 10)"
            :key="appointment.id"
            class="p-4 bg-surface-2 rounded-lg border border-surface-3"
          >
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <div class="flex items-center gap-2 text-stone mb-1">
                  <span class="font-mono">{{ formatDate(appointment.appointmentDate) }}</span>
                  <span>•</span>
                  <span class="font-mono">{{ formatTime(appointment.startTime) }}</span>
                </div>
                <span
                  :class="getStatusClass(appointment.status)"
                  class="text-xs px-2 py-1 rounded-full"
                >
                  {{ appointment.status }}
                </span>
              </div>
            </div>
          </div>
        </div>
        <div v-else class="text-center py-8 text-stone">
          {{ t('schedule.noPastAppointments') }}
        </div>
      </Card>
    </div>

    <!-- Change Request Modal -->
    <Modal v-model="showChangeModal" :title="t('schedule.requestChange')" size="md">
      <form id="change-request-form" @submit.prevent="handleChangeRequest">
        <div class="space-y-4">
          <div v-if="selectedAppointment" class="p-3 bg-surface-2 rounded-lg border border-surface-3">
            <p class="text-sm text-stone mb-1">{{ t('schedule.currentSession') }}:</p>
            <p class="text-smoke font-mono">
              {{ formatDate(selectedAppointment.appointmentDate) }} {{ t('schedule.at') }} {{ formatTime(selectedAppointment.startTime) }}
            </p>
          </div>

          <div>
            <label class="block text-sm font-medium text-smoke mb-1">
              {{ t('schedule.changeReason') }} *
            </label>
            <textarea
              v-model="changeForm.reason"
              rows="3"
              class="block w-full rounded-lg bg-surface-2 border border-surface-3 px-4 py-2 text-smoke placeholder-stone focus:outline-none focus:ring-2 focus:border-lime focus:ring-lime"
              :placeholder="t('schedule.changeReason')"
              required
            ></textarea>
          </div>

          <Input
            v-model="changeForm.preferredDate"
            type="date"
            :label="t('schedule.preferredDate')"
          />

          <Input
            v-model="changeForm.preferredTime"
            type="time"
            :label="t('schedule.preferredTime')"
          />

          <div v-if="changeErrors.general" class="p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
            <p class="text-sm text-red-500">{{ changeErrors.general }}</p>
          </div>
        </div>
      </form>

      <template #footer>
        <div class="flex justify-end gap-3">
          <Button variant="ghost" @click="showChangeModal = false">
            {{ t('common.cancel') }}
          </Button>
          <Button type="submit" form="change-request-form" variant="primary" :loading="isSubmitting">
            {{ t('common.submit') }}
          </Button>
        </div>
      </template>
    </Modal>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useScheduleStore } from '@/stores/schedule'
import { useToast } from '@/composables/useToast'
import { formatDate, formatTime } from '@/utils/date'
import type { Appointment } from '@/types'
import Card from '@/components/ui/Card.vue'
import Button from '@/components/ui/Button.vue'
import Input from '@/components/ui/Input.vue'
import Modal from '@/components/ui/Modal.vue'
import { Calendar as CalendarIcon, Clock } from 'lucide-vue-next'

const { t } = useI18n()
const scheduleStore = useScheduleStore()
const toast = useToast()

const showChangeModal = ref(false)
const selectedAppointment = ref<Appointment | null>(null)
const isSubmitting = ref(false)

const changeForm = reactive({
  reason: '',
  preferredDate: '',
  preferredTime: '',
})

const changeErrors = reactive({
  general: '',
})

const upcomingAppointments = computed(() => scheduleStore.upcomingAppointments)
const pastAppointments = computed(() => scheduleStore.pastAppointments)
const isLoading = computed(() => scheduleStore.isLoading)

const getStatusClass = (status: string) => {
  const classes = {
    completed: 'bg-green-500/20 text-green-500',
    cancelled: 'bg-red-500/20 text-red-500',
    no_show: 'bg-yellow-500/20 text-yellow-600',
  }
  return classes[status as keyof typeof classes] || 'bg-surface-3 text-stone'
}

const openChangeRequestModal = (appointment: Appointment) => {
  selectedAppointment.value = appointment
  changeForm.reason = ''
  changeForm.preferredDate = ''
  changeForm.preferredTime = ''
  changeErrors.general = ''
  showChangeModal.value = true
}

const handleChangeRequest = async () => {
  changeErrors.general = ''

  if (!changeForm.reason.trim()) {
    changeErrors.general = t('validation.required')
    return
  }

  isSubmitting.value = true

  try {
    await scheduleStore.requestAppointmentChange({
      appointmentId: selectedAppointment.value!.id,
      reason: changeForm.reason,
      preferredDate: changeForm.preferredDate || undefined,
      preferredTime: changeForm.preferredTime || undefined,
    })

    toast.success(t('schedule.changeRequestSent'))
    showChangeModal.value = false
  } catch (error) {
    changeErrors.general = t('schedule.changeRequestError')
  } finally {
    isSubmitting.value = false
  }
}

onMounted(async () => {
  await scheduleStore.fetchAppointments()
})
</script>
