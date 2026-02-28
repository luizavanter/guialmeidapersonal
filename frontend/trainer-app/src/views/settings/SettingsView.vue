<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuth } from '@ga-personal/shared'

const { t, locale } = useI18n()
const { user } = useAuth()

const selectedLocale = ref(locale.value)

function changeLanguage() {
  locale.value = selectedLocale.value
  localStorage.setItem('locale', selectedLocale.value)
}
</script>

<template>
  <div class="space-y-6">
    <h1 class="text-display-md text-smoke">{{ t('nav.settings') }}</h1>

    <!-- Profile Settings -->
    <div class="card">
      <h2 class="font-display text-2xl mb-4">{{ t('nav.profile') }}</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium mb-2">{{ t('auth.name') }}</label>
          <input
            type="text"
            class="input"
            :value="`${user?.firstName} ${user?.lastName}`"
          />
        </div>
        <div>
          <label class="block text-sm font-medium mb-2">{{ t('auth.email') }}</label>
          <input type="email" class="input" :value="user?.email" />
        </div>
      </div>
    </div>

    <!-- Language Settings -->
    <div class="card">
      <h2 class="font-display text-2xl mb-4">{{ t('nav.language') }}</h2>
      <div class="flex items-center space-x-4">
        <select v-model="selectedLocale" @change="changeLanguage" class="input">
          <option value="pt-BR">Português (BR)</option>
          <option value="en-US">English (US)</option>
        </select>
      </div>
    </div>
  </div>
</template>
