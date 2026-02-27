<script setup lang="ts">
import { useAuth } from '@ga-personal/shared'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { Menu, Bell, LogOut } from 'lucide-vue-next'

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
  <header class="h-16 bg-coal border-b border-surface-3 flex items-center justify-between px-6">
    <button
      @click="emit('toggleSidebar')"
      class="p-2 rounded-ga hover:bg-surface-2 transition-colors text-stone hover:text-smoke"
    >
      <Menu :size="20" :stroke-width="1.75" />
    </button>

    <div class="flex items-center space-x-4">
      <!-- Notifications -->
      <button class="p-2 rounded-ga hover:bg-surface-2 transition-colors text-stone hover:text-smoke relative">
        <Bell :size="20" :stroke-width="1.75" />
        <span class="absolute top-1.5 right-1.5 w-2 h-2 bg-lime rounded-full"></span>
      </button>

      <!-- User menu -->
      <div class="flex items-center space-x-3">
        <div class="w-9 h-9 bg-lime/15 border border-lime/20 rounded-full flex items-center justify-center text-lime text-sm font-semibold">
          {{ user?.firstName?.[0] }}{{ user?.lastName?.[0] }}
        </div>
        <div class="hidden md:block">
          <p class="text-sm font-medium text-smoke">{{ user?.firstName }} {{ user?.lastName }}</p>
          <p class="text-xs text-stone">{{ user?.email }}</p>
        </div>
        <button
          @click="handleLogout"
          class="p-2 rounded-ga hover:bg-surface-2 transition-colors text-stone hover:text-smoke"
          :title="t('auth.logout')"
        >
          <LogOut :size="18" :stroke-width="1.75" />
        </button>
      </div>
    </div>
  </header>
</template>
