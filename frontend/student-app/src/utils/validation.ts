export const validateEmail = (email: string): boolean => {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return re.test(email)
}

export const validatePassword = (password: string): { valid: boolean; errors: string[] } => {
  const errors: string[] = []

  if (password.length < 8) {
    errors.push('Password must be at least 8 characters')
  }

  if (!/[A-Z]/.test(password)) {
    errors.push('Password must contain at least one uppercase letter')
  }

  if (!/[a-z]/.test(password)) {
    errors.push('Password must contain at least one lowercase letter')
  }

  if (!/[0-9]/.test(password)) {
    errors.push('Password must contain at least one number')
  }

  return {
    valid: errors.length === 0,
    errors
  }
}

export const validatePhone = (phone: string): boolean => {
  // Brazilian phone format: (XX) XXXXX-XXXX or (XX) XXXX-XXXX
  const re = /^\(\d{2}\)\s?\d{4,5}-?\d{4}$/
  return re.test(phone)
}

export const validateRPE = (rpe: number): boolean => {
  return rpe >= 1 && rpe <= 10
}

export const validateWeight = (weight: number): boolean => {
  return weight > 0 && weight <= 1000 // kg
}

export const validateReps = (reps: number): boolean => {
  return reps > 0 && reps <= 1000
}

export const validateSets = (sets: number): boolean => {
  return sets > 0 && sets <= 100
}
