<template>
  <div class="testimonial-card card">
    <div class="testimonial-rating">
      <span v-for="n in 5" :key="n">⭐</span>
    </div>
    <p class="testimonial-text">"{{ text }}"</p>
    <div class="testimonial-author">
      <div class="author-info">
        <strong class="author-name">{{ name }}</strong>
        <span class="author-meta">{{ meta }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  text: string
  name: string
  meta: string
}>()
</script>

<style scoped lang="scss">
@import '../styles/variables.scss';

.testimonial-card {
  display: flex;
  flex-direction: column;
  gap: $spacing-md;
}

.testimonial-rating {
  color: $lime;
  font-size: 1.2rem;
  letter-spacing: 0.2rem;
}

.testimonial-text {
  font-size: 1.1rem;
  font-style: italic;
  color: rgba($smoke, 0.9);
  line-height: 1.7;
  flex-grow: 1;
}

.testimonial-author {
  display: flex;
  align-items: center;
  gap: $spacing-md;
  padding-top: $spacing-md;
  border-top: 1px solid rgba($smoke, 0.1);
}

.author-info {
  display: flex;
  flex-direction: column;
  gap: $spacing-xs / 2;
}

.author-name {
  color: $lime;
  font-weight: 600;
  font-size: 1rem;
}

.author-meta {
  color: rgba($smoke, 0.6);
  font-size: 0.9rem;
}
