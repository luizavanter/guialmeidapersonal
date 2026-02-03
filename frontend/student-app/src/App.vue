<template>
  <div id="app">
    <router-view />
    <Toast />
  </div>
</template>

<script setup lang="ts">
import Toast from '@/components/ui/Toast.vue'
</script>

<style>
#app {
  min-height: 100vh;
  font-family: 'Outfit', sans-serif;
}
</style>
