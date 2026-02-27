<template>
  <div class="hero-section">
    <div class="hero-bg"></div>
    <div class="container">
      <div class="hero-grid">
        <div class="hero-content">
          <p class="hero-label">Personal Trainer | Jurerê, Florianópolis</p>
          <h1 class="hero-title">{{ title }}</h1>
          <p class="hero-subtitle">{{ subtitle }}</p>
          <div class="hero-cta">
            <a :href="primaryCtaLink" class="btn btn-primary">{{ primaryCta }}</a>
            <a :href="secondaryCtaLink" class="btn btn-secondary">{{ secondaryCta }}</a>
          </div>
        </div>
        <div class="hero-image">
          <div class="hero-image-frame">
            <img :src="image" :alt="imageAlt" />
          </div>
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
  min-height: 85vh;
  display: flex;
  align-items: center;
  position: relative;
  overflow: hidden;
  padding: 6rem 0 $spacing-2xl;
}

.hero-bg {
  position: absolute;
  inset: 0;
  background: radial-gradient(ellipse 70% 50% at 70% 40%, rgba($lime, 0.04), transparent 70%);
  pointer-events: none;
}

.hero-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: $spacing-xl;
  align-items: center;

  @media (min-width: $breakpoint-md) {
    grid-template-columns: 1.1fr 0.9fr;
    gap: 4rem;
  }
}

.hero-content {
  z-index: 1;
}

.hero-label {
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  color: $lime;
  margin-bottom: $spacing-md;
}

.hero-title {
  font-family: $font-display;
  font-weight: 700;
  font-size: clamp(2.5rem, 5.5vw, 4rem);
  line-height: 1.05;
  letter-spacing: -0.03em;
  color: $smoke;
  margin-bottom: $spacing-md;
}

.hero-subtitle {
  font-size: 1.125rem;
  color: $stone;
  margin-bottom: $spacing-xl;
  line-height: 1.7;
  max-width: 520px;
}

.hero-cta {
  display: flex;
  gap: $spacing-md;
  flex-wrap: wrap;
}

.hero-image {
  position: relative;
  z-index: 1;

  @media (max-width: $breakpoint-md) {
    display: none;
  }
}

.hero-image-frame {
  position: relative;
  border-radius: 1rem;
  overflow: hidden;

  &::after {
    content: '';
    position: absolute;
    inset: 0;
    border: 1px solid rgba($lime, 0.15);
    border-radius: 1rem;
    pointer-events: none;
  }

  img {
    width: 100%;
    height: auto;
    display: block;
    border-radius: 1rem;
  }
}
</style>
