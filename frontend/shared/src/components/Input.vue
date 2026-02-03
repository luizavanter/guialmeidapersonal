<template>
  <div class="input-wrapper">
    <label v-if="label" :for="inputId" class="input-label">
      {{ label }}
      <span v-if="required" class="text-red-500 ml-1">*</span>
    </label>

    <div class="input-container">
      <div v-if="$slots['icon-left']" class="input-icon-left">
        <slot name="icon-left" />
      </div>

      <input
        :id="inputId"
        ref="inputRef"
        :type="type"
        :value="modelValue"
        :placeholder="placeholder"
        :disabled="disabled"
        :readonly="readonly"
        :required="required"
        :autocomplete="autocomplete"
        :class="inputClasses"
        @input="handleInput"
        @blur="handleBlur"
        @focus="handleFocus"
        @keydown.enter="handleEnter"
      />

      <div v-if="$slots['icon-right']" class="input-icon-right">
        <slot name="icon-right" />
      </div>
    </div>

    <p v-if="error" class="input-error">{{ error }}</p>
    <p v-else-if="hint" class="input-hint">{{ hint }}</p>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'

export interface InputProps {
  modelValue?: string | number
  type?: 'text' | 'email' | 'password' | 'number' | 'tel' | 'url' | 'search' | 'date' | 'time' | 'datetime-local'
  label?: string
  placeholder?: string
  error?: string
  hint?: string
  disabled?: boolean
  readonly?: boolean
  required?: boolean
  autocomplete?: string
}

const props = withDefaults(defineProps<InputProps>(), {
  type: 'text',
  disabled: false,
  readonly: false,
  required: false,
})

const emit = defineEmits<{
  'update:modelValue': [value: string | number]
  blur: [event: FocusEvent]
  focus: [event: FocusEvent]
  enter: [event: KeyboardEvent]
}>()

const inputRef = ref<HTMLInputElement>()
const inputId = computed(() => `input-${Math.random().toString(36).substr(2, 9)}`)

const inputClasses = computed(() => {
  const classes = [
    'input-base',
    'w-full',
    'px-4',
    'py-3',
    'bg-coal-light',
    'border',
    'rounded-ga',
    'text-smoke',
    'placeholder-smoke-dark/50',
    'transition-all',
    'duration-200',
    'focus-ring',
  ]

  if (props.error) {
    classes.push('border-red-500', 'focus:border-red-500')
  } else {
    classes.push('border-coal-lighter', 'focus:border-lime')
  }

  if (props.disabled) {
    classes.push('opacity-50', 'cursor-not-allowed')
  }

  if (props.readonly) {
    classes.push('cursor-default')
  }

  return classes
})

const handleInput = (event: Event) => {
  const target = event.target as HTMLInputElement
  const value = props.type === 'number' ? Number(target.value) : target.value
  emit('update:modelValue', value)
}

const handleBlur = (event: FocusEvent) => {
  emit('blur', event)
}

const handleFocus = (event: FocusEvent) => {
  emit('focus', event)
}

const handleEnter = (event: KeyboardEvent) => {
  emit('enter', event)
}

defineExpose({
  focus: () => inputRef.value?.focus(),
  blur: () => inputRef.value?.blur(),
})
</script>

<style scoped>
.input-wrapper {
  @apply flex flex-col gap-2;
}

.input-label {
  @apply text-sm font-medium text-smoke;
}

.input-container {
  @apply relative flex items-center;
}

.input-icon-left {
  @apply absolute left-3 text-smoke-dark pointer-events-none;
}

.input-icon-right {
  @apply absolute right-3 text-smoke-dark;
}

.input-container:has(.input-icon-left) .input-base {
  @apply pl-10;
}

.input-container:has(.input-icon-right) .input-base {
  @apply pr-10;
}

.input-error {
  @apply text-sm text-red-500;
}

.input-hint {
  @apply text-sm text-smoke-dark;
}
</style>
