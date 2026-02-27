<template>
  <div :class="avatarClasses">
    <img
      v-if="src && !imageError"
      :src="src"
      :alt="alt"
      class="avatar-image"
      @error="handleImageError"
    />
    <div v-else class="avatar-fallback">
      <slot>
        <span class="avatar-initials">{{ initials }}</span>
      </slot>
    </div>
    <div v-if="status" :class="statusClasses" />
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { initials as getInitials } from '@/utils/format'

export interface AvatarProps {
  src?: string
  alt?: string
  name?: string
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl' | '2xl'
  rounded?: 'square' | 'rounded' | 'full'
  status?: 'online' | 'offline' | 'busy' | 'away'
}

const props = withDefaults(defineProps<AvatarProps>(), {
  size: 'md',
  rounded: 'full',
})

const imageError = ref(false)

const avatarClasses = computed(() => {
  const classes = ['avatar', 'relative', 'inline-flex', 'items-center', 'justify-center', 'bg-surface-3', 'text-smoke', 'font-medium', 'overflow-hidden']

  // Size
  switch (props.size) {
    case 'xs':
      classes.push('w-6', 'h-6', 'text-xs')
      break
    case 'sm':
      classes.push('w-8', 'h-8', 'text-sm')
      break
    case 'md':
      classes.push('w-10', 'h-10', 'text-base')
      break
    case 'lg':
      classes.push('w-12', 'h-12', 'text-lg')
      break
    case 'xl':
      classes.push('w-16', 'h-16', 'text-xl')
      break
    case '2xl':
      classes.push('w-20', 'h-20', 'text-2xl')
      break
  }

  // Rounded
  switch (props.rounded) {
    case 'square':
      classes.push('rounded-none')
      break
    case 'rounded':
      classes.push('rounded-ga')
      break
    case 'full':
      classes.push('rounded-full')
      break
  }

  return classes
})

const statusClasses = computed(() => {
  const classes = ['avatar-status', 'absolute', 'bottom-0', 'right-0', 'rounded-full', 'border-2', 'border-coal']

  // Size based on avatar size
  switch (props.size) {
    case 'xs':
      classes.push('w-1.5', 'h-1.5')
      break
    case 'sm':
      classes.push('w-2', 'h-2')
      break
    case 'md':
      classes.push('w-2.5', 'h-2.5')
      break
    case 'lg':
    case 'xl':
    case '2xl':
      classes.push('w-3', 'h-3')
      break
  }

  // Status color
  switch (props.status) {
    case 'online':
      classes.push('bg-green-500')
      break
    case 'offline':
      classes.push('bg-gray-500')
      break
    case 'busy':
      classes.push('bg-red-500')
      break
    case 'away':
      classes.push('bg-yellow-500')
      break
  }

  return classes
})

const initials = computed(() => {
  if (props.name) {
    return getInitials(props.name)
  }
  return props.alt?.[0]?.toUpperCase() || '?'
})

const handleImageError = () => {
  imageError.value = true
}
</script>

<style scoped>
.avatar-image {
  @apply w-full h-full object-cover;
}

.avatar-fallback {
  @apply w-full h-full flex items-center justify-center;
}

.avatar-initials {
  @apply font-display;
}
</style>
