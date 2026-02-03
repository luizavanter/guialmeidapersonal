<script setup lang="ts">
import { ref } from 'vue'
import { RouterView } from 'vue-router'
import Sidebar from './Sidebar.vue'
import Topbar from './Topbar.vue'

const sidebarOpen = ref(true)

function toggleSidebar() {
  sidebarOpen.value = !sidebarOpen.value
}
</script>

<template>
  <div class="flex h-screen bg-coal">
    <Sidebar :open="sidebarOpen" @toggle="toggleSidebar" />

    <div class="flex-1 flex flex-col overflow-hidden">
      <Topbar @toggle-sidebar="toggleSidebar" />

      <main class="flex-1 overflow-y-auto p-6">
        <RouterView />
      </main>
    </div>
  </div>
</template>
