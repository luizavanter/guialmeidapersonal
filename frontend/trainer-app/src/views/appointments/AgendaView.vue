<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAppointmentsStore } from '@/stores/appointmentsStore'
import { useStudentsStore } from '@/stores/studentsStore'
import { formatDate, formatTime } from '@ga-personal/shared'

const { t } = useI18n()
const appointmentsStore = useAppointmentsStore()
const studentsStore = useStudentsStore()

const view = ref<'day' | 'week' | 'month'>('week')
const currentDate = ref(new Date())
const showAddModal = ref(false)
const isSubmitting = ref(false)
const submitError = ref('')

const newAppointment = reactive({
  studentId: '',
  date: new Date().toISOString().split('T')[0],
  startTime: '09:00',
  endTime: '10:00',
  notes: '',
  status: 'scheduled'
})

onMounted(async () => {
  await Promise.all([
    appointmentsStore.fetchAppointments(),
    studentsStore.fetchStudents()
  ])
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

function closeModal() {
  showAddModal.value = false
  submitError.value = ''
  newAppointment.studentId = ''
  newAppointment.date = new Date().toISOString().split('T')[0]
  newAppointment.startTime = '09:00'
  newAppointment.endTime = '10:00'
  newAppointment.notes = ''
  newAppointment.status = 'scheduled'
}

async function handleAddAppointment() {
  if (!newAppointment.studentId || !newAppointment.date || !newAppointment.startTime) {
    submitError.value = t('common.requiredFields')
    return
  }

  isSubmitting.value = true
  submitError.value = ''

  try {
    // Calculate duration in minutes from start and end time
    const [startHour, startMin] = newAppointment.startTime.split(':').map(Number)
    const [endHour, endMin] = newAppointment.endTime.split(':').map(Number)
    const durationMinutes = (endHour * 60 + endMin) - (startHour * 60 + startMin)

    await appointmentsStore.createAppointment({
      student_id: newAppointment.studentId,
      scheduled_at: `${newAppointment.date}T${newAppointment.startTime}:00`,
      duration_minutes: durationMinutes > 0 ? durationMinutes : 60,
      notes: newAppointment.notes,
      status: newAppointment.status,
      appointment_type: 'training'
    })
    closeModal()
    await appointmentsStore.fetchAppointments()
  } catch (err: any) {
    submitError.value = err.message || t('common.error')
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <h1 class="font-display text-4xl text-lime">{{ t('agenda.title') }}</h1>
      <button @click="showAddModal = true" class="btn btn-primary">
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

    <!-- Add Appointment Modal -->
    <div v-if="showAddModal" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeModal"></div>
      <div class="relative bg-coal border border-smoke/20 rounded-xl p-6 w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-lime">{{ t('agenda.createAppointment') }}</h2>
          <button @click="closeModal" class="text-smoke/60 hover:text-smoke text-2xl">&times;</button>
        </div>

        <form @submit.prevent="handleAddAppointment" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2">{{ t('students.title') }} *</label>
            <select v-model="newAppointment.studentId" class="input w-full" required>
              <option value="">{{ t('common.select') }}</option>
              <option v-for="student in studentsStore.students" :key="student.id" :value="student.id">
                {{ student.user?.firstName }} {{ student.user?.lastName }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('agenda.date') }} *</label>
            <input v-model="newAppointment.date" type="date" class="input w-full" required />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-2">{{ t('agenda.startTime') }} *</label>
              <input v-model="newAppointment.startTime" type="time" class="input w-full" required />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">{{ t('agenda.endTime') }} *</label>
              <input v-model="newAppointment.endTime" type="time" class="input w-full" required />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.notes') }}</label>
            <textarea v-model="newAppointment.notes" class="input w-full" rows="3"></textarea>
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
