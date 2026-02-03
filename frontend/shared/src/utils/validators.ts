/**
 * Validation utility functions
 */

import { REGEX } from '@/constants'

export const isRequired = (value: any): boolean => {
  if (value === null || value === undefined) return false
  if (typeof value === 'string') return value.trim().length > 0
  if (Array.isArray(value)) return value.length > 0
  return true
}

export const isEmail = (email: string): boolean => {
  return REGEX.EMAIL.test(email)
}

export const isPhone = (phone: string): boolean => {
  return REGEX.PHONE.test(phone)
}

export const isUrl = (url: string): boolean => {
  return REGEX.URL.test(url)
}

export const isPassword = (password: string): boolean => {
  return REGEX.PASSWORD.test(password)
}

export const minLength = (value: string, min: number): boolean => {
  return value.length >= min
}

export const maxLength = (value: string, max: number): boolean => {
  return value.length <= max
}

export const min = (value: number, minValue: number): boolean => {
  return value >= minValue
}

export const max = (value: number, maxValue: number): boolean => {
  return value <= maxValue
}

export const isNumeric = (value: any): boolean => {
  return !isNaN(parseFloat(value)) && isFinite(value)
}

export const isInteger = (value: any): boolean => {
  return Number.isInteger(Number(value))
}

export const isPositive = (value: number): boolean => {
  return value > 0
}

export const isNegative = (value: number): boolean => {
  return value < 0
}

export const isBetween = (value: number, min: number, max: number): boolean => {
  return value >= min && value <= max
}

export const matches = (value: string, pattern: RegExp): boolean => {
  return pattern.test(value)
}

export const isDate = (value: string): boolean => {
  const date = new Date(value)
  return !isNaN(date.getTime())
}

export const isAfter = (date: string | Date, compareDate: string | Date): boolean => {
  const d1 = typeof date === 'string' ? new Date(date) : date
  const d2 = typeof compareDate === 'string' ? new Date(compareDate) : compareDate
  return d1.getTime() > d2.getTime()
}

export const isBefore = (date: string | Date, compareDate: string | Date): boolean => {
  const d1 = typeof date === 'string' ? new Date(date) : date
  const d2 = typeof compareDate === 'string' ? new Date(compareDate) : compareDate
  return d1.getTime() < d2.getTime()
}

export const isCPF = (cpf: string): boolean => {
  // Remove non-digits
  cpf = cpf.replace(/\D/g, '')

  if (cpf.length !== 11) return false

  // Check if all digits are the same
  if (/^(\d)\1{10}$/.test(cpf)) return false

  // Validate first digit
  let sum = 0
  for (let i = 0; i < 9; i++) {
    sum += parseInt(cpf.charAt(i)) * (10 - i)
  }
  let digit = 11 - (sum % 11)
  if (digit >= 10) digit = 0
  if (digit !== parseInt(cpf.charAt(9))) return false

  // Validate second digit
  sum = 0
  for (let i = 0; i < 10; i++) {
    sum += parseInt(cpf.charAt(i)) * (11 - i)
  }
  digit = 11 - (sum % 11)
  if (digit >= 10) digit = 0
  if (digit !== parseInt(cpf.charAt(10))) return false

  return true
}

export const isCNPJ = (cnpj: string): boolean => {
  // Remove non-digits
  cnpj = cnpj.replace(/\D/g, '')

  if (cnpj.length !== 14) return false

  // Check if all digits are the same
  if (/^(\d)\1{13}$/.test(cnpj)) return false

  // Validate first digit
  let size = cnpj.length - 2
  let numbers = cnpj.substring(0, size)
  const digits = cnpj.substring(size)
  let sum = 0
  let pos = size - 7

  for (let i = size; i >= 1; i--) {
    sum += parseInt(numbers.charAt(size - i)) * pos--
    if (pos < 2) pos = 9
  }

  let result = sum % 11 < 2 ? 0 : 11 - (sum % 11)
  if (result !== parseInt(digits.charAt(0))) return false

  // Validate second digit
  size = size + 1
  numbers = cnpj.substring(0, size)
  sum = 0
  pos = size - 7

  for (let i = size; i >= 1; i--) {
    sum += parseInt(numbers.charAt(size - i)) * pos--
    if (pos < 2) pos = 9
  }

  result = sum % 11 < 2 ? 0 : 11 - (sum % 11)
  if (result !== parseInt(digits.charAt(1))) return false

  return true
}

export const validateField = (value: any, rules: any[]): string | null => {
  for (const rule of rules) {
    if (rule.type === 'required' && !isRequired(value)) {
      return rule.message || 'This field is required'
    }
    if (rule.type === 'email' && !isEmail(value)) {
      return rule.message || 'Please enter a valid email'
    }
    if (rule.type === 'phone' && !isPhone(value)) {
      return rule.message || 'Please enter a valid phone number'
    }
    if (rule.type === 'url' && !isUrl(value)) {
      return rule.message || 'Please enter a valid URL'
    }
    if (rule.type === 'password' && !isPassword(value)) {
      return rule.message || 'Password must meet requirements'
    }
    if (rule.type === 'minLength' && !minLength(value, rule.value)) {
      return rule.message || `Minimum length is ${rule.value}`
    }
    if (rule.type === 'maxLength' && !maxLength(value, rule.value)) {
      return rule.message || `Maximum length is ${rule.value}`
    }
    if (rule.type === 'min' && !min(value, rule.value)) {
      return rule.message || `Minimum value is ${rule.value}`
    }
    if (rule.type === 'max' && !max(value, rule.value)) {
      return rule.message || `Maximum value is ${rule.value}`
    }
    if (rule.type === 'numeric' && !isNumeric(value)) {
      return rule.message || 'Please enter a valid number'
    }
    if (rule.type === 'custom' && rule.validator && !rule.validator(value)) {
      return rule.message || 'Validation failed'
    }
  }
  return null
}
