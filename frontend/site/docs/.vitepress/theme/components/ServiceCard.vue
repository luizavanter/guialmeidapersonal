<template>
  <div class="service-card card">
    <div class="service-icon">{{ icon }}</div>
    <h3>{{ title }}</h3>
    <p class="service-description">{{ description }}</p>
    <ul class="service-features">
      <li v-for="(feature, index) in features" :key="index">{{ feature }}</li>
    </ul>
    <a v-if="link" :href="link" class="service-link">
      {{ linkText }} →
    </a>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  icon: string
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
  height: 100%;
}

.service-icon {
  font-size: 3rem;
  margin-bottom: $spacing-md;
  filter: grayscale(100%) brightness(1.5);
}

h3 {
  color: $lime;
  margin-bottom: $spacing-sm;
}

.service-description {
  color: rgba($smoke, 0.8);
  margin-bottom: $spacing-md;
  flex-grow: 1;
}

.service-features {
  list-style: none;
  padding: 0;
  margin: 0 0 $spacing-md 0;

  li {
    padding: $spacing-xs 0;
    padding-left: $spacing-md;
    position: relative;
    color: rgba($smoke, 0.9);

    &::before {
      content: '✓';
      position: absolute;
      left: 0;
      color: $lime;
      font-weight: bold;
    }
  }
}

.service-link {
  color: $ocean;
  text-decoration: none;
  font-weight: 600;
  transition: color 0.3s ease;

  &:hover {
    color: lighten($ocean, 10%);
  }
}
</style>
