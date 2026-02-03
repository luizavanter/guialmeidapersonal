<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="font-display text-4xl text-lime">{{ t('messages.title') }}</h1>
      <button class="btn btn-primary">{{ t('messages.compose') }}</button>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Inbox list -->
      <div class="lg:col-span-1 card">
        <h2 class="font-display text-xl mb-4">{{ t('messages.inbox') }}</h2>
        <div class="space-y-2">
          <div class="p-3 bg-smoke/5 rounded-lg hover:bg-smoke/10 cursor-pointer">
            <p class="font-medium">Student Name</p>
            <p class="text-sm text-smoke/60 truncate">Message preview...</p>
          </div>
        </div>
      </div>

      <!-- Message detail -->
      <div class="lg:col-span-2 card">
        <div class="text-center py-12 text-smoke/40">
          {{ t('messages.noMessages') }}
        </div>
      </div>
    </div>
  </div>
</template>
