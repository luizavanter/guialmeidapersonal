<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useI18n } from 'vue-i18n'
import { useStudentsStore } from '@/stores/studentsStore'

const { t } = useI18n()
const studentsStore = useStudentsStore()

const showComposeModal = ref(false)
const isSubmitting = ref(false)
const submitError = ref('')

const newMessage = reactive({
  recipientId: '',
  subject: '',
  body: ''
})

// Mock messages for now
const messages = ref([
  { id: 1, from: 'João Silva', subject: 'Dúvida sobre treino', preview: 'Olá, tenho uma dúvida...', date: new Date(), unread: true },
  { id: 2, from: 'Maria Santos', subject: 'Obrigada!', preview: 'Muito obrigada pelo treino...', date: new Date(), unread: false }
])

const selectedMessage = ref<any>(null)

function selectMessage(message: any) {
  selectedMessage.value = message
  message.unread = false
}

function closeModal() {
  showComposeModal.value = false
  submitError.value = ''
  newMessage.recipientId = ''
  newMessage.subject = ''
  newMessage.body = ''
}

async function handleSendMessage() {
  if (!newMessage.recipientId || !newMessage.subject || !newMessage.body) {
    submitError.value = t('common.requiredFields')
    return
  }

  isSubmitting.value = true
  submitError.value = ''

  try {
    // TODO: Implement actual message sending when backend is ready
    console.log('Sending message:', newMessage)
    closeModal()
  } catch (err: any) {
    submitError.value = err.message || t('common.error')
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="text-display-md text-smoke">{{ t('messages.title') }}</h1>
      <button @click="showComposeModal = true" class="btn btn-primary">{{ t('messages.compose') }}</button>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Inbox list -->
      <div class="lg:col-span-1 card">
        <h2 class="font-display text-xl mb-4">{{ t('messages.inbox') }}</h2>
        <div class="space-y-2">
          <div
            v-for="message in messages"
            :key="message.id"
            @click="selectMessage(message)"
            :class="[
              'p-3 rounded-lg cursor-pointer transition-colors',
              selectedMessage?.id === message.id ? 'bg-lime/20 border border-lime/50' : 'bg-surface-2 hover:bg-surface-3',
              message.unread ? 'border-l-4 border-l-lime' : ''
            ]"
          >
            <div class="flex items-center justify-between">
              <p :class="['font-medium', message.unread ? 'text-lime' : '']">{{ message.from }}</p>
              <span class="text-xs text-stone">{{ new Date(message.date).toLocaleDateString() }}</span>
            </div>
            <p class="text-sm font-medium">{{ message.subject }}</p>
            <p class="text-sm text-stone truncate">{{ message.preview }}</p>
          </div>
        </div>

        <div v-if="messages.length === 0" class="text-center py-8 text-stone">
          {{ t('messages.noMessages') }}
        </div>
      </div>

      <!-- Message detail -->
      <div class="lg:col-span-2 card">
        <div v-if="selectedMessage">
          <div class="border-b border-surface-3 pb-4 mb-4">
            <h3 class="font-display text-2xl">{{ selectedMessage.subject }}</h3>
            <div class="flex items-center justify-between mt-2">
              <p class="text-stone">{{ t('messages.from') }}: <span class="text-smoke">{{ selectedMessage.from }}</span></p>
              <p class="text-stone text-sm">{{ new Date(selectedMessage.date).toLocaleString() }}</p>
            </div>
          </div>
          <div class="prose prose-invert max-w-none">
            <p>{{ selectedMessage.preview }}</p>
            <p class="mt-4 text-stone">Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
          </div>
          <div class="mt-6 pt-4 border-t border-surface-3">
            <button class="btn btn-primary">{{ t('messages.reply') }}</button>
          </div>
        </div>
        <div v-else class="text-center py-12 text-stone">
          {{ t('messages.selectMessage') }}
        </div>
      </div>
    </div>

    <!-- Compose Modal -->
    <div v-if="showComposeModal" class="fixed inset-0 z-50 flex items-center justify-center">
      <div class="absolute inset-0 bg-black/70" @click="closeModal"></div>
      <div class="relative bg-surface-1 border border-surface-3 rounded-xl p-6 w-full max-w-lg mx-4 max-h-[90vh] overflow-y-auto">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-2xl text-lime">{{ t('messages.compose') }}</h2>
          <button @click="closeModal" class="text-stone hover:text-smoke text-2xl">&times;</button>
        </div>

        <form @submit.prevent="handleSendMessage" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2">{{ t('messages.to') }} *</label>
            <select v-model="newMessage.recipientId" class="input w-full" required>
              <option value="">{{ t('common.select') }}</option>
              <option v-for="student in studentsStore.students" :key="student.id" :value="student.id">
                {{ student.user?.firstName }} {{ student.user?.lastName }}
              </option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('messages.subject') }} *</label>
            <input v-model="newMessage.subject" type="text" class="input w-full" required />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">{{ t('messages.message') }} *</label>
            <textarea v-model="newMessage.body" class="input w-full" rows="6" required></textarea>
          </div>

          <div v-if="submitError" class="p-3 bg-red-500/20 text-red-400 rounded-lg text-sm">
            {{ submitError }}
          </div>

          <div class="flex justify-end space-x-3 pt-4">
            <button type="button" @click="closeModal" class="btn btn-secondary">
              {{ t('common.cancel') }}
            </button>
            <button type="submit" :disabled="isSubmitting" class="btn btn-primary">
              {{ isSubmitting ? t('common.loading') : t('messages.send') }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>
