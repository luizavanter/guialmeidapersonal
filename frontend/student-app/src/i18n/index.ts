import { createI18n } from 'vue-i18n'
import ptBR from './locales/pt-BR'
import enUS from './locales/en-US'

const i18n = createI18n({
  legacy: false,
  locale: localStorage.getItem('ga_locale') || 'pt-BR',
  fallbackLocale: 'en-US',
  messages: {
    'pt-BR': ptBR,
    'en-US': enUS,
  },
})

export default i18n
