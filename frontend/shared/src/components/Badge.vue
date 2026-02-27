<template>
  <span :class="badgeClasses">
    <slot />
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'

export interface BadgeProps {
  variant?: 'default' | 'primary' | 'success' | 'warning' | 'danger' | 'info'
  size?: 'sm' | 'md' | 'lg'
  rounded?: boolean
  outline?: boolean
}

const props = withDefaults(defineProps<BadgeProps>(), {
  variant: 'default',
  size: 'md',
  rounded: false,
  outline: false,
})

const badgeClasses = computed(() => {
  const classes = [
    'inline-flex',
    'items-center',
    'justify-center',
    'font-medium',
    'transition-colors',
  ]

  // Size
  switch (props.size) {
    case 'sm':
      classes.push('px-2', 'py-0.5', 'text-xs')
      break
    case 'md':
      classes.push('px-2.5', 'py-1', 'text-sm')
      break
    case 'lg':
      classes.push('px-3', 'py-1.5', 'text-base')
      break
  }

  // Rounded
  if (props.rounded) {
    classes.push('rounded-full')
  } else {
    classes.push('rounded-md')
  }

  // Variant
  if (props.outline) {
    classes.push('border', 'bg-transparent')
    switch (props.variant) {
      case 'default':
        classes.push('border-smoke-dark', 'text-smoke-dark')
        break
      case 'primary':
        classes.push('border-lime', 'text-lime')
        break
      case 'success':
        classes.push('border-green-500', 'text-green-500')
        break
      case 'warning':
        classes.push('border-yellow-500', 'text-yellow-500')
        break
      case 'danger':
        classes.push('border-red-500', 'text-red-500')
        break
      case 'info':
        classes.push('border-ocean', 'text-ocean')
        break
    }
  } else {
    switch (props.variant) {
      case 'default':
        classes.push('bg-surface-3', 'text-stone')
        break
      case 'primary':
        classes.push('bg-lime', 'text-coal')
        break
      case 'success':
        classes.push('bg-green-500/10', 'text-green-400')
        break
      case 'warning':
        classes.push('bg-yellow-500/10', 'text-yellow-400')
        break
      case 'danger':
        classes.push('bg-red-500/10', 'text-red-400')
        break
      case 'info':
        classes.push('bg-ocean', 'text-white')
        break
    }
  }

  return classes
})
</script>
