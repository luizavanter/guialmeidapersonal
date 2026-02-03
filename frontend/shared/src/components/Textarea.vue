<template>
  <div class="textarea-wrapper">
    <label v-if="label" :for="textareaId" class="textarea-label">
      {{ label }}
      <span v-if="required" class="text-red-500 ml-1">*</span>
    </label>

    <textarea
      :id="textareaId"
      ref="textareaRef"
      :value="modelValue"
      :placeholder="placeholder"
      :disabled="disabled"
      :readonly="readonly"
      :required="required"
      :rows="rows"
      :class="textareaClasses"
      @input="handleInput"
      @blur="handleBlur"
      @focus="handleFocus"
    />

    <p v-if="error" class="textarea-error">{{ error }}</p>
    <p v-else-if="hint" class="textarea-hint">{{ hint }}</p>
    <p v-if="maxLength" class="textarea-counter">
      {{ modelValue?.length || 0 }} / {{ maxLength }}
    </p>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'

export interface TextareaProps {
  modelValue?: string
  label?: string
  placeholder?: string
  error?: string
  hint?: string
  disabled?: boolean
  readonly?: boolean
  required?: boolean
  rows?: number
  maxLength?: number
}

const props = withDefaults(defineProps<TextareaProps>(), {
  disabled: false,
  readonly: false,
  required: false,
  rows: 4,
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
  blur: [event: FocusEvent]
  focus: [event: FocusEvent]
}>()

const textareaRef = ref<HTMLTextAreaElement>()
const textareaId = computed(() => `textarea-${Math.random().toString(36).substr(2, 9)}`)

const textareaClasses = computed(() => {
  const classes = [
    'textarea-base',
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
    'resize-y',
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
  const target = event.target as HTMLTextAreaElement
  let value = target.value

  if (props.maxLength && value.length > props.maxLength) {
    value = value.substring(0, props.maxLength)
    target.value = value
  }

  emit('update:modelValue', value)
}

const handleBlur = (event: FocusEvent) => {
  emit('blur', event)
}

const handleFocus = (event: FocusEvent) => {
  emit('focus', event)
}

defineExpose({
  focus: () => textareaRef.value?.focus(),
  blur: () => textareaRef.value?.blur(),
})
</script>

<style scoped>
.textarea-wrapper {
  @apply flex flex-col gap-2;
}

.textarea-label {
  @apply text-sm font-medium text-smoke;
}

.textarea-error {
  @apply text-sm text-red-500;
}

.textarea-hint {
  @apply text-sm text-smoke-dark;
}

.textarea-counter {
  @apply text-xs text-smoke-dark text-right;
}
</style>
