<script setup lang="ts">
import { ref, onMounted, markRaw } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useStudentsStore } from '@/stores/studentsStore'
import { User, Dumbbell, TrendingUp, Wallet, ClipboardList, ArrowLeft } from 'lucide-vue-next'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const studentsStore = useStudentsStore()

const activeTab = ref('info')

const tabs = [
  { key: 'info', label: t('students.personalInfo'), icon: markRaw(User) },
  { key: 'workouts', label: t('students.workoutPlans'), icon: markRaw(Dumbbell) },
  { key: 'evolution', label: t('evolution.title'), icon: markRaw(TrendingUp) },
  { key: 'payments', label: t('finance.payments'), icon: markRaw(Wallet) },
  { key: 'history', label: t('students.activityHistory'), icon: markRaw(ClipboardList) },
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
      <button @click="goBack" class="flex items-center space-x-2 text-stone hover:text-smoke transition-colors px-3 py-2 rounded-ga hover:bg-surface-2">
        <ArrowLeft :size="18" :stroke-width="1.75" />
        <span class="text-sm font-medium">{{ t('common.back') }}</span>
      </button>
      <div class="flex-1">
        <h1 class="text-display-sm text-smoke">
          {{ studentsStore.currentStudent?.user?.firstName }} {{ studentsStore.currentStudent?.user?.lastName }}
        </h1>
        <p class="text-sm text-stone">{{ studentsStore.currentStudent?.user?.email }}</p>
      </div>
      <span :class="[
        'text-xs font-medium px-3 py-1.5 rounded-full',
        studentsStore.currentStudent?.status === 'active'
          ? 'bg-lime/10 text-lime'
          : 'bg-yellow-400/10 text-yellow-400'
      ]">
        {{ t(`students.${studentsStore.currentStudent?.status}`) }}
      </span>
    </div>

    <!-- Tabs -->
    <div class="card">
      <div class="flex space-x-2 border-b border-surface-3 pb-4">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          @click="activeTab = tab.key"
          :class="[
            'flex items-center space-x-2 px-4 py-2 rounded-ga transition-colors text-sm',
            activeTab === tab.key
              ? 'bg-lime/10 text-lime'
              : 'text-stone hover:bg-surface-2 hover:text-smoke'
          ]"
        >
          <component :is="tab.icon" :size="16" :stroke-width="1.75" />
          <span class="font-medium">{{ tab.label }}</span>
        </button>
      </div>

      <!-- Tab Content -->
      <div class="pt-6">
        <!-- Personal Info -->
        <div v-if="activeTab === 'info'" class="space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 class="text-sm font-semibold text-smoke mb-4 uppercase tracking-wider">{{ t('students.contactInfo') }}</h3>
              <div class="space-y-4">
                <div>
                  <label class="text-xs text-stone uppercase tracking-wider">{{ t('auth.email') }}</label>
                  <p class="text-sm font-medium text-smoke mt-1">{{ studentsStore.currentStudent?.user?.email }}</p>
                </div>
                <div>
                  <label class="text-xs text-stone uppercase tracking-wider">{{ t('students.phone') }}</label>
                  <p class="text-sm font-medium text-smoke mt-1">{{ studentsStore.currentStudent?.user?.phone || '-' }}</p>
                </div>
              </div>
            </div>

            <div>
              <h3 class="text-sm font-semibold text-smoke mb-4 uppercase tracking-wider">{{ t('students.emergencyContact') }}</h3>
              <div class="space-y-4">
                <div>
                  <label class="text-xs text-stone uppercase tracking-wider">{{ t('students.emergencyContact') }}</label>
                  <p class="text-sm font-medium text-smoke mt-1">{{ studentsStore.currentStudent?.emergencyContact || '-' }}</p>
                </div>
                <div>
                  <label class="text-xs text-stone uppercase tracking-wider">{{ t('students.phone') }}</label>
                  <p class="text-sm font-medium text-smoke mt-1">{{ studentsStore.currentStudent?.emergencyPhone || '-' }}</p>
                </div>
              </div>
            </div>
          </div>

          <div>
            <h3 class="text-sm font-semibold text-smoke mb-4 uppercase tracking-wider">{{ t('students.medicalInfo') }}</h3>
            <div class="p-4 bg-surface-2 rounded-ga">
              <p class="text-sm text-smoke/80">{{ studentsStore.currentStudent?.medicalNotes || t('common.noData') }}</p>
            </div>
          </div>

          <div>
            <h3 class="text-sm font-semibold text-smoke mb-4 uppercase tracking-wider">{{ t('students.goals') }}</h3>
            <div class="p-4 bg-surface-2 rounded-ga">
              <p class="text-sm text-smoke/80">{{ studentsStore.currentStudent?.goals || t('common.noData') }}</p>
            </div>
          </div>
        </div>

        <!-- Empty States for other tabs -->
        <div v-else-if="activeTab === 'workouts'" class="text-center py-16">
          <Dumbbell :size="32" :stroke-width="1.5" class="text-stone mx-auto mb-3" />
          <p class="text-stone text-sm">{{ t('students.workoutPlans') }} - {{ t('common.noData') }}</p>
        </div>

        <div v-else-if="activeTab === 'evolution'" class="text-center py-16">
          <TrendingUp :size="32" :stroke-width="1.5" class="text-stone mx-auto mb-3" />
          <p class="text-stone text-sm">{{ t('evolution.title') }} - {{ t('common.noData') }}</p>
        </div>

        <div v-else-if="activeTab === 'payments'" class="text-center py-16">
          <Wallet :size="32" :stroke-width="1.5" class="text-stone mx-auto mb-3" />
          <p class="text-stone text-sm">{{ t('finance.payments') }} - {{ t('common.noData') }}</p>
        </div>

        <div v-else-if="activeTab === 'history'" class="text-center py-16">
          <ClipboardList :size="32" :stroke-width="1.5" class="text-stone mx-auto mb-3" />
          <p class="text-stone text-sm">{{ t('students.activityHistory') }} - {{ t('common.noData') }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
