<script setup lang="ts">
import { useAuth } from '@ga-personal/shared'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'

const emit = defineEmits<{
  toggleSidebar: []
}>()

const { user, logout } = useAuth()
const router = useRouter()
const { t } = useI18n()

async function handleLogout() {
  await logout()
  router.push('/login')
}
</script>

<template>
  <header class="h-16 bg-coal border-b border-smoke/10 flex items-center justify-between px-6">
    <button
      @click="emit('toggleSidebar')"
      class="p-2 rounded-lg hover:bg-smoke/5 transition-colors"
    >
      <span class="text-xl">☰</span>
    </button>

    <div class="flex items-center space-x-4">
      <!-- Notifications -->
      <button class="p-2 rounded-lg hover:bg-smoke/5 transition-colors relative">
        <span class="text-xl">🔔</span>
        <span class="absolute top-1 right-1 w-2 h-2 bg-lime rounded-full"></span>
      </button>

      <!-- User menu -->
      <div class="flex items-center space-x-3">
        <div class="w-10 h-10 bg-lime rounded-full flex items-center justify-center text-coal font-bold">
          {{ user?.firstName?.[0] }}{{ user?.lastName?.[0] }}
        </div>
        <div class="hidden md:block">
          <p class="text-sm font-medium">{{ user?.firstName }} {{ user?.lastName }}</p>
          <p class="text-xs text-smoke/60">{{ user?.email }}</p>
        </div>
        <button
          @click="handleLogout"
          class="p-2 rounded-lg hover:bg-smoke/5 transition-colors"
          :title="t('auth.logout')"
        >
          <span class="text-xl">🚪</span>
        </button>
      </div>
    </div>
  </header>
</template>
