<template>
  <div class="min-h-screen bg-coal flex items-center justify-center px-4">
    <Card class="w-full max-w-md">
      <div class="text-center mb-8">
        <h1 class="text-4xl font-display text-lime mb-2">GA PERSONAL</h1>
        <h2 class="text-2xl font-semibold text-smoke mb-2">{{ t('auth.welcomeBack') }}</h2>
        <p class="text-smoke/60">{{ t('auth.loginSubtitle') }}</p>
      </div>

      <form @submit.prevent="handleLogin">
        <div class="space-y-4">
          <Input
            id="email"
            v-model="form.email"
            type="email"
            :label="t('auth.email')"
            :error="errors.email"
            required
            autocomplete="email"
          />

          <Input
            id="password"
            v-model="form.password"
            type="password"
            :label="t('auth.password')"
            :error="errors.password"
            required
            autocomplete="current-password"
          />

          <div v-if="errors.general" class="p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
            <p class="text-sm text-red-500">{{ errors.general }}</p>
          </div>

          <Button
            type="submit"
            variant="primary"
            size="lg"
            full-width
            :loading="isLoading"
            :disabled="isLoading"
          >
            {{ t('auth.login') }}
          </Button>
        </div>
      </form>

      <div class="mt-6 text-center">
        <button
          type="button"
          class="text-sm text-ocean hover:text-ocean/80 transition-colors"
        >
          {{ t('auth.forgotPassword') }}
        </button>
      </div>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuth } from '@/composables/useAuth'
import { validateEmail } from '@/utils/validation'
import Card from '@/components/ui/Card.vue'
import Input from '@/components/ui/Input.vue'
import Button from '@/components/ui/Button.vue'

const { t } = useI18n()
const { login, isLoading } = useAuth()

const form = reactive({
  email: '',
  password: '',
})

const errors = reactive({
  email: '',
  password: '',
  general: '',
})

const handleLogin = async () => {
  // Reset errors
  errors.email = ''
  errors.password = ''
  errors.general = ''

  // Validate
  if (!form.email) {
    errors.email = t('validation.required')
    return
  }

  if (!validateEmail(form.email)) {
    errors.email = t('validation.email')
    return
  }

  if (!form.password) {
    errors.password = t('validation.required')
    return
  }

  try {
    await login({
      email: form.email,
      password: form.password,
    })
  } catch (error: any) {
    errors.general = error?.message || t('auth.invalidCredentials')
  }
}
</script>
