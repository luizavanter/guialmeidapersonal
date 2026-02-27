<script setup lang="ts">
import { onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import { useStudentsStore } from '@/stores/studentsStore'
import { Activity, Camera, Target } from 'lucide-vue-next'

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
  <div class="space-y-8">
    <h1 class="text-display-md text-smoke">{{ t('evolution.title') }}</h1>

    <!-- Student Selection -->
    <div v-if="!studentId">
      <p class="text-stone mb-6">{{ t('evolution.selectStudent') }}</p>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        <div
          v-for="student in studentsStore.students"
          :key="student.id"
          @click="selectStudent(student.id)"
          class="card hover:border-lime/30 cursor-pointer transition-all"
        >
          <div class="flex items-center space-x-4">
            <div class="w-10 h-10 bg-ocean/15 border border-ocean/20 rounded-full flex items-center justify-center text-ocean text-sm font-semibold">
              {{ student.user?.firstName?.[0] }}{{ student.user?.lastName?.[0] }}
            </div>
            <div>
              <h3 class="font-medium text-sm text-smoke">{{ student.user?.firstName }} {{ student.user?.lastName }}</h3>
              <p class="text-xs text-stone">{{ student.user?.email }}</p>
            </div>
          </div>
        </div>
      </div>

      <div v-if="studentsStore.students.length === 0" class="card text-center py-12">
        <p class="text-stone">{{ t('students.noStudentsFound') }}</p>
      </div>
    </div>

    <!-- Evolution Dashboard -->
    <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-5">
      <div class="card group hover:border-lime/30 cursor-pointer transition-all">
        <div class="flex flex-col items-center text-center py-4">
          <div class="w-14 h-14 bg-lime/8 rounded-ga-lg flex items-center justify-center mb-4 group-hover:bg-lime/15 transition-colors">
            <Activity :size="28" :stroke-width="1.5" class="text-lime" />
          </div>
          <h3 class="text-lg font-display font-semibold text-smoke mb-1">{{ t('evolution.bodyAssessments') }}</h3>
          <p class="text-sm text-stone">{{ t('evolution.weight') }}, {{ t('evolution.measurements') }}, {{ t('evolution.bodyFat') }}</p>
        </div>
      </div>

      <div class="card group hover:border-lime/30 cursor-pointer transition-all">
        <div class="flex flex-col items-center text-center py-4">
          <div class="w-14 h-14 bg-ocean/8 rounded-ga-lg flex items-center justify-center mb-4 group-hover:bg-ocean/15 transition-colors">
            <Camera :size="28" :stroke-width="1.5" class="text-ocean" />
          </div>
          <h3 class="text-lg font-display font-semibold text-smoke mb-1">{{ t('evolution.photos') }}</h3>
          <p class="text-sm text-stone">{{ t('evolution.photoComparison') }}</p>
        </div>
      </div>

      <div class="card group hover:border-lime/30 cursor-pointer transition-all">
        <div class="flex flex-col items-center text-center py-4">
          <div class="w-14 h-14 bg-surface-3 rounded-ga-lg flex items-center justify-center mb-4 group-hover:bg-surface-4 transition-colors">
            <Target :size="28" :stroke-width="1.5" class="text-smoke" />
          </div>
          <h3 class="text-lg font-display font-semibold text-smoke mb-1">{{ t('evolution.goals') }}</h3>
          <p class="text-sm text-stone">{{ t('evolution.progress') }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
