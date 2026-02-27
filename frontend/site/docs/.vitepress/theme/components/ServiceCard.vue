<template>
  <div class="service-card">
    <div class="service-body">
      <h3>{{ title }}</h3>
      <p class="service-description">{{ description }}</p>
    </div>
    <ul class="service-features">
      <li v-for="(feature, index) in features" :key="index">{{ feature }}</li>
    </ul>
    <a v-if="link" :href="link" class="service-link">
      {{ linkText }} <span class="arrow">→</span>
    </a>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  icon?: string
  title: string
  description: string
  features: string[]
  link?: string
  linkText?: string
}>()
</script>

<style scoped lang="scss">
@import '../styles/variables.scss';

.service-card {
  display: flex;
  flex-direction: column;
  background-color: $surface-1;
  border: 1px solid $surface-3;
  border-radius: 1rem;
  padding: $spacing-lg;
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);

  &:hover {
    border-color: rgba($lime, 0.2);
    transform: translateY(-2px);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);

    .service-link .arrow {
      transform: translateX(4px);
    }
  }
}

.service-body {
  margin-bottom: $spacing-md;
}

h3 {
  font-family: $font-display;
  font-weight: 600;
  font-size: 1.25rem;
  color: $smoke;
  margin-bottom: $spacing-xs;
  letter-spacing: -0.01em;
}

.service-description {
  color: $stone;
  font-size: 0.9375rem;
  line-height: 1.5;
}

.service-features {
  list-style: none;
  padding: 0;
  margin: 0 0 $spacing-md 0;
  flex-grow: 1;

  li {
    padding: $spacing-xs 0;
    padding-left: $spacing-md;
    position: relative;
    color: rgba($smoke, 0.85);
    font-size: 0.875rem;

    &::before {
      content: '';
      position: absolute;
      left: 0;
      top: 50%;
      transform: translateY(-50%);
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background-color: $lime;
    }
  }
}

.service-link {
  color: $lime;
  text-decoration: none;
  font-weight: 600;
  font-size: 0.875rem;
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  transition: color 0.2s ease;

  .arrow {
    transition: transform 0.2s ease;
    display: inline-block;
  }

  &:hover {
    color: lighten($lime, 10%);
  }
}
</style>
