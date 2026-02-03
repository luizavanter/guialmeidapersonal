<script setup lang="ts">
import { onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import { useStudentsStore } from '@/stores/studentsStore'

const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const studentsStore = useStudentsStore()

const studentId = route.params.studentId as string

onMounted(async () => {
  if (!studentId) {
    await studentsStore.fetchStudents()
  }
})

function selectStudent(id: string) {
  router.push(`/evolution/${id}`)
}
</script>

<template>
  <div class="space-y-6">
    <h1 class="font-display text-4xl text-lime">{{ t('evolution.title') }}</h1>

    <!-- Student Selection (when no student is selected) -->
    <div v-if="!studentId">
      <p class="text-smoke/60 mb-6">{{ t('evolution.selectStudent') }}</p>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="student in studentsStore.students"
          :key="student.id"
          @click="selectStudent(student.id)"
          class="card hover:border-lime/50 cursor-pointer transition-all"
        >
          <div class="flex items-center space-x-4">
            <div class="w-12 h-12 bg-ocean rounded-full flex items-center justify-center text-white text-xl font-bold">
              {{ student.user?.firstName?.[0] }}{{ student.user?.lastName?.[0] }}
            </div>
            <div>
              <h3 class="font-medium">{{ student.user?.firstName }} {{ student.user?.lastName }}</h3>
              <p class="text-sm text-smoke/60">{{ student.user?.email }}</p>
            </div>
          </div>
        </div>
      </div>

      <div v-if="studentsStore.students.length === 0" class="card text-center py-12">
        <p class="text-smoke/40">{{ t('students.noStudentsFound') }}</p>
      </div>
    </div>

    <!-- Evolution Dashboard (when student is selected) -->
    <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div class="card hover:border-lime/50 cursor-pointer transition-all">
        <div class="text-center">
          <div class="text-6xl mb-4">📊</div>
          <h3 class="font-display text-2xl mb-2">{{ t('evolution.bodyAssessments') }}</h3>
          <p class="text-smoke/60">{{ t('evolution.weight') }}, {{ t('evolution.measurements') }}, {{ t('evolution.bodyFat') }}</p>
        </div>
      </div>

      <div class="card hover:border-lime/50 cursor-pointer transition-all">
        <div class="text-center">
          <div class="text-6xl mb-4">📸</div>
          <h3 class="font-display text-2xl mb-2">{{ t('evolution.photos') }}</h3>
          <p class="text-smoke/60">{{ t('evolution.photoComparison') }}</p>
        </div>
      </div>

      <div class="card hover:border-lime/50 cursor-pointer transition-all">
        <div class="text-center">
          <div class="text-6xl mb-4">🎯</div>
          <h3 class="font-display text-2xl mb-2">{{ t('evolution.goals') }}</h3>
          <p class="text-smoke/60">{{ t('evolution.progress') }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
