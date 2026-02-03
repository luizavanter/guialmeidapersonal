<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'

const props = defineProps<{
  open: boolean
}>()

const emit = defineEmits<{
  toggle: []
}>()

const { t } = useI18n()
const route = useRoute()

const navItems = [
  { name: 'dashboard', icon: '📊', label: t('nav.dashboard'), path: '/' },
  { name: 'students', icon: '👥', label: t('nav.students'), path: '/students' },
  { name: 'agenda', icon: '📅', label: t('nav.agenda'), path: '/agenda' },
  { name: 'workouts', icon: '💪', label: t('nav.workouts'), path: '/workouts' },
  { name: 'evolution', icon: '📈', label: t('nav.evolution'), path: '/evolution' },
  { name: 'finance', icon: '💰', label: t('nav.finance'), path: '/finance' },
  { name: 'messages', icon: '💬', label: t('nav.messages'), path: '/messages' },
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
      'bg-coal border-r border-smoke/10 transition-all duration-300',
      open ? 'w-64' : 'w-20'
    ]"
  >
    <div class="h-full flex flex-col">
      <!-- Logo -->
      <div class="h-16 flex items-center justify-between px-4 border-b border-smoke/10">
        <div v-if="open" class="flex items-center space-x-2">
          <div class="w-8 h-8 bg-lime rounded-lg"></div>
          <span class="font-display text-xl text-lime">GA PERSONAL</span>
        </div>
        <div v-else class="w-8 h-8 bg-lime rounded-lg mx-auto"></div>
      </div>

      <!-- Navigation -->
      <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        <RouterLink
          v-for="item in navItems"
          :key="item.name"
          :to="item.path"
          :class="[
            'flex items-center space-x-3 px-3 py-2.5 rounded-lg transition-colors',
            isActive(item.path)
              ? 'bg-lime/20 text-lime'
              : 'text-smoke/70 hover:bg-smoke/5 hover:text-smoke'
          ]"
        >
          <span class="text-xl">{{ item.icon }}</span>
          <span v-if="open" class="font-medium">{{ item.label }}</span>
        </RouterLink>
      </nav>

      <!-- User section -->
      <div class="p-4 border-t border-smoke/10">
        <RouterLink
          to="/settings"
          :class="[
            'flex items-center space-x-3 px-3 py-2.5 rounded-lg transition-colors',
            'text-smoke/70 hover:bg-smoke/5 hover:text-smoke'
          ]"
        >
          <span class="text-xl">⚙️</span>
          <span v-if="open" class="font-medium">{{ t('nav.settings') }}</span>
        </RouterLink>
      </div>
    </div>
  </aside>
</template>
