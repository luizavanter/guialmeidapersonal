import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createI18n } from '@ga-personal/shared'
import App from './App.vue'
import router from './router'
import './assets/main.css'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(createI18n())

app.mount('#app')
