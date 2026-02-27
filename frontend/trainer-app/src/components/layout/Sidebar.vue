<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import {
  LayoutDashboard,
  Users,
  Calendar,
  Dumbbell,
  TrendingUp,
  Wallet,
  MessageSquare,
  Settings,
} from 'lucide-vue-next'

const props = defineProps<{
  open: boolean
}>()

const emit = defineEmits<{
  toggle: []
}>()

const { t } = useI18n()
const route = useRoute()

const navItems = [
  { name: 'dashboard', icon: LayoutDashboard, label: t('nav.dashboard'), path: '/' },
  { name: 'students', icon: Users, label: t('nav.students'), path: '/students' },
  { name: 'agenda', icon: Calendar, label: t('nav.agenda'), path: '/agenda' },
  { name: 'workouts', icon: Dumbbell, label: t('nav.workouts'), path: '/workouts' },
  { name: 'evolution', icon: TrendingUp, label: t('nav.evolution'), path: '/evolution' },
  { name: 'finance', icon: Wallet, label: t('nav.finance'), path: '/finance' },
  { name: 'messages', icon: MessageSquare, label: t('nav.messages'), path: '/messages' },
]

function isActive(path: string) {
  if (path === '/') {
    return route.path === '/'
  }
  return route.path.startsWith(path)
}
</script>

<template>
  <aside
    :class="[
      'bg-coal border-r border-surface-3 transition-all duration-300',
      open ? 'w-64' : 'w-20'
    ]"
  >
    <div class="h-full flex flex-col">
      <!-- Logo -->
      <div class="h-16 flex items-center justify-between px-4 border-b border-surface-3">
        <div v-if="open" class="flex items-center space-x-3">
          <img src="@ga-personal/shared/src/assets/logo-monogram-32.png" alt="GA" width="32" height="32" class="rounded-md" />
          <span class="font-display text-lg font-semibold tracking-tight text-smoke">GA Personal</span>
        </div>
        <img v-else src="@ga-personal/shared/src/assets/logo-monogram-32.png" alt="GA" width="32" height="32" class="rounded-md mx-auto" />
      </div>

      <!-- Navigation -->
      <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        <RouterLink
          v-for="item in navItems"
          :key="item.name"
          :to="item.path"
          :class="[
            'flex items-center space-x-3 px-3 py-2.5 rounded-ga transition-colors duration-150',
            isActive(item.path)
              ? 'bg-lime/10 text-lime'
              : 'text-stone hover:bg-surface-2 hover:text-smoke'
          ]"
        >
          <component :is="item.icon" :size="20" :stroke-width="1.75" />
          <span v-if="open" class="font-medium text-sm">{{ item.label }}</span>
        </RouterLink>
      </nav>

      <!-- User section -->
      <div class="p-4 border-t border-surface-3">
        <RouterLink
          to="/settings"
          :class="[
            'flex items-center space-x-3 px-3 py-2.5 rounded-ga transition-colors duration-150',
            'text-stone hover:bg-surface-2 hover:text-smoke'
          ]"
        >
          <Settings :size="20" :stroke-width="1.75" />
          <span v-if="open" class="font-medium text-sm">{{ t('nav.settings') }}</span>
        </RouterLink>
      </div>
    </div>
  </aside>
</template>
