/**
 * Formatting utility functions
 */

export const formatCurrency = (
  value: number,
  currency = 'BRL',
  locale = 'pt-BR'
): string => {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
  }).format(value)
}

export const formatNumber = (
  value: number,
  decimals = 0,
  locale = 'pt-BR'
): string => {
  return new Intl.NumberFormat(locale, {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(value)
}

export const formatPercent = (
  value: number,
  decimals = 0,
  locale = 'pt-BR'
): string => {
  return new Intl.NumberFormat(locale, {
    style: 'percent',
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(value / 100)
}

export const formatCPF = (cpf: string): string => {
  const cleaned = cpf.replace(/\D/g, '')
  if (cleaned.length !== 11) return cpf
  return cleaned.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4')
}

export const formatCNPJ = (cnpj: string): string => {
  const cleaned = cnpj.replace(/\D/g, '')
  if (cleaned.length !== 14) return cnpj
  return cleaned.replace(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '$1.$2.$3/$4-$5')
}

export const formatPhone = (phone: string): string => {
  const cleaned = phone.replace(/\D/g, '')

  if (cleaned.length === 11) {
    // Mobile: (XX) XXXXX-XXXX
    return cleaned.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3')
  } else if (cleaned.length === 10) {
    // Landline: (XX) XXXX-XXXX
    return cleaned.replace(/(\d{2})(\d{4})(\d{4})/, '($1) $2-$3')
  }

  return phone
}

export const formatCEP = (cep: string): string => {
  const cleaned = cep.replace(/\D/g, '')
  if (cleaned.length !== 8) return cep
  return cleaned.replace(/(\d{5})(\d{3})/, '$1-$2')
}

export const formatWeight = (kg: number, locale = 'pt-BR'): string => {
  const unit = locale === 'pt-BR' ? 'kg' : 'lbs'
  const value = locale === 'pt-BR' ? kg : kg * 2.20462
  return `${formatNumber(value, 1, locale)} ${unit}`
}

export const formatHeight = (cm: number, locale = 'pt-BR'): string => {
  if (locale === 'pt-BR') {
    return `${formatNumber(cm, 0, locale)} cm`
  } else {
    const totalInches = cm / 2.54
    const feet = Math.floor(totalInches / 12)
    const inches = Math.round(totalInches % 12)
    return `${feet}'${inches}"`
  }
}

export const formatBodyFat = (percentage: number, locale = 'pt-BR'): string => {
  return `${formatNumber(percentage, 1, locale)}%`
}

export const formatMeasurement = (cm: number, locale = 'pt-BR'): string => {
  const unit = locale === 'pt-BR' ? 'cm' : 'in'
  const value = locale === 'pt-BR' ? cm : cm / 2.54
  return `${formatNumber(value, 1, locale)} ${unit}`
}

export const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes'

  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))

  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`
}

export const truncate = (text: string, length: number, suffix = '...'): string => {
  if (text.length <= length) return text
  return text.substring(0, length - suffix.length) + suffix
}

export const capitalize = (text: string): string => {
  return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase()
}

export const titleCase = (text: string): string => {
  return text
    .split(' ')
    .map(word => capitalize(word))
    .join(' ')
}

export const kebabCase = (text: string): string => {
  return text
    .replace(/([a-z])([A-Z])/g, '$1-$2')
    .replace(/[\s_]+/g, '-')
    .toLowerCase()
}

export const camelCase = (text: string): string => {
  return text
    .replace(/[-_\s]+(.)?/g, (_, c) => c ? c.toUpperCase() : '')
    .replace(/^(.)/, (_, c) => c.toLowerCase())
}

export const snakeCase = (text: string): string => {
  return text
    .replace(/([a-z])([A-Z])/g, '$1_$2')
    .replace(/[\s-]+/g, '_')
    .toLowerCase()
}

export const pluralize = (count: number, singular: string, plural?: string): string => {
  if (count === 1) return `${count} ${singular}`
  return `${count} ${plural || singular + 's'}`
}

export const initials = (name: string): string => {
  return name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .substring(0, 2)
}

export const maskEmail = (email: string): string => {
  const [user, domain] = email.split('@')
  if (!user || !domain) return email

  const masked = user.length > 3
    ? user.substring(0, 2) + '***'
    : user

  return `${masked}@${domain}`
}

export const maskPhone = (phone: string): string => {
  const cleaned = phone.replace(/\D/g, '')
  if (cleaned.length < 8) return phone

  const visible = cleaned.substring(0, 2) + cleaned.substring(cleaned.length - 4)
  const masked = '*'.repeat(cleaned.length - 6)

  return formatPhone(visible.substring(0, 2) + masked + visible.substring(2))
}

export const slugify = (text: string): string => {
  return text
    .toString()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '')
}
