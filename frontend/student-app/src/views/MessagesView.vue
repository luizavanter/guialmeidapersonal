<template>
  <div>
    <div class="mb-8 flex items-center justify-between">
      <h1 class="text-3xl font-display text-lime">{{ t('messages.title') }}</h1>
      <Button
        v-if="unreadCount > 0"
        variant="ghost"
        size="sm"
        @click="handleMarkAllRead"
      >
        {{ t('messages.markAllRead') }}
      </Button>
    </div>

    <div v-if="isLoading" class="text-center py-12">
      <p class="text-smoke/60">{{ t('common.loading') }}</p>
    </div>

    <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Messages List -->
      <div class="lg:col-span-2">
        <Card title="Conversas">
          <div v-if="sortedMessages.length > 0" class="space-y-3 max-h-[600px] overflow-y-auto">
            <div
              v-for="message in sortedMessages"
              :key="message.id"
              :class="[
                'p-4 rounded-lg border transition-colors',
                !message.readAt
                  ? 'bg-lime/5 border-lime/20'
                  : 'bg-coal/50 border-smoke/10',
              ]"
            >
              <div class="flex items-start gap-3">
                <div class="flex-shrink-0 w-10 h-10 bg-ocean/20 rounded-full flex items-center justify-center">
                  <svg class="w-5 h-5 text-ocean" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                </div>
                <div class="flex-1 min-w-0">
                  <div class="flex items-start justify-between mb-1">
                    <p class="text-sm font-semibold text-smoke">
                      {{ message.sender?.name || 'Trainer' }}
                    </p>
                    <div class="flex items-center gap-2">
                      <span class="text-xs text-smoke/60 whitespace-nowrap">
                        {{ formatRelativeTime(message.insertedAt) }}
                      </span>
                      <span
                        v-if="!message.readAt"
                        class="flex-shrink-0 w-2 h-2 bg-lime rounded-full"
                      ></span>
                    </div>
                  </div>
                  <p class="text-sm text-smoke/80 whitespace-pre-wrap break-words">{{ message.content }}</p>
                </div>
              </div>
            </div>
          </div>
          <div v-else class="text-center py-12 text-smoke/60">
            {{ t('messages.noMessages') }}
          </div>
        </Card>
      </div>

      <!-- Send Message Form -->
      <div>
        <Card :title="t('messages.sendMessage')">
          <form @submit.prevent="handleSendMessage">
            <div class="space-y-4">
              <div>
                <label class="block text-sm font-medium text-smoke mb-1">
                  Mensagem *
                </label>
                <textarea
                  v-model="messageForm.content"
                  rows="8"
                  class="block w-full rounded-lg bg-coal/50 border border-smoke/20 px-4 py-2 text-smoke placeholder-smoke/40 focus:outline-none focus:ring-2 focus:border-lime focus:ring-lime resize-none"
                  :placeholder="t('messages.typeMessage')"
                  required
                ></textarea>
              </div>

              <div v-if="messageErrors.general" class="p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
                <p class="text-sm text-red-500">{{ messageErrors.general }}</p>
              </div>

              <Button
                type="submit"
                variant="primary"
                full-width
                :loading="isSubmitting"
                :disabled="!messageForm.content.trim()"
              >
                {{ t('messages.sendMessage') }}
              </Button>
            </div>
          </form>
        </Card>

        <!-- Stats -->
        <Card title="Estatísticas" class="mt-6">
          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <span class="text-smoke/60 text-sm">Total de mensagens</span>
              <span class="text-2xl font-bold text-smoke font-mono">{{ sortedMessages.length }}</span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-smoke/60 text-sm">Não lidas</span>
              <span class="text-2xl font-bold text-lime font-mono">{{ unreadCount }}</span>
            </div>
          </div>
        </Card>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth'
import { useMessagesStore } from '@/stores/messages'
import { useToast } from '@/composables/useToast'
import { formatRelativeTime } from '@/utils/date'
import Card from '@/components/ui/Card.vue'
import Button from '@/components/ui/Button.vue'

const { t } = useI18n()
const authStore = useAuthStore()
const messagesStore = useMessagesStore()
const toast = useToast()

const isSubmitting = ref(false)

const messageForm = reactive({
  content: '',
})

const messageErrors = reactive({
  general: '',
})

const sortedMessages = computed(() => messagesStore.sortedMessages)
const unreadCount = computed(() => messagesStore.unreadCount)
const isLoading = computed(() => messagesStore.isLoading)

const handleSendMessage = async () => {
  messageErrors.general = ''

  if (!messageForm.content.trim()) {
    return
  }

  isSubmitting.value = true

  try {
    // Get trainer ID from user profile (assuming student has a trainerId)
    // For now, we'll send to a default receiver
    await messagesStore.sendMessage({
      receiverId: 'trainer-id', // This should come from student profile
      content: messageForm.content,
    })

    toast.success(t('messages.messageSent'))
    messageForm.content = ''
  } catch (error) {
    messageErrors.general = t('messages.messageError')
  } finally {
    isSubmitting.value = false
  }
}

const handleMarkAllRead = async () => {
  await messagesStore.markAllAsRead()
}

onMounted(async () => {
  await messagesStore.fetchMessages()

  // Mark messages as read when viewing
  const unread = sortedMessages.value.filter((m) => !m.readAt)
  unread.forEach((m) => {
    messagesStore.markAsRead(m.id)
  })
})
</script>
