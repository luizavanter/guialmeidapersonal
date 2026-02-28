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
  <div class="min-h-screen flex items-center justify-center bg-coal px-4 relative">
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
        <h1 class="font-display text-xl font-bold tracking-tight text-smoke mb-1">GA Personal</h1>
        <p class="text-sm text-stone">{{ t('auth.loginSubtitle') }}</p>
      </div>

      <!-- Login Form -->
      <form @submit.prevent="handleLogin" class="space-y-5">
        <div>
          <label class="block text-xs font-medium text-stone uppercase tracking-wider mb-2">
            {{ t('auth.email') }}
          </label>
          <input
            v-model="email"
            type="email"
            required
            class="w-full px-4 py-3 bg-surface-1 border border-surface-3 rounded-ga text-smoke placeholder-stone/50 focus:outline-none focus:border-lime/40 focus:ring-1 focus:ring-lime/20 transition-colors text-sm"
            :placeholder="t('auth.email')"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-stone uppercase tracking-wider mb-2">
            {{ t('auth.password') }}
          </label>
          <input
            v-model="password"
            type="password"
            required
            class="w-full px-4 py-3 bg-surface-1 border border-surface-3 rounded-ga text-smoke placeholder-stone/50 focus:outline-none focus:border-lime/40 focus:ring-1 focus:ring-lime/20 transition-colors text-sm"
            :placeholder="t('auth.password')"
          />
        </div>

        <div class="flex items-center justify-between">
          <label class="flex items-center space-x-2">
            <input
              v-model="rememberMe"
              type="checkbox"
              class="w-3.5 h-3.5 rounded border-surface-3 text-lime focus:ring-lime/30"
            />
            <span class="text-xs text-stone">{{ t('auth.rememberMe') }}</span>
          </label>
          <a href="#" class="text-xs text-stone hover:text-smoke transition-colors">
            {{ t('auth.forgotPassword') }}
          </a>
        </div>

        <div v-if="error" class="p-3 bg-red-500/10 border border-red-500/20 text-red-400 rounded-ga text-sm">
          {{ error.message }}
        </div>

        <button
          type="submit"
          :disabled="loading"
          class="w-full py-3 bg-lime text-coal font-semibold text-sm rounded-ga hover:bg-lime/90 active:scale-[0.98] transition-all disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {{ loading ? t('common.loading') : t('auth.login') }}
        </button>
      </form>

      <!-- Footer -->
      <p class="mt-8 text-center text-xs text-stone/50">
        GA Personal &middot; {{ t('auth.tagline') }}
      </p>
    </div>
  </div>
</template>
