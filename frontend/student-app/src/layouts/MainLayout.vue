<template>
  <div class="min-h-screen bg-coal">
    <!-- Sidebar -->
    <aside
      :class="sidebarClasses"
      class="fixed inset-y-0 left-0 z-50 w-64 bg-coal border-r border-smoke/10 transform transition-transform duration-200 ease-in-out"
    >
      <div class="flex flex-col h-full">
        <!-- Logo -->
        <div class="flex items-center justify-between px-6 py-4 border-b border-smoke/10">
          <h1 class="text-2xl font-display text-lime">GA PERSONAL</h1>
          <button
            type="button"
            class="lg:hidden text-smoke hover:text-lime"
            @click="toggleSidebar"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <!-- Navigation -->
        <nav class="flex-1 px-4 py-6 space-y-2 overflow-y-auto">
          <router-link
            v-for="item in navItems"
            :key="item.name"
            :to="item.path"
            :class="getLinkClasses(item.path)"
            @click="closeSidebarOnMobile"
          >
            <component :is="item.icon" class="w-5 h-5" />
            <span>{{ t(item.label) }}</span>
            <span v-if="item.badge" class="ml-auto bg-lime text-coal text-xs font-bold px-2 py-0.5 rounded-full">
              {{ item.badge }}
            </span>
          </router-link>
        </nav>

        <!-- User section -->
        <div class="px-4 py-4 border-t border-smoke/10">
          <div class="flex items-center gap-3 mb-3">
            <div class="w-10 h-10 rounded-full bg-lime/20 flex items-center justify-center text-lime font-bold">
              {{ userInitials }}
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-smoke truncate">{{ user?.name }}</p>
              <p class="text-xs text-smoke/60 truncate">{{ user?.email }}</p>
            </div>
          </div>
          <Button variant="ghost" size="sm" full-width @click="handleLogout">
            {{ t('auth.logout') }}
          </Button>
        </div>
      </div>
    </aside>

    <!-- Mobile backdrop -->
    <div
      v-if="sidebarOpen"
      class="fixed inset-0 z-40 bg-coal/80 lg:hidden"
      @click="closeSidebar"
    ></div>

    <!-- Main content -->
    <div class="lg:pl-64">
      <!-- Mobile header -->
      <header class="lg:hidden sticky top-0 z-30 bg-coal border-b border-smoke/10 px-4 py-3">
        <div class="flex items-center justify-between">
          <button
            type="button"
            class="text-smoke hover:text-lime"
            @click="toggleSidebar"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
          <h1 class="text-lg font-display text-lime">GA PERSONAL</h1>
          <div class="w-6"></div>
        </div>
      </header>

      <!-- Page content -->
      <main class="p-4 lg:p-8">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, h } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuth } from '@/composables/useAuth'
import { useMessagesStore } from '@/stores/messages'
import Button from '@/components/ui/Button.vue'

const { t } = useI18n()
const router = useRouter()
const route = useRoute()
const { user, logout } = useAuth()
const messagesStore = useMessagesStore()

const sidebarOpen = ref(false)

const userInitials = computed(() => {
  if (!user.value?.name) return 'U'
  return user.value.name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
})

const navItems = computed(() => [
  {
    name: 'dashboard',
    path: '/',
    label: 'nav.dashboard',
    icon: h('svg', { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, [
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6' })
    ]),
  },
  {
    name: 'workouts',
    path: '/workouts',
    label: 'nav.workouts',
    icon: h('svg', { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, [
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2' })
    ]),
  },
  {
    name: 'evolution',
    path: '/evolution',
    label: 'nav.evolution',
    icon: h('svg', { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, [
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z' })
    ]),
  },
  {
    name: 'schedule',
    path: '/schedule',
    label: 'nav.schedule',
    icon: h('svg', { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, [
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z' })
    ]),
  },
  {
    name: 'messages',
    path: '/messages',
    label: 'nav.messages',
    badge: messagesStore.unreadCount || undefined,
    icon: h('svg', { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, [
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z' })
    ]),
  },
  {
    name: 'profile',
    path: '/profile',
    label: 'nav.profile',
    icon: h('svg', { class: 'w-5 h-5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, [
      h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z' })
    ]),
  },
])

const sidebarClasses = computed(() => {
  return sidebarOpen.value ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
})

const getLinkClasses = (path: string) => {
  const isActive = path === '/' ? route.path === '/' : route.path.startsWith(path)
  const base = 'flex items-center gap-3 px-4 py-3 rounded-lg transition-colors text-sm font-medium'
  return isActive
    ? `${base} bg-lime/10 text-lime`
    : `${base} text-smoke/70 hover:text-smoke hover:bg-smoke/5`
}

const toggleSidebar = () => {
  sidebarOpen.value = !sidebarOpen.value
}

const closeSidebar = () => {
  sidebarOpen.value = false
}

const closeSidebarOnMobile = () => {
  if (window.innerWidth < 1024) {
    closeSidebar()
  }
}

const handleLogout = async () => {
  await logout()
}
</script>
