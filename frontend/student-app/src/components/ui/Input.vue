<template>
  <div class="w-full">
    <label v-if="label" :for="id" class="block text-sm font-medium text-smoke mb-1">
      {{ label }}
      <span v-if="required" class="text-red-500">*</span>
    </label>
    <input
      :id="id"
      :type="type"
      :value="modelValue"
      :placeholder="placeholder"
      :disabled="disabled"
      :required="required"
      :class="inputClasses"
      @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)"
      @blur="$emit('blur')"
    />
    <p v-if="error" class="mt-1 text-sm text-red-500">{{ error }}</p>
    <p v-else-if="hint" class="mt-1 text-sm text-stone">{{ hint }}</p>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  id?: string
  label?: string
  type?: string
  modelValue?: string | number
  placeholder?: string
  disabled?: boolean
  required?: boolean
  error?: string
  hint?: string
}

const props = withDefaults(defineProps<Props>(), {
  type: 'text',
  disabled: false,
  required: false,
})

defineEmits<{
  'update:modelValue': [value: string]
  blur: []
}>()

const inputClasses = computed(() => {
  const base = 'block w-full rounded-lg bg-surface-1 border px-4 py-2 text-smoke placeholder-stone focus:outline-none focus:ring-2 focus:ring-offset-0 disabled:opacity-50 disabled:cursor-not-allowed transition-colors'

  if (props.error) {
    return `${base} border-red-500 focus:border-red-500 focus:ring-red-500`
  }

  return `${base} border-surface-3 focus:border-lime focus:ring-lime`
})
</script>
