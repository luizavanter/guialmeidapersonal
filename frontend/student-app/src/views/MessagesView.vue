<template>
  <div>
    <div class="mb-8 flex items-center justify-between">
      <h1 class="text-display-md text-smoke">{{ t('messages.title') }}</h1>
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
      <p class="text-stone">{{ t('common.loading') }}</p>
    </div>

    <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Messages List -->
      <div class="lg:col-span-2">
        <Card :title="t('messages.conversations')">
          <div v-if="sortedMessages.length > 0" class="space-y-3 max-h-[600px] overflow-y-auto">
            <div
              v-for="message in sortedMessages"
              :key="message.id"
              :class="[
                'p-4 rounded-lg border transition-colors',
                !message.readAt
                  ? 'bg-lime/5 border-lime/20'
                  : 'bg-surface-2 border-surface-3',
              ]"
            >
              <div class="flex items-start gap-3">
                <div class="flex-shrink-0 w-10 h-10 bg-ocean/10 rounded-full flex items-center justify-center">
                  <UserIcon class="w-5 h-5 text-ocean" />
                </div>
                <div class="flex-1 min-w-0">
                  <div class="flex items-start justify-between mb-1">
                    <p class="text-sm font-semibold text-smoke">
                      {{ message.sender?.name || t('messages.trainer') }}
                    </p>
                    <div class="flex items-center gap-2">
                      <span class="text-xs text-stone whitespace-nowrap">
                        {{ formatRelativeTime(message.insertedAt) }}
                      </span>
                      <span
                        v-if="!message.readAt"
                        class="flex-shrink-0 w-2 h-2 bg-lime rounded-full"
                      ></span>
                    </div>
                  </div>
                  <p class="text-sm text-smoke/90 whitespace-pre-wrap break-words">{{ message.content }}</p>
                </div>
              </div>
            </div>
          </div>
          <div v-else class="text-center py-12 text-stone">
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
                  {{ t('messages.messageLabel') }} *
                </label>
                <textarea
                  v-model="messageForm.content"
                  rows="8"
                  class="block w-full rounded-lg bg-surface-2 border border-surface-3 px-4 py-2 text-smoke placeholder-stone focus:outline-none focus:ring-2 focus:border-lime focus:ring-lime resize-none"
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
        <Card :title="t('messages.stats')" class="mt-6">
          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <span class="text-stone text-sm">{{ t('messages.totalMessages') }}</span>
              <span class="text-2xl font-bold text-smoke font-mono">{{ sortedMessages.length }}</span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-stone text-sm">{{ t('messages.unread') }}</span>
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
import { useProfileStore } from '@/stores/profile'
import { useToast } from '@/composables/useToast'
import { formatRelativeTime } from '@/utils/date'
import Card from '@/components/ui/Card.vue'
import Button from '@/components/ui/Button.vue'
import { User as UserIcon } from 'lucide-vue-next'

const { t } = useI18n()
const authStore = useAuthStore()
const messagesStore = useMessagesStore()
const profileStore = useProfileStore()
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
    const trainerId = profileStore.profile?.trainerId
    if (!trainerId) {
      messageErrors.general = t('messages.noTrainerAssigned')
      return
    }

    await messagesStore.sendMessage({
      receiverId: trainerId,
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
  // Ensure profile is loaded to get trainerId
  if (!profileStore.profile) {
    await profileStore.fetchProfile()
  }

  await messagesStore.fetchMessages()

  // Mark messages as read when viewing
  const unread = sortedMessages.value.filter((m) => !m.readAt)
  unread.forEach((m) => {
    messagesStore.markAsRead(m.id)
  })
})
</script>
