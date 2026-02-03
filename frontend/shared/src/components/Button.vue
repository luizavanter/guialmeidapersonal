<template>
  <button
    :type="type"
    :class="buttonClasses"
    :disabled="disabled || loading"
    @click="handleClick"
  >
    <span v-if="loading" class="loading-spinner" />
    <slot v-else name="icon-left" />

    <span v-if="!loading || showTextWhileLoading" class="button-text">
      <slot />
    </span>

    <slot v-if="!loading" name="icon-right" />
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'

export interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger' | 'success'
  size?: 'sm' | 'md' | 'lg'
  type?: 'button' | 'submit' | 'reset'
  disabled?: boolean
  loading?: boolean
  showTextWhileLoading?: boolean
  block?: boolean
  rounded?: boolean
}

const props = withDefaults(defineProps<ButtonProps>(), {
  variant: 'primary',
  size: 'md',
  type: 'button',
  disabled: false,
  loading: false,
  showTextWhileLoading: false,
  block: false,
  rounded: false,
})

const emit = defineEmits<{
  click: [event: MouseEvent]
}>()

const buttonClasses = computed(() => {
  const classes = [
    'btn-base',
    'font-sans',
    'font-medium',
    'transition-all',
    'duration-200',
    'inline-flex',
    'items-center',
    'justify-center',
    'gap-2',
  ]

  // Variant styles
  switch (props.variant) {
    case 'primary':
      classes.push(
        'bg-lime',
        'text-coal',
        'hover:bg-lime-dark',
        'active:scale-95',
        'shadow-ga'
      )
      break
    case 'secondary':
      classes.push(
        'bg-ocean',
        'text-white',
        'hover:bg-ocean-dark',
        'active:scale-95'
      )
      break
    case 'ghost':
      classes.push(
        'bg-transparent',
        'text-smoke',
        'border',
        'border-coal-lighter',
        'hover:bg-coal-light',
        'hover:border-lime'
      )
      break
    case 'danger':
      classes.push(
        'bg-red-600',
        'text-white',
        'hover:bg-red-700',
        'active:scale-95'
      )
      break
    case 'success':
      classes.push(
        'bg-green-600',
        'text-white',
        'hover:bg-green-700',
        'active:scale-95'
      )
      break
  }

  // Size styles
  switch (props.size) {
    case 'sm':
      classes.push('px-4', 'py-2', 'text-sm')
      break
    case 'md':
      classes.push('px-6', 'py-3', 'text-base')
      break
    case 'lg':
      classes.push('px-8', 'py-4', 'text-lg')
      break
  }

  // Additional modifiers
  if (props.block) {
    classes.push('w-full')
  }

  if (props.rounded) {
    classes.push('rounded-full')
  } else {
    classes.push('rounded-ga')
  }

  if (props.disabled || props.loading) {
    classes.push('opacity-50', 'cursor-not-allowed')
  }

  return classes
})

const handleClick = (event: MouseEvent) => {
  if (!props.disabled && !props.loading) {
    emit('click', event)
  }
}
</script>

<style scoped>
.loading-spinner {
  @apply inline-block w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin;
}

.button-text {
  @apply inline-block;
}
</style>
