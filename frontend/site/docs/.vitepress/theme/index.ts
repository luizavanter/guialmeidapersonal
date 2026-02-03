import DefaultTheme from 'vitepress/theme'
import './styles/custom.scss'
import Hero from './components/Hero.vue'
import ServiceCard from './components/ServiceCard.vue'
import TestimonialCard from './components/TestimonialCard.vue'
import ContactForm from './components/ContactForm.vue'
import LanguageSwitcher from './components/LanguageSwitcher.vue'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('Hero', Hero)
    app.component('ServiceCard', ServiceCard)
    app.component('TestimonialCard', TestimonialCard)
    app.component('ContactForm', ContactForm)
    app.component('LanguageSwitcher', LanguageSwitcher)
  }
}
