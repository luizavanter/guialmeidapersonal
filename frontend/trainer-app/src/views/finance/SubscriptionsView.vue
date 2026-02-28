<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useFinanceStore } from '@/stores/financeStore'
import { useStudentsStore } from '@/stores/studentsStore'
import { formatDate } from '@ga-personal/shared'

const { t } = useI18n()
const financeStore = useFinanceStore()
const studentsStore = useStudentsStore()

const showAddModal = ref(false)
const isSubmitting = ref(false)
const submitError = ref('')

const newSubscription = reactive({
  studentId: '',
  planId: '',
  startDate: new Date().toISOString().split('T')[0],
  status: 'active'
})

onMounted(async () => {
  await Promise.all([
    financeStore.fetchSubscriptions(),
    financeStore.fetchPlans(),
    studentsStore.fetchStudents()
  ])
})

function closeModal() {
  showAddModal.value = false
  submitError.value = ''
  newSubscription.studentId = ''
  newSubscription.planId = ''
  newSubscription.startDate = new Date().toISOString().split('T')[0]
  newSubscription.status = 'active'
}

async function handleAddSubscription() {
  if (!newSubscription.studentId || !newSubscription.planId || !newSubscription.startDate) {
    submitError.value = t('common.requiredFields')
    return
  }

  isSubmitting.value = true
  submitError.value = ''

  try {
    await financeStore.createSubscription({
      student_id: newSubscription.studentId,
      plan_id: newSubscription.planId,
      start_date: newSubscription.startDate,
      status: newSubscription.status
    })
    closeModal()
    await financeStore.fetchSubscriptions()
  } catch (err: any) {
    submitError.value = err.message || t('common.error')
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="text-display-md text-smoke">{{ t('finance.subscriptions') }}</h1>
      <button @click="showAddModal = true" class="btn btn-primary">{{ t('finance.addSubscription') }}</button>
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
        <div class="space-y-2 text-sm text-stone">
          <p>{{ t('finance.plan') }}: {{ sub.plan?.name }}</p>
          <p>{{ t('finance.startDate') }}: {{ formatDate(sub.startDate) }}</p>
          <p>{{ t('finance.endDate') }}: {{ formatDate(sub.endDate) }}</p>
        </div>
      </div>
    </div>

    <div v-if="financeStore.subscriptions.length === 0" class="card text-center py-12">
      <p class="text-stone">{{ t('finance.noSubscriptions') }}</p>
    </div>

    <!-- Add Subscription Modal -->
    <div v-if="showAddModal" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeModal"></div>
      <div class="relative bg-surface-1 border border-surface-3 rounded-xl p-6 w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-lime">{{ t('finance.addSubscription') }}</h2>
          <button @click="closeModal" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>

        <form @submit.prevent="handleAddSubscription" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2">{{ t('students.title') }} *</label>
            <select v-model="newSubscription.studentId" class="input w-full" required>
              <option value="">{{ t('common.select') }}</option>
              <option v-for="student in studentsStore.students" :key="student.id" :value="student.id">
                {{ student.user?.firstName }} {{ student.user?.lastName }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('finance.plan') }} *</label>
            <select v-model="newSubscription.planId" class="input w-full" required>
              <option value="">{{ t('common.select') }}</option>
              <option v-for="plan in financeStore.plans" :key="plan.id" :value="plan.id">
                {{ plan.name }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('finance.startDate') }} *</label>
            <input v-model="newSubscription.startDate" type="date" class="input w-full" required />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('finance.status') }}</label>
            <select v-model="newSubscription.status" class="input w-full">
              <option value="active">{{ t('finance.active') }}</option>
              <option value="cancelled">{{ t('finance.cancelled') }}</option>
              <option value="expired">{{ t('finance.expired') }}</option>
            </select>
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
