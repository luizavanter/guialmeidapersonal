import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useApi } from '@ga-personal/shared'
import { API_ENDPOINTS } from '@ga-personal/shared'

interface Message {
  id: string
  subject: string
  body: string
  readAt: string | null
  insertedAt: string
  sender?: {
    id: string
    firstName: string
    lastName: string
    fullName?: string
    email: string
  }
  recipient?: {
    id: string
    firstName: string
    lastName: string
    fullName?: string
    email: string
  }
}

// Normalize user object from backend (full_name -> firstName/lastName)
function normalizeUser(user: any) {
  if (!user) return undefined
  const fullName = user.full_name || user.fullName || ''
  const parts = fullName.split(' ')
  return {
    id: user.id,
    firstName: user.firstName || parts[0] || '',
    lastName: user.lastName || parts.slice(1).join(' ') || '',
    fullName,
    email: user.email,
  }
}

// Normalize backend snake_case message to frontend format
function normalizeMessage(raw: any): Message {
  return {
    id: raw.id,
    subject: raw.subject || '',
    body: raw.body || '',
    readAt: raw.read_at || raw.readAt || null,
    insertedAt: raw.inserted_at || raw.insertedAt || '',
    sender: normalizeUser(raw.sender),
    recipient: normalizeUser(raw.recipient),
  }
}

export const useMessagesStore = defineStore('messages', () => {
  const api = useApi()

  const messages = ref<Message[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  const unreadCount = computed(() =>
    messages.value.filter(m => !m.readAt).length
  )

  const sortedMessages = computed(() =>
    [...messages.value].sort(
      (a, b) => new Date(b.insertedAt).getTime() - new Date(a.insertedAt).getTime()
    )
  )

  async function fetchMessages() {
    loading.value = true
    error.value = null

    try {
      const response = await api.get(API_ENDPOINTS.MESSAGES)
      const data = response.data || response || []
      messages.value = (Array.isArray(data) ? data : []).map(normalizeMessage)
    } catch (err: any) {
      error.value = err.message || 'Failed to fetch messages'
    } finally {
      loading.value = false
    }
  }

  async function sendMessage(data: { recipient_id: string; subject: string; body: string }) {
    loading.value = true
    error.value = null

    try {
      const response = await api.post(API_ENDPOINTS.MESSAGES, { message: data })
      const newMessage = normalizeMessage(response.data || response)
      messages.value.unshift(newMessage)
      return newMessage
    } catch (err: any) {
      error.value = err.message || 'Failed to send message'
      throw err
    } finally {
      loading.value = false
    }
  }

  async function markAsRead(messageId: string) {
    try {
      await api.put(`/messages/${messageId}/read`)
      const message = messages.value.find(m => m.id === messageId)
      if (message) {
        message.readAt = new Date().toISOString()
      }
    } catch {
      // Silently fail
    }
  }

  return {
    messages,
    sortedMessages,
    unreadCount,
    loading,
    error,
    fetchMessages,
    sendMessage,
    markAsRead,
  }
})
