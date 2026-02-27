<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="modelValue" class="modal-overlay" @click="handleOverlayClick">
        <div :class="modalClasses" @click.stop>
          <div class="modal-header">
            <slot name="header">
              <h2 class="modal-title">{{ title }}</h2>
            </slot>
            <button
              v-if="showClose"
              class="modal-close"
              type="button"
              @click="handleClose"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <div class="modal-body">
            <slot />
          </div>

          <div v-if="$slots.footer" class="modal-footer">
            <slot name="footer" />
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { computed, watch } from 'vue'

export interface ModalProps {
  modelValue: boolean
  title?: string
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'full'
  showClose?: boolean
  closeOnOverlay?: boolean
}

const props = withDefaults(defineProps<ModalProps>(), {
  size: 'md',
  showClose: true,
  closeOnOverlay: true,
})

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  close: []
}>()

const modalClasses = computed(() => {
  const classes = [
    'modal-content',
    'bg-surface-1',
    'rounded-ga',
    'shadow-coal',
    'relative',
    'animate-scale-in',
  ]

  switch (props.size) {
    case 'sm':
      classes.push('max-w-md')
      break
    case 'md':
      classes.push('max-w-lg')
      break
    case 'lg':
      classes.push('max-w-2xl')
      break
    case 'xl':
      classes.push('max-w-4xl')
      break
    case 'full':
      classes.push('max-w-full', 'h-full', 'm-4')
      break
  }

  return classes
})

const handleClose = () => {
  emit('update:modelValue', false)
  emit('close')
}

const handleOverlayClick = () => {
  if (props.closeOnOverlay) {
    handleClose()
  }
}

// Prevent body scroll when modal is open
watch(() => props.modelValue, (isOpen) => {
  if (isOpen) {
    document.body.style.overflow = 'hidden'
  } else {
    document.body.style.overflow = ''
  }
})
</script>

<style scoped>
.modal-overlay {
  @apply fixed inset-0 z-50 flex items-center justify-center bg-coal/80 backdrop-blur-sm p-4;
}

.modal-content {
  @apply w-full max-h-[90vh] flex flex-col;
}

.modal-header {
  @apply flex items-center justify-between px-6 py-4 border-b border-surface-3;
}

.modal-title {
  @apply text-xl font-display text-smoke;
}

.modal-close {
  @apply text-stone hover:text-smoke transition-colors p-1 rounded-lg hover:bg-surface-2;
}

.modal-body {
  @apply flex-1 overflow-y-auto px-6 py-4;
}

.modal-footer {
  @apply px-6 py-4 border-t border-surface-3 flex items-center justify-end gap-3;
}

/* Transitions */
.modal-enter-active,
.modal-leave-active {
  @apply transition-opacity duration-300;
}

.modal-enter-from,
.modal-leave-to {
  @apply opacity-0;
}

.modal-enter-active .modal-content,
.modal-leave-active .modal-content {
  @apply transition-transform duration-300;
}

.modal-enter-from .modal-content,
.modal-leave-to .modal-content {
  @apply scale-95;
}
</style>
