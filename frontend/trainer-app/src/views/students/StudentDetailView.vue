<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useStudentsStore } from '@/stores/studentsStore'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const studentsStore = useStudentsStore()

const activeTab = ref('info')

const tabs = [
  { key: 'info', label: t('students.personalInfo'), icon: '👤' },
  { key: 'workouts', label: t('students.workoutPlans'), icon: '💪' },
  { key: 'evolution', label: t('evolution.title'), icon: '📈' },
  { key: 'payments', label: t('finance.payments'), icon: '💰' },
  { key: 'history', label: t('students.activityHistory'), icon: '📋' },
]

onMounted(async () => {
  const studentId = route.params.id as string
  await studentsStore.fetchStudent(studentId)
})

function goBack() {
  router.push('/students')
}
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center space-x-4">
      <button @click="goBack" class="btn btn-ghost">
        ← {{ t('common.back') }}
      </button>
      <div class="flex-1">
        <h1 class="font-display text-4xl text-lime">
          {{ studentsStore.currentStudent?.user?.firstName }} {{ studentsStore.currentStudent?.user?.lastName }}
        </h1>
        <p class="text-smoke/60">{{ studentsStore.currentStudent?.user?.email }}</p>
      </div>
      <span :class="[
        'badge text-base',
        studentsStore.currentStudent?.status === 'active' ? 'badge-success' : 'badge-warning'
      ]">
        {{ t(`students.${studentsStore.currentStudent?.status}`) }}
      </span>
    </div>

    <!-- Tabs -->
    <div class="card">
      <div class="flex space-x-4 border-b border-smoke/10 pb-4">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          @click="activeTab = tab.key"
          :class="[
            'flex items-center space-x-2 px-4 py-2 rounded-lg transition-colors',
            activeTab === tab.key
              ? 'bg-lime/20 text-lime'
              : 'text-smoke/60 hover:bg-smoke/5'
          ]"
        >
          <span>{{ tab.icon }}</span>
          <span class="font-medium">{{ tab.label }}</span>
        </button>
      </div>

      <!-- Tab Content -->
      <div class="pt-6">
        <!-- Personal Info -->
        <div v-if="activeTab === 'info'" class="space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 class="font-display text-xl mb-4">{{ t('students.contactInfo') }}</h3>
              <div class="space-y-3">
                <div>
                  <label class="text-sm text-smoke/60">{{ t('auth.email') }}</label>
                  <p class="font-medium">{{ studentsStore.currentStudent?.user?.email }}</p>
                </div>
                <div>
                  <label class="text-sm text-smoke/60">{{ t('students.phone') }}</label>
                  <p class="font-medium">{{ studentsStore.currentStudent?.user?.phone || '-' }}</p>
                </div>
              </div>
            </div>

            <div>
              <h3 class="font-display text-xl mb-4">{{ t('students.emergencyContact') }}</h3>
              <div class="space-y-3">
                <div>
                  <label class="text-sm text-smoke/60">{{ t('students.emergencyContact') }}</label>
                  <p class="font-medium">{{ studentsStore.currentStudent?.emergencyContact || '-' }}</p>
                </div>
                <div>
                  <label class="text-sm text-smoke/60">{{ t('students.phone') }}</label>
                  <p class="font-medium">{{ studentsStore.currentStudent?.emergencyPhone || '-' }}</p>
                </div>
              </div>
            </div>
          </div>

          <div>
            <h3 class="font-display text-xl mb-4">{{ t('students.medicalInfo') }}</h3>
            <div class="p-4 bg-smoke/5 rounded-lg">
              <p>{{ studentsStore.currentStudent?.medicalNotes || t('common.noData') }}</p>
            </div>
          </div>

          <div>
            <h3 class="font-display text-xl mb-4">{{ t('students.goals') }}</h3>
            <div class="p-4 bg-smoke/5 rounded-lg">
              <p>{{ studentsStore.currentStudent?.goals || t('common.noData') }}</p>
            </div>
          </div>
        </div>

        <!-- Workouts Tab -->
        <div v-else-if="activeTab === 'workouts'" class="text-center py-12 text-smoke/40">
          <div class="text-4xl mb-4">💪</div>
          <p>{{ t('students.workoutPlans') }} - {{ t('common.noData') }}</p>
        </div>

        <!-- Evolution Tab -->
        <div v-else-if="activeTab === 'evolution'" class="text-center py-12 text-smoke/40">
          <div class="text-4xl mb-4">📈</div>
          <p>{{ t('evolution.title') }} - {{ t('common.noData') }}</p>
        </div>

        <!-- Payments Tab -->
        <div v-else-if="activeTab === 'payments'" class="text-center py-12 text-smoke/40">
          <div class="text-4xl mb-4">💰</div>
          <p>{{ t('finance.payments') }} - {{ t('common.noData') }}</p>
        </div>

        <!-- History Tab -->
        <div v-else-if="activeTab === 'history'" class="text-center py-12 text-smoke/40">
          <div class="text-4xl mb-4">📋</div>
          <p>{{ t('students.activityHistory') }} - {{ t('common.noData') }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
