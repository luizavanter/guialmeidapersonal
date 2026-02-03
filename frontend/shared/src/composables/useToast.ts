import { ref } from 'vue'

export interface Toast {
  id: string
  type: 'success' | 'error' | 'warning' | 'info'
  message: string
  duration?: number
}

const toasts = ref<Toast[]>([])

export function useToast() {
  function show(toast: Omit<Toast, 'id'>) {
    const id = Math.random().toString(36).substring(2, 9)
    const duration = toast.duration || 5000

    const newToast: Toast = {
      ...toast,
      id,
      duration,
    }

    toasts.value.push(newToast)

    if (duration > 0) {
      setTimeout(() => {
        remove(id)
      }, duration)
    }

    return id
  }

  function remove(id: string) {
    const index = toasts.value.findIndex((t) => t.id === id)
    if (index > -1) {
      toasts.value.splice(index, 1)
    }
  }

  function success(message: string, duration?: number) {
    return show({ type: 'success', message, duration })
  }

  function error(message: string, duration?: number) {
    return show({ type: 'error', message, duration })
  }

  function warning(message: string, duration?: number) {
    return show({ type: 'warning', message, duration })
  }

  function info(message: string, duration?: number) {
    return show({ type: 'info', message, duration })
  }

  function clear() {
    toasts.value = []
  }

  return {
    toasts,
    show,
    remove,
    success,
    error,
    warning,
    info,
    clear,
  }
}
