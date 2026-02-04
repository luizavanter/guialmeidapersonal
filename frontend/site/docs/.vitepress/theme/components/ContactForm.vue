<template>
  <div class="contact-form-wrapper">
    <form
      class="contact-form"
      @submit.prevent="handleSubmit"
    >
      <div class="form-group">
        <label for="name">{{ labels.name }}</label>
        <input
          type="text"
          id="name"
          name="name"
          v-model="formData.name"
          required
          :placeholder="placeholders.name"
          :disabled="loading"
        />
      </div>

      <div class="form-group">
        <label for="email">{{ labels.email }}</label>
        <input
          type="email"
          id="email"
          name="email"
          v-model="formData.email"
          required
          :placeholder="placeholders.email"
          :disabled="loading"
        />
      </div>

      <div class="form-group">
        <label for="phone">{{ labels.phone }}</label>
        <input
          type="tel"
          id="phone"
          name="phone"
          v-model="formData.phone"
          :placeholder="placeholders.phone"
          :disabled="loading"
        />
      </div>

      <div class="form-group">
        <label for="goal">{{ labels.goal }}</label>
        <select id="goal" name="goal" v-model="formData.goal" required :disabled="loading">
          <option value="">{{ placeholders.goal }}</option>
          <option v-for="option in goalOptions" :key="option.value" :value="option.value">
            {{ option.label }}
          </option>
        </select>
      </div>

      <div class="form-group">
        <label for="message">{{ labels.message }}</label>
        <textarea
          id="message"
          name="message"
          rows="5"
          v-model="formData.message"
          required
          :placeholder="placeholders.message"
          :disabled="loading"
        ></textarea>
      </div>

      <button type="submit" class="btn btn-primary btn-block" :disabled="loading">
        <span v-if="loading" class="loading-spinner"></span>
        {{ loading ? loadingText : submitText }}
      </button>
    </form>

    <div v-if="submitted" class="success-message">
      {{ successMessage }}
    </div>

    <div v-if="errorMessage" class="error-message">
      {{ errorMessage }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'

const props = defineProps<{
  labels: {
    name: string
    email: string
    phone: string
    goal: string
    message: string
  }
  placeholders: {
    name: string
    email: string
    phone: string
    goal: string
    message: string
  }
  goalOptions: Array<{ value: string; label: string }>
  submitText: string
  successMessage: string
  loadingText?: string
  errorText?: string
  locale?: string
}>()

const API_URL = import.meta.env.VITE_API_URL || 'https://api.guialmeidapersonal.esp.br'

const formData = reactive({
  name: '',
  email: '',
  phone: '',
  goal: '',
  message: ''
})

const loading = ref(false)
const submitted = ref(false)
const errorMessage = ref('')

const handleSubmit = async () => {
  loading.value = true
  errorMessage.value = ''
  submitted.value = false

  try {
    const response = await fetch(`${API_URL}/api/v1/contact`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': props.locale || 'pt-BR'
      },
      body: JSON.stringify({
        contact: {
          name: formData.name,
          email: formData.email,
          phone: formData.phone || null,
          goal: formData.goal || null,
          message: formData.message,
          locale: props.locale === 'en' ? 'en_US' : 'pt_BR'
        }
      })
    })

    const data = await response.json()

    if (response.ok) {
      submitted.value = true
      // Reset form
      formData.name = ''
      formData.email = ''
      formData.phone = ''
      formData.goal = ''
      formData.message = ''
    } else {
      errorMessage.value = data.error || props.errorText || 'Erro ao enviar mensagem. Tente novamente.'
    }
  } catch (error) {
    console.error('Contact form error:', error)
    errorMessage.value = props.errorText || 'Erro ao enviar mensagem. Tente novamente.'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped lang="scss">
@import '../styles/variables.scss';

.contact-form-wrapper {
  max-width: 600px;
  margin: 0 auto;
}

.contact-form {
  display: flex;
  flex-direction: column;
  gap: $spacing-md;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: $spacing-xs;

  label {
    font-weight: 600;
    color: $smoke;
    font-size: 0.95rem;
  }

  input,
  textarea,
  select {
    padding: $spacing-sm;
    border: 2px solid rgba($smoke, 0.2);
    border-radius: 8px;
    background-color: lighten($coal, 5%);
    color: $smoke;
    font-family: $font-body;
    font-size: 1rem;
    transition: border-color 0.3s ease;

    &:focus {
      outline: none;
      border-color: $lime;
    }

    &::placeholder {
      color: rgba($smoke, 0.4);
    }

    &:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }
  }

  textarea {
    resize: vertical;
    min-height: 120px;
  }
}

.btn-block {
  width: 100%;
  padding: $spacing-md;
  font-size: 1.1rem;
  margin-top: $spacing-sm;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;

  &:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }
}

.loading-spinner {
  width: 18px;
  height: 18px;
  border: 2px solid transparent;
  border-top-color: currentColor;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.success-message {
  margin-top: $spacing-lg;
  padding: $spacing-md;
  background-color: rgba($lime, 0.1);
  border: 2px solid $lime;
  border-radius: 8px;
  color: $lime;
  text-align: center;
  font-weight: 600;
}

.error-message {
  margin-top: $spacing-lg;
  padding: $spacing-md;
  background-color: rgba(#ef4444, 0.1);
  border: 2px solid #ef4444;
  border-radius: 8px;
  color: #ef4444;
  text-align: center;
  font-weight: 600;
}
</style>
