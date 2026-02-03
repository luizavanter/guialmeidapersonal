<script setup lang="ts">
import { RouterView } from 'vue-router'
import { useAuth } from '@ga-personal/shared'

const { initAuth } = useAuth()
initAuth()
</script>

<template>
  <RouterView />
</template>

<style>
#app {
  @apply min-h-screen bg-coal text-smoke;
}
</style>
