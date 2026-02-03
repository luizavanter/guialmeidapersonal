<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '@ga-personal/shared'
import { useI18n } from 'vue-i18n'

const router = useRouter()
const { login, loading, error } = useAuth()
const { t } = useI18n()

const email = ref('')
const password = ref('')
const rememberMe = ref(false)

async function handleLogin() {
  try {
    await login({
      email: email.value,
      password: password.value,
      rememberMe: rememberMe.value,
    })
    router.push('/')
  } catch (err) {
    console.error('Login failed:', err)
  }
}
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-coal px-4">
    <div class="w-full max-w-md">
      <div class="card">
        <!-- Logo -->
        <div class="text-center mb-8">
          <div class="w-16 h-16 bg-lime rounded-xl mx-auto mb-4"></div>
          <h1 class="font-display text-3xl text-lime mb-2">GA PERSONAL</h1>
          <p class="text-smoke/60">{{ t('auth.loginSubtitle') }}</p>
        </div>

        <!-- Login Form -->
        <form @submit.prevent="handleLogin" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2">
              {{ t('auth.email') }}
            </label>
            <input
              v-model="email"
              type="email"
              required
              class="input"
              :placeholder="t('auth.email')"
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">
              {{ t('auth.password') }}
            </label>
            <input
              v-model="password"
              type="password"
              required
              class="input"
              :placeholder="t('auth.password')"
            />
          </div>

          <div class="flex items-center justify-between">
            <label class="flex items-center space-x-2">
              <input
                v-model="rememberMe"
                type="checkbox"
                class="w-4 h-4 rounded border-smoke/20 text-lime focus:ring-lime"
              />
              <span class="text-sm">{{ t('auth.rememberMe') }}</span>
            </label>
            <a href="#" class="text-sm text-ocean hover:underline">
              {{ t('auth.forgotPassword') }}
            </a>
          </div>

          <div v-if="error" class="p-3 bg-red-500/20 text-red-500 rounded-lg text-sm">
            {{ error.message }}
          </div>

          <button
            type="submit"
            :disabled="loading"
            class="btn btn-primary w-full"
          >
            {{ loading ? t('common.loading') : t('auth.login') }}
          </button>
        </form>
      </div>
    </div>
  </div>
</template>
