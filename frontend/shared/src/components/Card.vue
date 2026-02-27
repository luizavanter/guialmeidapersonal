<template>
  <div :class="cardClasses">
    <div v-if="$slots.header || title" class="card-header">
      <slot name="header">
        <h3 v-if="title" class="card-title">{{ title }}</h3>
      </slot>
    </div>

    <div class="card-body">
      <slot />
    </div>

    <div v-if="$slots.footer" class="card-footer">
      <slot name="footer" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

export interface CardProps {
  title?: string
  padding?: 'none' | 'sm' | 'md' | 'lg'
  hover?: boolean
  clickable?: boolean
}

const props = withDefaults(defineProps<CardProps>(), {
  padding: 'md',
  hover: false,
  clickable: false,
})

const cardClasses = computed(() => {
  const classes = [
    'card',
    'bg-surface-1',
    'border',
    'border-surface-3',
    'rounded-ga-lg',
    'transition-all',
    'duration-200',
  ]

  if (props.hover) {
    classes.push('hover:border-lime', 'hover:shadow-ga')
  }

  if (props.clickable) {
    classes.push('cursor-pointer', 'active:scale-[0.99]')
  }

  return classes
})
</script>

<style scoped>
.card {
  @apply overflow-hidden;
}

.card-header {
  @apply px-6 py-4 border-b border-surface-3;
}

.card-title {
  @apply text-lg font-display text-smoke;
}

.card-body {
  @apply p-6;
}

.card-footer {
  @apply px-6 py-4 border-t border-surface-3;
}

.card[data-padding="none"] .card-body {
  @apply p-0;
}

.card[data-padding="sm"] .card-body {
  @apply p-4;
}

.card[data-padding="lg"] .card-body {
  @apply p-8;
}
</style>
