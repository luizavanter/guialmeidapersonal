<template>
  <div class="min-h-screen bg-coal">
    <!-- Sidebar -->
    <aside
      :class="sidebarClasses"
      class="fixed inset-y-0 left-0 z-50 w-64 bg-coal border-r border-surface-3 transform transition-transform duration-200 ease-in-out"
    >
      <div class="flex flex-col h-full">
        <!-- Logo -->
        <div class="flex items-center justify-between px-6 py-4 border-b border-surface-3">
          <div class="flex items-center gap-3">
            <img src="@ga-personal/shared/src/assets/logo-monogram-64.png" alt="GA" class="h-8 w-8" />
            <span class="text-xs font-medium text-stone uppercase tracking-wider">{{ t('nav.studentLabel') }}</span>
          </div>
          <button
            type="button"
            class="lg:hidden text-stone hover:text-smoke"
            @click="toggleSidebar"
          >
            <X class="w-5 h-5" />
          </button>
        </div>

        <!-- Navigation -->
        <nav class="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
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
        <div class="px-4 py-4 border-t border-surface-3">
          <div class="flex items-center gap-3 mb-3">
            <div class="w-10 h-10 rounded-full bg-lime/15 border border-lime/20 flex items-center justify-center text-lime font-bold text-sm">
              {{ userInitials }}
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-smoke truncate">{{ user?.name || [user?.firstName, user?.lastName].filter(Boolean).join(' ') }}</p>
              <p class="text-xs text-stone truncate">{{ user?.email }}</p>
            </div>
          </div>
          <button @click="handleLogout" class="w-full flex items-center justify-center gap-2 px-3 py-2 text-sm text-stone hover:text-smoke hover:bg-surface-2 rounded-lg transition-colors">
            <LogOut class="w-4 h-4" />
            {{ t('auth.logout') }}
          </button>
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
      <header class="lg:hidden sticky top-0 z-30 bg-coal border-b border-surface-3 px-4 py-3">
        <div class="flex items-center justify-between">
          <button
            type="button"
            class="text-stone hover:text-smoke"
            @click="toggleSidebar"
          >
            <Menu class="w-5 h-5" />
          </button>
          <img src="@ga-personal/shared/src/assets/logo-monogram-48.png" alt="GA" class="h-6 w-6" />
          <div class="w-5"></div>
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
import { ref, computed, markRaw } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuth } from '@/composables/useAuth'
import { useMessagesStore } from '@/stores/messages'
import {
  LayoutDashboard, Dumbbell, TrendingUp, Calendar,
  MessageSquare, User, X, Menu, LogOut
} from 'lucide-vue-next'

const { t } = useI18n()
const router = useRouter()
const route = useRoute()
const { user, logout } = useAuth()
const messagesStore = useMessagesStore()

const sidebarOpen = ref(false)

const userInitials = computed(() => {
  const name = user.value?.name || [user.value?.firstName, user.value?.lastName].filter(Boolean).join(' ')
  if (!name) return 'U'
  return name
    .split(' ')
    .map((n: string) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
})

const navItems = computed(() => [
  { name: 'dashboard', path: '/', label: 'nav.dashboard', icon: markRaw(LayoutDashboard) },
  { name: 'workouts', path: '/workouts', label: 'nav.workouts', icon: markRaw(Dumbbell) },
  { name: 'evolution', path: '/evolution', label: 'nav.evolution', icon: markRaw(TrendingUp) },
  { name: 'schedule', path: '/schedule', label: 'nav.schedule', icon: markRaw(Calendar) },
  { name: 'messages', path: '/messages', label: 'nav.messages', badge: messagesStore.unreadCount || undefined, icon: markRaw(MessageSquare) },
  { name: 'profile', path: '/profile', label: 'nav.profile', icon: markRaw(User) },
])

const sidebarClasses = computed(() => {
  return sidebarOpen.value ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
})

const getLinkClasses = (path: string) => {
  const isActive = path === '/' ? route.path === '/' : route.path.startsWith(path)
  const base = 'flex items-center gap-3 px-4 py-3 rounded-lg transition-colors text-sm font-medium'
  return isActive
    ? `${base} bg-lime/10 text-lime`
    : `${base} text-stone hover:text-smoke hover:bg-surface-2`
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
