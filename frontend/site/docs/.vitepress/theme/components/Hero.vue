<template>
  <div class="hero-section">
    <div class="container">
      <div class="hero-grid">
        <div class="hero-content">
          <h1 class="hero-title">
            <span class="display-text">{{ title }}</span>
          </h1>
          <div class="accent-line"></div>
          <p class="hero-subtitle">{{ subtitle }}</p>
          <div class="hero-cta">
            <a :href="primaryCtaLink" class="btn btn-primary">{{ primaryCta }}</a>
            <a :href="secondaryCtaLink" class="btn btn-secondary">{{ secondaryCta }}</a>
          </div>
        </div>
        <div class="hero-image">
          <img :src="image" :alt="imageAlt" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  title: string
  subtitle: string
  primaryCta: string
  primaryCtaLink: string
  secondaryCta: string
  secondaryCtaLink: string
  image: string
  imageAlt: string
}>()
</script>

<style scoped lang="scss">
@import '../styles/variables.scss';

.hero-section {
  min-height: 80vh;
  display: flex;
  align-items: center;
  background: linear-gradient(135deg, $coal 0%, lighten($coal, 8%) 100%);
  position: relative;
  overflow: hidden;
  padding: $spacing-2xl 0;

  &::before {
    content: '';
    position: absolute;
    top: 0;
    right: 0;
    width: 50%;
    height: 100%;
    background: radial-gradient(circle at top right, rgba($lime, 0.1), transparent 70%);
    pointer-events: none;
  }
}

.hero-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: $spacing-xl;
  align-items: center;

  @media (min-width: $breakpoint-md) {
    grid-template-columns: 1fr 1fr;
  }
}

.hero-content {
  z-index: 1;
}

.hero-title {
  background: linear-gradient(135deg, $lime 0%, $ocean 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: $spacing-md;
}

.hero-subtitle {
  font-size: 1.25rem;
  color: rgba($smoke, 0.9);
  margin-bottom: $spacing-lg;
  line-height: 1.6;
}

.hero-cta {
  display: flex;
  gap: $spacing-md;
  flex-wrap: wrap;
}

.hero-image {
  position: relative;
  z-index: 1;

  img {
    width: 100%;
    height: auto;
    border-radius: 16px;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
    border: 2px solid rgba($lime, 0.3);
  }
}
</style>
