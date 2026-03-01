<template>
  <div
    :class="[
      'relative border-2 border-dashed rounded-xl p-6 text-center transition-all cursor-pointer',
      isDragging
        ? 'border-lime bg-lime/5'
        : 'border-surface-3 hover:border-lime/40 bg-[#1a1a1a]',
      disabled ? 'opacity-50 cursor-not-allowed' : '',
    ]"
    @dragenter.prevent="onDragEnter"
    @dragover.prevent="onDragOver"
    @dragleave.prevent="onDragLeave"
    @drop.prevent="onDrop"
    @click="openFilePicker"
  >
    <input
      ref="fileInput"
      type="file"
      :accept="accept"
      class="hidden"
      @change="onFileChange"
    />

    <!-- Upload state -->
    <div v-if="!selectedFile && !uploading">
      <div class="w-12 h-12 mx-auto mb-3 bg-surface-3 rounded-full flex items-center justify-center">
        <svg class="w-6 h-6 text-stone" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
        </svg>
      </div>
      <p class="text-smoke font-medium mb-1">{{ label || t('media.dragDrop') }}</p>
      <p class="text-stone text-sm">{{ t('media.browse') }}</p>
      <p v-if="maxSizeMb" class="text-stone/60 text-xs mt-2">{{ t('media.maxSize', { size: maxSizeMb }) }}</p>
    </div>

    <!-- Selected file preview -->
    <div v-else-if="selectedFile && !uploading" class="space-y-3">
      <div v-if="previewUrl" class="mx-auto w-24 h-24 rounded-lg overflow-hidden border border-surface-3">
        <img :src="previewUrl" alt="Preview" class="w-full h-full object-cover" />
      </div>
      <div v-else class="w-12 h-12 mx-auto bg-ocean/10 rounded-full flex items-center justify-center">
        <svg class="w-6 h-6 text-ocean" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
      </div>
      <p class="text-smoke text-sm font-medium truncate">{{ selectedFile.name }}</p>
      <p class="text-stone text-xs">{{ formatFileSize(selectedFile.size) }}</p>
      <div class="flex justify-center gap-2">
        <button
          type="button"
          class="px-3 py-1.5 text-xs rounded-lg bg-surface-3 text-stone hover:text-smoke transition-colors"
          @click.stop="clearFile"
        >
          {{ t('common.cancel') }}
        </button>
        <button
          type="button"
          class="px-3 py-1.5 text-xs rounded-lg bg-lime text-coal font-medium hover:bg-lime-dark transition-colors"
          @click.stop="$emit('upload-start')"
        >
          {{ t('media.upload') }}
        </button>
      </div>
    </div>

    <!-- Uploading state -->
    <div v-else-if="uploading" class="space-y-3">
      <div class="w-12 h-12 mx-auto flex items-center justify-center">
        <div class="w-8 h-8 border-2 border-lime border-t-transparent rounded-full animate-spin"></div>
      </div>
      <p class="text-smoke text-sm">{{ t('media.uploading') }}</p>
      <div v-if="progress > 0" class="w-full bg-surface-3 rounded-full h-2 overflow-hidden max-w-xs mx-auto">
        <div class="h-full bg-lime transition-all" :style="{ width: `${progress}%` }"></div>
      </div>
    </div>

    <!-- Error -->
    <p v-if="errorMessage" class="text-red-400 text-xs mt-2">{{ errorMessage }}</p>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useI18n } from 'vue-i18n'

export interface FileUploadProps {
  accept?: string
  maxSizeMb?: number
  label?: string
  uploading?: boolean
  progress?: number
  disabled?: boolean
}

const props = withDefaults(defineProps<FileUploadProps>(), {
  accept: 'image/jpeg,image/png,image/webp,application/pdf',
  maxSizeMb: 10,
  label: '',
  uploading: false,
  progress: 0,
  disabled: false,
})

const emit = defineEmits<{
  'file-selected': [file: File]
  'upload-start': []
}>()

const { t } = useI18n()
const fileInput = ref<HTMLInputElement>()
const selectedFile = ref<File | null>(null)
const isDragging = ref(false)
const errorMessage = ref('')

const previewUrl = computed(() => {
  if (!selectedFile.value) return null
  if (selectedFile.value.type.startsWith('image/')) {
    return URL.createObjectURL(selectedFile.value)
  }
  return null
})

function openFilePicker() {
  if (props.disabled || props.uploading) return
  fileInput.value?.click()
}

function onFileChange(event: Event) {
  const input = event.target as HTMLInputElement
  if (input.files?.[0]) {
    validateAndSet(input.files[0])
  }
}

function onDragEnter() {
  if (!props.disabled) isDragging.value = true
}

function onDragOver() {
  if (!props.disabled) isDragging.value = true
}

function onDragLeave() {
  isDragging.value = false
}

function onDrop(event: DragEvent) {
  isDragging.value = false
  if (props.disabled) return
  const file = event.dataTransfer?.files?.[0]
  if (file) validateAndSet(file)
}

function validateAndSet(file: File) {
  errorMessage.value = ''

  // Validate type
  const allowedTypes = props.accept.split(',').map((t) => t.trim())
  if (!allowedTypes.some((type) => file.type === type || type === '*/*')) {
    errorMessage.value = t('media.invalidType')
    return
  }

  // Validate size
  if (props.maxSizeMb && file.size > props.maxSizeMb * 1024 * 1024) {
    errorMessage.value = t('media.maxSize', { size: props.maxSizeMb })
    return
  }

  selectedFile.value = file
  emit('file-selected', file)
}

function clearFile() {
  selectedFile.value = null
  errorMessage.value = ''
  if (fileInput.value) fileInput.value.value = ''
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

defineExpose({ clearFile })
</script>
