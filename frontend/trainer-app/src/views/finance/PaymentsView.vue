<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useFinanceStore } from '@/stores/financeStore'
import { useStudentsStore } from '@/stores/studentsStore'
import { formatCurrency, formatDate } from '@ga-personal/shared'

import { Pencil } from 'lucide-vue-next'

const { t } = useI18n()
const financeStore = useFinanceStore()
const studentsStore = useStudentsStore()

const showAddModal = ref(false)
const showViewModal = ref(false)
const showEditModal = ref(false)
const isSubmitting = ref(false)
const submitError = ref('')
const selectedPayment = ref<any>(null)

const newPayment = reactive({
  studentId: '',
  amount: '',
  dueDate: new Date().toISOString().split('T')[0],
  status: 'pending',
  description: ''
})

const editPayment = reactive({
  id: '',
  studentId: '',
  amount: '',
  dueDate: '',
  status: 'pending',
  description: ''
})

onMounted(async () => {
  await Promise.all([
    financeStore.fetchPayments(),
    studentsStore.fetchStudents()
  ])
})

function closeModal() {
  showAddModal.value = false
  submitError.value = ''
  newPayment.studentId = ''
  newPayment.amount = ''
  newPayment.dueDate = new Date().toISOString().split('T')[0]
  newPayment.status = 'pending'
  newPayment.description = ''
}

function viewPayment(payment: any) {
  selectedPayment.value = payment
  showViewModal.value = true
}

function closeViewModal() {
  showViewModal.value = false
  selectedPayment.value = null
}

function openEditModal(payment: any) {
  selectedPayment.value = payment
  editPayment.id = payment.id
  editPayment.studentId = payment.studentId || payment.student?.id || ''
  editPayment.amount = payment.amount ? (payment.amount / 100).toString() : ''
  editPayment.dueDate = payment.dueDate ? payment.dueDate.split('T')[0] : ''
  editPayment.status = payment.status || 'pending'
  editPayment.description = payment.description || payment.notes || ''
  showEditModal.value = true
}

function closeEditModal() {
  showEditModal.value = false
  submitError.value = ''
  selectedPayment.value = null
}

async function handleEditPayment() {
  if (!editPayment.amount || !editPayment.dueDate) {
    submitError.value = t('common.requiredFields')
    return
  }

  isSubmitting.value = true
  submitError.value = ''

  try {
    await financeStore.updatePayment(editPayment.id, {
      payment: {
        amount_cents: Math.round(parseFloat(editPayment.amount) * 100),
        due_date: editPayment.dueDate,
        status: editPayment.status,
        notes: editPayment.description || null
      }
    })
    closeEditModal()
    await financeStore.fetchPayments()
  } catch (err: any) {
    submitError.value = err.message || t('common.error')
  } finally {
    isSubmitting.value = false
  }
}

async function handleAddPayment() {
  if (!newPayment.studentId || !newPayment.amount || !newPayment.dueDate) {
    submitError.value = t('common.requiredFields')
    return
  }

  isSubmitting.value = true
  submitError.value = ''

  try {
    // Backend expects amount_cents (integer cents)
    await financeStore.createPayment({
      student_id: newPayment.studentId,
      amount_cents: Math.round(parseFloat(newPayment.amount) * 100),
      currency: 'BRL',
      due_date: newPayment.dueDate,
      status: newPayment.status,
      notes: newPayment.description || null,
      payment_method: 'pix'
    })
    closeModal()
    await financeStore.fetchPayments()
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
      <h1 class="text-display-md text-smoke">{{ t('finance.payments') }}</h1>
      <button @click="showAddModal = true" class="btn btn-primary">
        {{ t('finance.addPayment') }}
      </button>
    </div>

    <div class="card">
      <div class="overflow-x-auto">
        <table class="w-full">
          <thead>
            <tr class="border-b border-surface-3">
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
              class="border-b border-smoke/5 hover:bg-surface-2"
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
                <div class="flex space-x-2">
                  <button @click="viewPayment(payment)" class="btn btn-ghost btn-sm">{{ t('common.view') }}</button>
                  <button
                    @click="openEditModal(payment)"
                    class="p-2 text-stone hover:text-lime hover:bg-surface-3 rounded-lg transition-colors"
                    :title="t('common.edit')"
                  >
              <Pencil class="w-4 h-4" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div v-if="financeStore.payments.length === 0" class="text-center py-12 text-stone">
        {{ t('finance.noPayments') }}
      </div>
    </div>

    <!-- Add Payment Modal -->
    <div v-if="showAddModal" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeModal"></div>
      <div class="relative bg-surface-1 border border-surface-3 rounded-xl p-6 w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-lime">{{ t('finance.addPayment') }}</h2>
          <button @click="closeModal" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>

        <form @submit.prevent="handleAddPayment" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2">{{ t('students.title') }} *</label>
            <select v-model="newPayment.studentId" class="input w-full" required>
              <option value="">{{ t('common.select') }}</option>
              <option v-for="student in studentsStore.students" :key="student.id" :value="student.id">
                {{ student.user?.firstName }} {{ student.user?.lastName }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('finance.amount') }} *</label>
            <input v-model="newPayment.amount" type="number" step="0.01" min="0" class="input w-full" required />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('finance.dueDate') }} *</label>
            <input v-model="newPayment.dueDate" type="date" class="input w-full" required />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('finance.status') }}</label>
            <select v-model="newPayment.status" class="input w-full">
              <option value="pending">{{ t('finance.pending') }}</option>
              <option value="paid">{{ t('finance.paid') }}</option>
              <option value="overdue">{{ t('finance.overdue') }}</option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.description') }}</label>
            <textarea v-model="newPayment.description" class="input w-full" rows="2"></textarea>
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

    <!-- View Payment Modal -->
    <div v-if="showViewModal && selectedPayment" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeViewModal"></div>
      <div class="relative bg-surface-1 border border-surface-3 rounded-xl p-6 w-full max-w-md mx-4">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-lime">{{ t('finance.paymentDetails') }}</h2>
          <button @click="closeViewModal" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>

        <div class="space-y-4">
          <div>
            <span class="text-stone text-sm">{{ t('students.title') }}</span>
            <p class="font-medium">{{ selectedPayment.student?.user?.firstName }} {{ selectedPayment.student?.user?.lastName }}</p>
          </div>
          <div>
            <span class="text-stone text-sm">{{ t('finance.amount') }}</span>
            <p class="font-display text-2xl text-lime">{{ formatCurrency(selectedPayment.amount) }}</p>
          </div>
          <div>
            <span class="text-stone text-sm">{{ t('finance.dueDate') }}</span>
            <p>{{ formatDate(selectedPayment.dueDate) }}</p>
          </div>
          <div>
            <span class="text-stone text-sm">{{ t('finance.status') }}</span>
            <p>
              <span :class="[
                'badge',
                selectedPayment.status === 'paid' ? 'badge-success' :
                selectedPayment.status === 'pending' ? 'badge-warning' :
                'badge-error'
              ]">
                {{ t(`finance.${selectedPayment.status}`) }}
              </span>
            </p>
          </div>
          <div v-if="selectedPayment.description">
            <span class="text-stone text-sm">{{ t('common.description') }}</span>
            <p>{{ selectedPayment.description }}</p>
          </div>
        </div>

        <div class="flex justify-end pt-6">
          <button @click="closeViewModal" class="btn btn-secondary">
            {{ t('common.close') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Edit Payment Modal -->
    <div v-if="showEditModal" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeEditModal"></div>
      <div class="relative bg-surface-1 border border-surface-3 rounded-xl p-6 w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-lime">{{ t('finance.editPayment') }}</h2>
          <button @click="closeEditModal" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>

        <form @submit.prevent="handleEditPayment" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2">{{ t('students.title') }}</label>
            <select v-model="editPayment.studentId" class="input w-full" disabled>
              <option value="">{{ t('common.select') }}</option>
              <option v-for="student in studentsStore.students" :key="student.id" :value="student.id">
                {{ student.user?.firstName }} {{ student.user?.lastName }}
              </option>
            </select>
            <p class="text-xs text-stone mt-1">{{ t('finance.studentCannotChange') }}</p>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('finance.amount') }} *</label>
            <input v-model="editPayment.amount" type="number" step="0.01" min="0" class="input w-full" required />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('finance.dueDate') }} *</label>
            <input v-model="editPayment.dueDate" type="date" class="input w-full" required />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('finance.status') }}</label>
            <select v-model="editPayment.status" class="input w-full">
              <option value="pending">{{ t('finance.pending') }}</option>
              <option value="paid">{{ t('finance.paid') }}</option>
              <option value="overdue">{{ t('finance.overdue') }}</option>
              <option value="cancelled">{{ t('finance.cancelled') }}</option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.description') }}</label>
            <textarea v-model="editPayment.description" class="input w-full" rows="2"></textarea>
          </div>

          <div v-if="submitError" class="p-3 bg-red-500/20 text-red-400 rounded-lg text-sm">
            {{ submitError }}
          </div>

          <div class="flex justify-end space-x-3 pt-4">
            <button type="button" @click="closeEditModal" class="btn btn-secondary">
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
