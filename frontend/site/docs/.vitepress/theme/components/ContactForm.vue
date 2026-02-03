<template>
  <div class="contact-form-wrapper">
    <form
      class="contact-form"
      action="https://formspree.io/f/YOUR_FORM_ID"
      method="POST"
      @submit="handleSubmit"
    >
      <div class="form-group">
        <label for="name">{{ labels.name }}</label>
        <input
          type="text"
          id="name"
          name="name"
          required
          :placeholder="placeholders.name"
        />
      </div>

      <div class="form-group">
        <label for="email">{{ labels.email }}</label>
        <input
          type="email"
          id="email"
          name="email"
          required
          :placeholder="placeholders.email"
        />
      </div>

      <div class="form-group">
        <label for="phone">{{ labels.phone }}</label>
        <input
          type="tel"
          id="phone"
          name="phone"
          :placeholder="placeholders.phone"
        />
      </div>

      <div class="form-group">
        <label for="goal">{{ labels.goal }}</label>
        <select id="goal" name="goal" required>
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
          required
          :placeholder="placeholders.message"
        ></textarea>
      </div>

      <button type="submit" class="btn btn-primary btn-block">
        {{ submitText }}
      </button>
    </form>

    <div v-if="submitted" class="success-message">
      {{ successMessage }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

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
}>()

const submitted = ref(false)

const handleSubmit = (e: Event) => {
  // Form will be handled by Formspree
  // Show success message after submission
  setTimeout(() => {
    submitted.value = true
  }, 1000)
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
</style>
