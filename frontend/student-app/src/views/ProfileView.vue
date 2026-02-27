<template>
  <div>
    <div class="mb-8">
      <h1 class="text-display-md text-smoke mb-2">{{ t('profile.title') }}</h1>
    </div>

    <div v-if="isLoading" class="text-center py-12">
      <p class="text-stone">{{ t('common.loading') }}</p>
    </div>

    <div v-else class="max-w-3xl">
      <Card :title="t('profile.personalInfo')">
        <form @submit.prevent="handleUpdateProfile">
          <div class="space-y-4">
            <!-- User Info (Read-only) -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input
                v-model="form.name"
                :label="t('profile.name')"
                :error="errors.name"
                required
                disabled
              />
              <Input
                v-model="form.email"
                type="email"
                :label="t('profile.email')"
                disabled
              />
            </div>

            <!-- Editable Fields -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input
                v-model="form.phone"
                type="tel"
                :label="t('profile.phone')"
                :error="errors.phone"
                placeholder="(XX) XXXXX-XXXX"
              />
              <Input
                v-model="form.dateOfBirth"
                type="date"
                :label="t('profile.dateOfBirth')"
              />
            </div>

            <!-- Emergency Contact -->
            <div class="pt-4 border-t border-surface-3">
              <h3 class="text-lg font-semibold text-smoke mb-4">Contato de Emergência</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <Input
                  v-model="form.emergencyContact"
                  :label="t('profile.emergencyContact')"
                  placeholder="Nome completo"
                />
                <Input
                  v-model="form.emergencyPhone"
                  type="tel"
                  :label="t('profile.emergencyPhone')"
                  placeholder="(XX) XXXXX-XXXX"
                />
              </div>
            </div>

            <!-- Health Info -->
            <div class="pt-4 border-t border-surface-3">
              <h3 class="text-lg font-semibold text-smoke mb-4">Informações de Saúde</h3>
              <div class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-smoke mb-1">
                    {{ t('profile.healthConditions') }}
                  </label>
                  <textarea
                    v-model="form.healthConditions"
                    rows="3"
                    class="block w-full rounded-lg bg-surface-1 border border-surface-3 px-4 py-2 text-smoke placeholder-stone focus:outline-none focus:ring-2 focus:border-lime focus:ring-lime"
                    placeholder="Alergias, lesões, condições crônicas, etc."
                  ></textarea>
                </div>

                <div>
                  <label class="block text-sm font-medium text-smoke mb-1">
                    {{ t('profile.goals') }}
                  </label>
                  <textarea
                    v-model="form.goals"
                    rows="3"
                    class="block w-full rounded-lg bg-surface-1 border border-surface-3 px-4 py-2 text-smoke placeholder-stone focus:outline-none focus:ring-2 focus:border-lime focus:ring-lime"
                    placeholder="Seus objetivos com o treinamento"
                  ></textarea>
                </div>
              </div>
            </div>

            <div v-if="errors.general" class="p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
              <p class="text-sm text-red-500">{{ errors.general }}</p>
            </div>

            <div v-if="updateSuccess" class="p-3 bg-green-500/10 border border-green-500/20 rounded-lg">
              <p class="text-sm text-green-500">{{ t('profile.updateSuccess') }}</p>
            </div>

            <div class="flex justify-end gap-3 pt-4">
              <Button
                type="button"
                variant="ghost"
                @click="loadProfile"
              >
                {{ t('common.cancel') }}
              </Button>
              <Button
                type="submit"
                variant="primary"
                :loading="isSubmitting"
              >
                {{ t('common.save') }}
              </Button>
            </div>
          </div>
        </form>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth'
import { useProfileStore } from '@/stores/profile'
import { validatePhone } from '@/utils/validation'
import Card from '@/components/ui/Card.vue'
import Input from '@/components/ui/Input.vue'
import Button from '@/components/ui/Button.vue'

const { t } = useI18n()
const authStore = useAuthStore()
const profileStore = useProfileStore()

const isSubmitting = ref(false)
const updateSuccess = ref(false)

const form = reactive({
  name: '',
  email: '',
  phone: '',
  dateOfBirth: '',
  emergencyContact: '',
  emergencyPhone: '',
  healthConditions: '',
  goals: '',
})

const errors = reactive({
  name: '',
  phone: '',
  general: '',
})

const isLoading = computed(() => profileStore.isLoading)

const loadProfile = () => {
  const user = authStore.user
  const profile = profileStore.profile

  form.name = user?.name || ''
  form.email = user?.email || ''
  form.phone = profile?.phone || ''
  form.dateOfBirth = profile?.dateOfBirth || ''
  form.emergencyContact = profile?.emergencyContact || ''
  form.emergencyPhone = profile?.emergencyPhone || ''
  form.healthConditions = profile?.healthConditions || ''
  form.goals = profile?.goals || ''

  errors.name = ''
  errors.phone = ''
  errors.general = ''
  updateSuccess.value = false
}

const handleUpdateProfile = async () => {
  errors.name = ''
  errors.phone = ''
  errors.general = ''
  updateSuccess.value = false

  // Validate phone if provided
  if (form.phone && !validatePhone(form.phone)) {
    errors.phone = t('validation.phone')
    return
  }

  isSubmitting.value = true

  try {
    await profileStore.updateProfile({
      phone: form.phone || undefined,
      dateOfBirth: form.dateOfBirth || undefined,
      emergencyContact: form.emergencyContact || undefined,
      emergencyPhone: form.emergencyPhone || undefined,
      healthConditions: form.healthConditions || undefined,
      goals: form.goals || undefined,
    })

    updateSuccess.value = true

    // Hide success message after 3 seconds
    setTimeout(() => {
      updateSuccess.value = false
    }, 3000)
  } catch (error) {
    errors.general = t('profile.updateError')
  } finally {
    isSubmitting.value = false
  }
}

onMounted(async () => {
  await profileStore.fetchProfile()
  loadProfile()
})
</script>
