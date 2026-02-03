<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useStudentsStore } from '@/stores/studentsStore'
import type { Student } from '@ga-personal/shared'

const { t } = useI18n()
const router = useRouter()
const studentsStore = useStudentsStore()

const searchQuery = ref('')
const statusFilter = ref('all')
const showAddModal = ref(false)

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
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="font-display text-4xl text-lime mb-2">{{ t('students.title') }}</h1>
        <p class="text-smoke/60">
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
            <p class="text-sm text-smoke/60 truncate">{{ student.user?.email }}</p>
            <p class="text-sm text-smoke/60 truncate">{{ student.user?.phone }}</p>

            <div class="flex items-center space-x-2 mt-3">
              <span :class="[
                'badge',
                student.status === 'active' ? 'badge-success' :
                student.status === 'inactive' ? 'badge-warning' :
                'badge-error'
              ]">
                {{ t(`students.${student.status}`) }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-if="filteredStudents.length === 0" class="card text-center py-12">
      <p class="text-smoke/40 text-lg">{{ t('students.noStudentsFound') }}</p>
    </div>
  </div>
</template>
