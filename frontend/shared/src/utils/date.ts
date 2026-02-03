/**
 * Date utility functions for GA Personal
 */

export const formatDate = (date: string | Date, format = 'DD/MM/YYYY'): string => {
  const d = typeof date === 'string' ? new Date(date) : date

  if (isNaN(d.getTime())) return ''

  const day = String(d.getDate()).padStart(2, '0')
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const year = d.getFullYear()
  const hours = String(d.getHours()).padStart(2, '0')
  const minutes = String(d.getMinutes()).padStart(2, '0')
  const seconds = String(d.getSeconds()).padStart(2, '0')

  return format
    .replace('DD', day)
    .replace('MM', month)
    .replace('YYYY', String(year))
    .replace('HH', hours)
    .replace('mm', minutes)
    .replace('ss', seconds)
}

export const formatDateTime = (date: string | Date): string => {
  return formatDate(date, 'DD/MM/YYYY HH:mm')
}

export const formatTime = (date: string | Date): string => {
  return formatDate(date, 'HH:mm')
}

export const parseDate = (dateStr: string): Date | null => {
  const date = new Date(dateStr)
  return isNaN(date.getTime()) ? null : date
}

export const isToday = (date: string | Date): boolean => {
  const d = typeof date === 'string' ? new Date(date) : date
  const today = new Date()

  return d.getDate() === today.getDate() &&
    d.getMonth() === today.getMonth() &&
    d.getFullYear() === today.getFullYear()
}

export const isTomorrow = (date: string | Date): boolean => {
  const d = typeof date === 'string' ? new Date(date) : date
  const tomorrow = new Date()
  tomorrow.setDate(tomorrow.getDate() + 1)

  return d.getDate() === tomorrow.getDate() &&
    d.getMonth() === tomorrow.getMonth() &&
    d.getFullYear() === tomorrow.getFullYear()
}

export const isYesterday = (date: string | Date): boolean => {
  const d = typeof date === 'string' ? new Date(date) : date
  const yesterday = new Date()
  yesterday.setDate(yesterday.getDate() - 1)

  return d.getDate() === yesterday.getDate() &&
    d.getMonth() === yesterday.getMonth() &&
    d.getFullYear() === yesterday.getFullYear()
}

export const getRelativeTime = (date: string | Date, locale = 'pt-BR'): string => {
  const d = typeof date === 'string' ? new Date(date) : date
  const now = new Date()
  const diffMs = now.getTime() - d.getTime()
  const diffSecs = Math.floor(diffMs / 1000)
  const diffMins = Math.floor(diffSecs / 60)
  const diffHours = Math.floor(diffMins / 60)
  const diffDays = Math.floor(diffHours / 24)

  const translations = {
    'pt-BR': {
      now: 'agora',
      seconds: 'segundos atrás',
      minute: 'minuto atrás',
      minutes: 'minutos atrás',
      hour: 'hora atrás',
      hours: 'horas atrás',
      day: 'dia atrás',
      days: 'dias atrás',
    },
    'en-US': {
      now: 'now',
      seconds: 'seconds ago',
      minute: 'minute ago',
      minutes: 'minutes ago',
      hour: 'hour ago',
      hours: 'hours ago',
      day: 'day ago',
      days: 'days ago',
    }
  }

  const t = translations[locale as keyof typeof translations]

  if (diffSecs < 60) return t.now
  if (diffMins === 1) return `1 ${t.minute}`
  if (diffMins < 60) return `${diffMins} ${t.minutes}`
  if (diffHours === 1) return `1 ${t.hour}`
  if (diffHours < 24) return `${diffHours} ${t.hours}`
  if (diffDays === 1) return `1 ${t.day}`
  if (diffDays < 7) return `${diffDays} ${t.days}`

  return formatDate(d)
}

export const addDays = (date: Date, days: number): Date => {
  const result = new Date(date)
  result.setDate(result.getDate() + days)
  return result
}

export const addWeeks = (date: Date, weeks: number): Date => {
  return addDays(date, weeks * 7)
}

export const addMonths = (date: Date, months: number): Date => {
  const result = new Date(date)
  result.setMonth(result.getMonth() + months)
  return result
}

export const getDaysBetween = (date1: string | Date, date2: string | Date): number => {
  const d1 = typeof date1 === 'string' ? new Date(date1) : date1
  const d2 = typeof date2 === 'string' ? new Date(date2) : date2
  const diffMs = Math.abs(d2.getTime() - d1.getTime())
  return Math.floor(diffMs / (1000 * 60 * 60 * 24))
}

export const getStartOfDay = (date: Date = new Date()): Date => {
  const result = new Date(date)
  result.setHours(0, 0, 0, 0)
  return result
}

export const getEndOfDay = (date: Date = new Date()): Date => {
  const result = new Date(date)
  result.setHours(23, 59, 59, 999)
  return result
}

export const getStartOfWeek = (date: Date = new Date()): Date => {
  const result = new Date(date)
  const day = result.getDay()
  const diff = result.getDate() - day
  result.setDate(diff)
  return getStartOfDay(result)
}

export const getEndOfWeek = (date: Date = new Date()): Date => {
  const result = new Date(date)
  const day = result.getDay()
  const diff = result.getDate() + (6 - day)
  result.setDate(diff)
  return getEndOfDay(result)
}

export const getStartOfMonth = (date: Date = new Date()): Date => {
  const result = new Date(date)
  result.setDate(1)
  return getStartOfDay(result)
}

export const getEndOfMonth = (date: Date = new Date()): Date => {
  const result = new Date(date)
  result.setMonth(result.getMonth() + 1, 0)
  return getEndOfDay(result)
}

export const isValidDate = (date: any): boolean => {
  if (date instanceof Date) {
    return !isNaN(date.getTime())
  }
  if (typeof date === 'string') {
    const parsed = new Date(date)
    return !isNaN(parsed.getTime())
  }
  return false
}

export const formatDuration = (minutes: number, locale = 'pt-BR'): string => {
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60

  const translations = {
    'pt-BR': { hour: 'h', minute: 'min' },
    'en-US': { hour: 'h', minute: 'min' }
  }

  const t = translations[locale as keyof typeof translations]

  if (hours > 0 && mins > 0) {
    return `${hours}${t.hour} ${mins}${t.minute}`
  } else if (hours > 0) {
    return `${hours}${t.hour}`
  } else {
    return `${mins}${t.minute}`
  }
}
