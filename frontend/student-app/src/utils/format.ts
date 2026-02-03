export const formatWeight = (weight: number, locale: string = 'pt-BR'): string => {
  return `${weight.toFixed(1)} kg`
}

export const formatPercentage = (value: number, locale: string = 'pt-BR'): string => {
  return `${value.toFixed(1)}%`
}

export const formatMeasurement = (value: number, unit: string = 'cm'): string => {
  return `${value.toFixed(1)} ${unit}`
}

export const formatRPE = (rpe: number): string => {
  return `${rpe}/10`
}

export const formatDuration = (seconds: number, locale: string = 'pt-BR'): string => {
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const secs = seconds % 60

  if (hours > 0) {
    return `${hours}h ${minutes}m`
  } else if (minutes > 0) {
    return `${minutes}m ${secs}s`
  } else {
    return `${secs}s`
  }
}

export const formatPhone = (phone: string): string => {
  // Format: (XX) XXXXX-XXXX
  const cleaned = phone.replace(/\D/g, '')
  if (cleaned.length === 11) {
    return `(${cleaned.slice(0, 2)}) ${cleaned.slice(2, 7)}-${cleaned.slice(7)}`
  } else if (cleaned.length === 10) {
    return `(${cleaned.slice(0, 2)}) ${cleaned.slice(2, 6)}-${cleaned.slice(6)}`
  }
  return phone
}

export const truncate = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) return text
  return text.slice(0, maxLength) + '...'
}
