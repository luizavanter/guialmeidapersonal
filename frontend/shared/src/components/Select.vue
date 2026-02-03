<template>
  <div class="select-wrapper">
    <label v-if="label" :for="selectId" class="select-label">
      {{ label }}
      <span v-if="required" class="text-red-500 ml-1">*</span>
    </label>

    <div class="select-container">
      <select
        :id="selectId"
        ref="selectRef"
        :value="modelValue"
        :disabled="disabled"
        :required="required"
        :class="selectClasses"
        @change="handleChange"
        @blur="handleBlur"
        @focus="handleFocus"
      >
        <option v-if="placeholder" value="" disabled>{{ placeholder }}</option>
        <option
          v-for="option in options"
          :key="option.value"
          :value="option.value"
          :disabled="option.disabled"
        >
          {{ option.label }}
        </option>
      </select>

      <div class="select-icon">
        <svg
          class="w-4 h-4"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M19 9l-7 7-7-7"
          />
        </svg>
      </div>
    </div>

    <p v-if="error" class="select-error">{{ error }}</p>
    <p v-else-if="hint" class="select-hint">{{ hint }}</p>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'

export interface SelectOption {
  label: string
  value: any
  disabled?: boolean
}

export interface SelectProps {
  modelValue?: any
  options: SelectOption[]
  label?: string
  placeholder?: string
  error?: string
  hint?: string
  disabled?: boolean
  required?: boolean
}

const props = withDefaults(defineProps<SelectProps>(), {
  disabled: false,
  required: false,
})

const emit = defineEmits<{
  'update:modelValue': [value: any]
  blur: [event: FocusEvent]
  focus: [event: FocusEvent]
}>()

const selectRef = ref<HTMLSelectElement>()
const selectId = computed(() => `select-${Math.random().toString(36).substr(2, 9)}`)

const selectClasses = computed(() => {
  const classes = [
    'select-base',
    'w-full',
    'px-4',
    'py-3',
    'pr-10',
    'bg-coal-light',
    'border',
    'rounded-ga',
    'text-smoke',
    'transition-all',
    'duration-200',
    'focus-ring',
    'appearance-none',
    'cursor-pointer',
  ]

  if (props.error) {
    classes.push('border-red-500', 'focus:border-red-500')
  } else {
    classes.push('border-coal-lighter', 'focus:border-lime')
  }

  if (props.disabled) {
    classes.push('opacity-50', 'cursor-not-allowed')
  }

  return classes
})

const handleChange = (event: Event) => {
  const target = event.target as HTMLSelectElement
  const value = target.value
  emit('update:modelValue', value)
}

const handleBlur = (event: FocusEvent) => {
  emit('blur', event)
}

const handleFocus = (event: FocusEvent) => {
  emit('focus', event)
}

defineExpose({
  focus: () => selectRef.value?.focus(),
  blur: () => selectRef.value?.blur(),
})
</script>

<style scoped>
.select-wrapper {
  @apply flex flex-col gap-2;
}

.select-label {
  @apply text-sm font-medium text-smoke;
}

.select-container {
  @apply relative;
}

.select-icon {
  @apply absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-smoke-dark;
}

.select-error {
  @apply text-sm text-red-500;
}

.select-hint {
  @apply text-sm text-smoke-dark;
}
</style>
