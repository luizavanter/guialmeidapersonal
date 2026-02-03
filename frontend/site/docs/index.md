---
layout: home
---

<script setup>
import { onMounted } from 'vue'

onMounted(() => {
  // Detect browser language and redirect
  const browserLang = navigator.language || navigator.userLanguage
  const lang = browserLang.startsWith('pt') ? 'pt-BR' : 'en-US'
  window.location.href = `/${lang}/`
})
</script>

# GA Personal

Redirecionando... / Redirecting...
