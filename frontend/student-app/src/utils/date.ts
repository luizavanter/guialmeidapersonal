export const formatDate = (date: string | Date, locale: string = 'pt-BR'): string => {
  const d = typeof date === 'string' ? new Date(date) : date
  return new Intl.DateTimeFormat(locale, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(d)
}

export const formatTime = (time: string, locale: string = 'pt-BR'): string => {
  const [hours, minutes] = time.split(':')
  const date = new Date()
  date.setHours(parseInt(hours), parseInt(minutes))
  return new Intl.DateTimeFormat(locale, {
    hour: '2-digit',
    minute: '2-digit',
  }).format(date)
}

export const formatDateTime = (datetime: string | Date, locale: string = 'pt-BR'): string => {
  const d = typeof datetime === 'string' ? new Date(datetime) : datetime
  return new Intl.DateTimeFormat(locale, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(d)
}

export const formatRelativeTime = (date: string | Date, locale: string = 'pt-BR'): string => {
  const d = typeof date === 'string' ? new Date(date) : date
  const now = new Date()
  const diff = now.getTime() - d.getTime()
  const seconds = Math.floor(diff / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)

  if (days > 7) {
    return formatDate(d, locale)
  } else if (days > 0) {
    return locale === 'pt-BR' ? `${days}d atrás` : `${days}d ago`
  } else if (hours > 0) {
    return locale === 'pt-BR' ? `${hours}h atrás` : `${hours}h ago`
  } else if (minutes > 0) {
    return locale === 'pt-BR' ? `${minutes}m atrás` : `${minutes}m ago`
  } else {
    return locale === 'pt-BR' ? 'Agora' : 'Now'
  }
}

export const getDayOfWeekName = (dayOfWeek: number, locale: string = 'pt-BR'): string => {
  const days = locale === 'pt-BR'
    ? ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado']
    : ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  return days[dayOfWeek]
}

export const isToday = (date: string | Date): boolean => {
  const d = typeof date === 'string' ? new Date(date) : date
  const today = new Date()
  return d.getDate() === today.getDate() &&
    d.getMonth() === today.getMonth() &&
    d.getFullYear() === today.getFullYear()
}

export const isFuture = (date: string | Date): boolean => {
  const d = typeof date === 'string' ? new Date(date) : date
  return d.getTime() > new Date().getTime()
}
