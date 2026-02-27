<template>
  <div class="testimonial-card">
    <div class="testimonial-rating">
      <svg v-for="n in 5" :key="n" class="star-icon" width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
    </div>
    <p class="testimonial-text">"{{ text }}"</p>
    <div class="testimonial-author">
      <div class="author-avatar">{{ name.charAt(0) }}</div>
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
  background-color: $surface-1;
  border: 1px solid $surface-3;
  border-radius: 1rem;
  padding: $spacing-lg;
  transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);

  &:hover {
    border-color: rgba($lime, 0.15);
  }
}

.testimonial-rating {
  display: flex;
  gap: 2px;
  color: $lime;
}

.testimonial-text {
  font-size: 1rem;
  font-style: italic;
  color: rgba($smoke, 0.85);
  line-height: 1.7;
  flex-grow: 1;
}

.testimonial-author {
  display: flex;
  align-items: center;
  gap: $spacing-sm;
  padding-top: $spacing-md;
  border-top: 1px solid $surface-3;
}

.author-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background-color: rgba($lime, 0.1);
  color: $lime;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 0.875rem;
  flex-shrink: 0;
}

.author-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.author-name {
  color: $smoke;
  font-weight: 600;
  font-size: 0.875rem;
}

.author-meta {
  color: $stone;
  font-size: 0.8125rem;
}
</style>
