<template>
  <div class="min-h-screen bg-coal flex items-center justify-center px-4 relative">
    <!-- Subtle background texture -->
    <div class="absolute inset-0 opacity-[0.02]" style="background-image: url('data:image/svg+xml,%3Csvg viewBox=\'0 0 256 256\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cfilter id=\'n\'%3E%3CfeTurbulence type=\'fractalNoise\' baseFrequency=\'0.9\' numOctaves=\'4\' stitchTiles=\'stitch\'/%3E%3C/filter%3E%3Crect width=\'100%25\' height=\'100%25\' filter=\'url(%23n)\'/%3E%3C/svg%3E');"></div>

    <div class="w-full max-w-sm relative z-10">
      <!-- Logo -->
      <div class="text-center mb-10">
        <img
          src="@ga-personal/shared/src/assets/logo-monogram-128.png"
          alt="GA Personal"
          width="64"
          height="64"
          class="mx-auto mb-6 rounded-xl"
        />
        <h2 class="font-display text-lg font-semibold text-smoke mb-1">{{ t('auth.welcomeBack') }}</h2>
        <p class="text-sm text-stone">{{ t('auth.loginSubtitle') }}</p>
      </div>

      <form @submit.prevent="handleLogin" class="space-y-5">
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

        <div v-if="errors.general" class="p-3 bg-red-500/10 border border-red-500/20 rounded-ga">
          <p class="text-sm text-red-400">{{ errors.general }}</p>
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
      </form>

      <div class="mt-6 text-center">
        <button
          type="button"
          class="text-xs text-stone hover:text-smoke transition-colors"
        >
          {{ t('auth.forgotPassword') }}
        </button>
      </div>

      <!-- Footer -->
      <p class="mt-8 text-center text-xs text-stone/50">
        GA Personal &middot; {{ t('auth.tagline') }}
      </p>
    </div>
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
  errors.email = ''
  errors.password = ''
  errors.general = ''

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
