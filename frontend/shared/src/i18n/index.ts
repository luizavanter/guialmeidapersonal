import { createI18n as createVueI18n } from 'vue-i18n'
import ptBR from './locales/pt-BR.json'
import enUS from './locales/en-US.json'

export function createI18n() {
  return createVueI18n({
    legacy: false,
    locale: localStorage.getItem('locale') || 'pt-BR',
    fallbackLocale: 'en-US',
    messages: {
      'pt-BR': ptBR,
      'en-US': enUS,
    },
  })
}

export { ptBR, enUS }
