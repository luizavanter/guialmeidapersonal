<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useStudentsStore } from '@/stores/studentsStore'
import type { Student } from '@ga-personal/shared'

import { Pencil, Trash2 } from 'lucide-vue-next'

const { t } = useI18n()
const router = useRouter()
const studentsStore = useStudentsStore()

const searchQuery = ref('')
const statusFilter = ref('all')
const showAddModal = ref(false)
const showEditModal = ref(false)
const showDeleteConfirm = ref(false)
const isSubmitting = ref(false)
const submitError = ref('')
const selectedStudent = ref<Student | null>(null)

const newStudent = reactive({
  email: '',
  password: '',
  firstName: '',
  lastName: '',
  phone: '',
  status: 'active'
})

const editStudent = reactive({
  id: '',
  email: '',
  firstName: '',
  lastName: '',
  phone: '',
  status: 'active'
})

onMounted(async () => {
  await studentsStore.fetchStudents()
})

const filteredStudents = computed(() => {
  let result = studentsStore.students

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(s =>
      s.user?.firstName?.toLowerCase().includes(query) ||
      s.user?.lastName?.toLowerCase().includes(query) ||
      s.user?.email?.toLowerCase().includes(query)
    )
  }

  if (statusFilter.value !== 'all') {
    result = result.filter(s => s.status === statusFilter.value)
  }

  return result
})

function viewStudent(student: Student) {
  router.push(`/students/${student.id}`)
}

function closeModal() {
  showAddModal.value = false
  submitError.value = ''
  // Reset form
  newStudent.email = ''
  newStudent.password = ''
  newStudent.firstName = ''
  newStudent.lastName = ''
  newStudent.phone = ''
  newStudent.status = 'active'
}

async function handleAddStudent() {
  if (!newStudent.email || !newStudent.firstName || !newStudent.lastName) {
    submitError.value = t('common.requiredFields')
    return
  }

  isSubmitting.value = true
  submitError.value = ''

  try {
    // Backend expects flat structure: email, password, full_name, phone, status
    await studentsStore.createStudent({
      email: newStudent.email,
      password: newStudent.password || 'temp123456',
      full_name: `${newStudent.firstName} ${newStudent.lastName}`,
      phone: newStudent.phone || null,
      status: newStudent.status
    })
    closeModal()
    await studentsStore.fetchStudents()
  } catch (err: any) {
    submitError.value = err.message || t('common.error')
  } finally {
    isSubmitting.value = false
  }
}

function openEditModal(student: Student, event: Event) {
  event.stopPropagation()
  selectedStudent.value = student
  editStudent.id = student.id
  editStudent.email = student.user?.email || ''
  editStudent.firstName = student.user?.firstName || ''
  editStudent.lastName = student.user?.lastName || ''
  editStudent.phone = student.user?.phone || ''
  editStudent.status = student.status || 'active'
  showEditModal.value = true
}

function closeEditModal() {
  showEditModal.value = false
  submitError.value = ''
  selectedStudent.value = null
}

async function handleEditStudent() {
  if (!editStudent.firstName || !editStudent.lastName) {
    submitError.value = t('common.requiredFields')
    return
  }

  isSubmitting.value = true
  submitError.value = ''

  try {
    await studentsStore.updateStudent(editStudent.id, {
      student: {
        full_name: `${editStudent.firstName} ${editStudent.lastName}`,
        phone: editStudent.phone || null,
        status: editStudent.status
      }
    })
    closeEditModal()
    await studentsStore.fetchStudents()
  } catch (err: any) {
    submitError.value = err.message || t('common.error')
  } finally {
    isSubmitting.value = false
  }
}

function openDeleteConfirm(student: Student, event: Event) {
  event.stopPropagation()
  selectedStudent.value = student
  showDeleteConfirm.value = true
}

function closeDeleteConfirm() {
  showDeleteConfirm.value = false
  selectedStudent.value = null
}

async function handleDeleteStudent() {
  if (!selectedStudent.value) return

  isSubmitting.value = true

  try {
    await studentsStore.deleteStudent(selectedStudent.value.id)
    closeDeleteConfirm()
    await studentsStore.fetchStudents()
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
      <div>
        <h1 class="text-display-md text-smoke mb-2">{{ t('students.title') }}</h1>
        <p class="text-stone">
          {{ studentsStore.totalStudents }} {{ t('students.title').toLowerCase() }}
        </p>
      </div>
      <button @click="showAddModal = true" class="btn btn-primary">
        {{ t('students.addStudent') }}
      </button>
    </div>

    <!-- Filters -->
    <div class="card">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <input
            v-model="searchQuery"
            type="text"
            class="input"
            :placeholder="t('students.searchStudents')"
          />
        </div>
        <div>
          <select v-model="statusFilter" class="input">
            <option value="all">{{ t('common.selectAll') }}</option>
            <option value="active">{{ t('students.active') }}</option>
            <option value="inactive">{{ t('students.inactive') }}</option>
            <option value="suspended">{{ t('students.suspended') }}</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Students List -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        v-for="student in filteredStudents"
        :key="student.id"
        class="card hover:border-lime/50 cursor-pointer transition-all"
        @click="viewStudent(student)"
      >
        <div class="flex items-start space-x-4">
          <div class="w-16 h-16 bg-ocean rounded-full flex items-center justify-center text-white text-2xl font-bold flex-shrink-0">
            {{ student.user?.firstName?.[0] }}{{ student.user?.lastName?.[0] }}
          </div>
          <div class="flex-1 min-w-0">
            <h3 class="font-medium text-lg truncate">
              {{ student.user?.firstName }} {{ student.user?.lastName }}
            </h3>
            <p class="text-sm text-stone truncate">{{ student.user?.email }}</p>
            <p class="text-sm text-stone truncate">{{ student.user?.phone }}</p>

            <div class="flex items-center justify-between mt-3">
              <span :class="[
                'badge',
                student.status === 'active' ? 'badge-success' :
                student.status === 'inactive' ? 'badge-warning' :
                'badge-error'
              ]">
                {{ t(`students.${student.status}`) }}
              </span>
              <div class="flex space-x-2">
                <button
                  @click="openEditModal(student, $event)"
                  class="p-2 text-stone hover:text-lime hover:bg-surface-3 rounded-lg transition-colors"
                  :title="t('common.edit')"
                >
              <Pencil class="w-4 h-4" />
                </button>
                <button
                  @click="openDeleteConfirm(student, $event)"
                  class="p-2 text-stone hover:text-red-500 hover:bg-surface-3 rounded-lg transition-colors"
                  :title="t('common.delete')"
                >
              <Trash2 class="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-if="filteredStudents.length === 0" class="card text-center py-12">
      <p class="text-stone text-lg">{{ t('students.noStudentsFound') }}</p>
    </div>

    <!-- Add Student Modal -->
    <div v-if="showAddModal" class="fixed inset-0 z-50 flex items-center justify-center">
      <!-- Backdrop -->
      <div class="absolute inset-0 bg-black/70" @click="closeModal"></div>

      <!-- Modal -->
      <div class="relative bg-surface-1 border border-surface-3 rounded-xl p-6 w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-lime">{{ t('students.addStudent') }}</h2>
          <button @click="closeModal" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>

        <form @submit.prevent="handleAddStudent" class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-2">{{ t('common.firstName') }} *</label>
              <input v-model="newStudent.firstName" type="text" class="input w-full" required />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">{{ t('common.lastName') }} *</label>
              <input v-model="newStudent.lastName" type="text" class="input w-full" required />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('auth.email') }} *</label>
            <input v-model="newStudent.email" type="email" class="input w-full" required />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('auth.password') }}</label>
            <input v-model="newStudent.password" type="password" class="input w-full" placeholder="temp123456" />
            <p class="text-xs text-stone mt-1">{{ t('students.passwordHint') }}</p>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.phone') }}</label>
            <input v-model="newStudent.phone" type="tel" class="input w-full" />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('students.status') }}</label>
            <select v-model="newStudent.status" class="input w-full">
              <option value="active">{{ t('students.active') }}</option>
              <option value="inactive">{{ t('students.inactive') }}</option>
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

    <!-- Edit Student Modal -->
    <div v-if="showEditModal" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeEditModal"></div>
      <div class="relative bg-surface-1 border border-surface-3 rounded-xl p-6 w-full max-w-md mx-4 max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-lime">{{ t('students.editStudent') }}</h2>
          <button @click="closeEditModal" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>

        <form @submit.prevent="handleEditStudent" class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-2">{{ t('common.firstName') }} *</label>
              <input v-model="editStudent.firstName" type="text" class="input w-full" required />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">{{ t('common.lastName') }} *</label>
              <input v-model="editStudent.lastName" type="text" class="input w-full" required />
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('auth.email') }}</label>
            <input v-model="editStudent.email" type="email" class="input w-full" disabled />
            <p class="text-xs text-stone mt-1">{{ t('students.emailCannotChange') }}</p>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('common.phone') }}</label>
            <input v-model="editStudent.phone" type="tel" class="input w-full" />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('students.status') }}</label>
            <select v-model="editStudent.status" class="input w-full">
              <option value="active">{{ t('students.active') }}</option>
              <option value="inactive">{{ t('students.inactive') }}</option>
              <option value="suspended">{{ t('students.suspended') }}</option>
            </select>
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

    <!-- Delete Confirmation Modal -->
    <div v-if="showDeleteConfirm" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeDeleteConfirm"></div>
      <div class="relative bg-surface-1 border border-surface-3 rounded-xl p-6 w-full max-w-md mx-4">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-red-500">{{ t('students.deleteStudent') }}</h2>
          <button @click="closeDeleteConfirm" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>

        <p class="text-smoke/90 mb-6">
          {{ t('students.deleteConfirmation') }}
          <strong class="block mt-2 text-smoke">
            {{ selectedStudent?.user?.firstName }} {{ selectedStudent?.user?.lastName }}
          </strong>
        </p>

        <div class="flex justify-end space-x-3">
          <button @click="closeDeleteConfirm" class="btn btn-secondary">
            {{ t('common.cancel') }}
          </button>
          <button @click="handleDeleteStudent" :disabled="isSubmitting" class="btn bg-red-600 hover:bg-red-700 text-white">
            {{ isSubmitting ? t('common.loading') : t('common.delete') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
