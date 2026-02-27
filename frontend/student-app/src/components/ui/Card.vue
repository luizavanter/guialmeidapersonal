<template>
  <div :class="cardClasses">
    <div v-if="$slots.header || title" class="px-6 py-4 border-b border-surface-3">
      <slot name="header">
        <h3 class="text-lg font-semibold text-smoke">{{ title }}</h3>
      </slot>
    </div>
    <div :class="bodyClasses">
      <slot />
    </div>
    <div v-if="$slots.footer" class="px-6 py-4 border-t border-surface-3">
      <slot name="footer" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  title?: string
  padding?: boolean
  hover?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  padding: true,
  hover: false,
})

const cardClasses = computed(() => {
  const base = 'bg-surface-1 border border-surface-3 rounded-ga-lg'
  const hoverClass = props.hover ? 'hover:border-lime/30 transition-colors' : ''
  return `${base} ${hoverClass}`
})

const bodyClasses = computed(() => {
  return props.padding ? 'p-6' : ''
})
</script>
