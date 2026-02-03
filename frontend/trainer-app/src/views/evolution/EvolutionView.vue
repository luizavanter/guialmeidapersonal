<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { useRoute } from 'vue-router'

const { t } = useI18n()
const route = useRoute()

const studentId = route.params.studentId as string
</script>

<template>
  <div class="space-y-6">
    <h1 class="font-display text-4xl text-lime">{{ t('evolution.title') }}</h1>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div class="card">
        <div class="text-center">
          <div class="text-6xl mb-4">📊</div>
          <h3 class="font-display text-2xl mb-2">{{ t('evolution.bodyAssessments') }}</h3>
          <p class="text-smoke/60">Weight, measurements, body composition</p>
        </div>
      </div>

      <div class="card">
        <div class="text-center">
          <div class="text-6xl mb-4">📸</div>
          <h3 class="font-display text-2xl mb-2">{{ t('evolution.photos') }}</h3>
          <p class="text-smoke/60">Progress photos comparison</p>
        </div>
      </div>

      <div class="card">
        <div class="text-center">
          <div class="text-6xl mb-4">🎯</div>
          <h3 class="font-display text-2xl mb-2">{{ t('evolution.goals') }}</h3>
          <p class="text-smoke/60">Track goals and achievements</p>
        </div>
      </div>
    </div>
  </div>
</template>
