import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api } from '@/lib/api'
import { API_ENDPOINTS } from '@/constants/api'
import type { Message, MessageInput } from '@/types'

export const useMessagesStore = defineStore('messages', () => {
  const messages = ref<Message[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  const unreadCount = computed(() => {
    return messages.value.filter((m) => !m.readAt).length
  })

  const sortedMessages = computed(() => {
    return [...messages.value].sort(
      (a, b) => new Date(b.insertedAt).getTime() - new Date(a.insertedAt).getTime()
    )
  })

  const fetchMessages = async () => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.get<Message[]>(API_ENDPOINTS.MESSAGES)
      messages.value = response.data
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to fetch messages'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const sendMessage = async (input: MessageInput) => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.post<Message>(API_ENDPOINTS.MESSAGES, input)
      messages.value.unshift(response.data)
      return response.data
    } catch (err) {
      const errors = api.handleError(err)
      error.value = errors[0]?.message || 'Failed to send message'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const markAsRead = async (messageId: string) => {
    try {
      await api.post(API_ENDPOINTS.MARK_READ(messageId))
      const message = messages.value.find((m) => m.id === messageId)
      if (message) {
        message.readAt = new Date().toISOString()
      }
    } catch (err) {
      // Silently fail
    }
  }

  const markAllAsRead = async () => {
    const unreadMessages = messages.value.filter((m) => !m.readAt)
    await Promise.all(unreadMessages.map((m) => markAsRead(m.id)))
  }

  return {
    messages,
    sortedMessages,
    unreadCount,
    isLoading,
    error,
    fetchMessages,
    sendMessage,
    markAsRead,
    markAllAsRead,
  }
})
