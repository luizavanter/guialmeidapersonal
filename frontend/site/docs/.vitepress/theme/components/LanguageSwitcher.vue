<template>
  <div class="language-switcher">
    <button
      v-for="locale in locales"
      :key="locale.code"
      :class="['lang-btn', { active: isActive(locale.code) }]"
      @click="switchLanguage(locale.code)"
    >
      {{ locale.label }}
    </button>
  </div>
</template>

<script setup lang="ts">
import { useData, useRouter } from 'vitepress'
import { computed } from 'vue'

const { lang } = useData()
const router = useRouter()

const locales = [
  { code: 'pt-BR', label: 'PT' },
  { code: 'en-US', label: 'EN' }
]

const isActive = (code: string) => {
  return lang.value === code
}

const switchLanguage = (code: string) => {
  const currentPath = router.route.path
  const currentLang = lang.value

  // Replace language in path
  let newPath = currentPath.replace(`/${currentLang}/`, `/${code}/`)

  // If at root, redirect to language root
  if (currentPath === '/' || currentPath === `/${currentLang}` || currentPath === `/${currentLang}/`) {
    newPath = `/${code}/`
  }

  router.go(newPath)
}
</script>

<style scoped lang="scss">
@import '../styles/variables.scss';

.language-switcher {
  display: flex;
  gap: $spacing-xs;
  align-items: center;
}

.lang-btn {
  padding: $spacing-xs $spacing-sm;
  background-color: transparent;
  border: 2px solid rgba($smoke, 0.3);
  border-radius: 6px;
  color: rgba($smoke, 0.7);
  font-family: $font-body;
  font-weight: 600;
  font-size: 0.85rem;
  cursor: pointer;
  transition: all 0.3s ease;

  &:hover {
    border-color: $lime;
    color: $lime;
  }

  &.active {
    background-color: $lime;
    border-color: $lime;
    color: $coal;
  }
}
</style>
