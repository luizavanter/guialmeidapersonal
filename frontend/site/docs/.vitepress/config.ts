import { defineConfig } from 'vitepress'

const ptBRConfig = {
  lang: 'pt-BR',
  title: 'GA Personal',
  description: 'Treinamento personalizado em Jurerê, Florianópolis/SC com Guilherme Almeida',
  themeConfig: {
    nav: [
      { text: 'Início', link: '/pt-BR/' },
      { text: 'Sobre', link: '/pt-BR/about' },
      { text: 'Serviços', link: '/pt-BR/services' },
      { text: 'Blog', link: '/pt-BR/blog/' },
      { text: 'Contato', link: '/pt-BR/contact' }
    ],
    sidebar: {
      '/pt-BR/blog/': [
        {
          text: 'Posts Recentes',
          items: [
            { text: 'Treinamento Híbrido: O Melhor dos Dois Mundos', link: '/pt-BR/blog/hybrid-training' },
            { text: '5 Erros Comuns na Perda de Peso', link: '/pt-BR/blog/weight-loss-mistakes' },
            { text: 'Ganho de Massa Muscular Após os 40', link: '/pt-BR/blog/muscle-gain-over-40' },
            { text: 'Importância da Nutrição no Treino', link: '/pt-BR/blog/nutrition-importance' },
            { text: 'Como Manter a Consistência no Treino', link: '/pt-BR/blog/training-consistency' }
          ]
        }
      ]
    },
    footer: {
      message: 'GA Personal - Transformando vidas através do fitness',
      copyright: 'Copyright © 2026 Guilherme Almeida Personal Trainer'
    }
  }
}

const enUSConfig = {
  lang: 'en-US',
  title: 'GA Personal',
  description: 'Personalized training in Jurerê, Florianópolis/SC with Guilherme Almeida',
  themeConfig: {
    nav: [
      { text: 'Home', link: '/en-US/' },
      { text: 'About', link: '/en-US/about' },
      { text: 'Services', link: '/en-US/services' },
      { text: 'Blog', link: '/en-US/blog/' },
      { text: 'Contact', link: '/en-US/contact' }
    ],
    sidebar: {},
    footer: {
      message: 'GA Personal - Transforming lives through fitness',
      copyright: 'Copyright © 2026 Guilherme Almeida Personal Trainer'
    }
  }
}

export default defineConfig({
  title: 'GA Personal',
  description: 'Treinamento personalizado em Jurerê, Florianópolis/SC',
  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: '/favicon.svg' }],
    ['meta', { name: 'theme-color', content: '#C4F53A' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:locale', content: 'pt_BR' }],
    ['meta', { property: 'og:site_name', content: 'GA Personal' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['link', { rel: 'preconnect', href: 'https://fonts.googleapis.com' }],
    ['link', { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' }],
    ['link', { href: 'https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Outfit:wght@300;400;500;600;700&display=swap', rel: 'stylesheet' }]
  ],

  locales: {
    'pt-BR': { label: 'Português', ...ptBRConfig },
    'en-US': { label: 'English', ...enUSConfig }
  },

  themeConfig: {
    logo: '/images/logo.svg',
    socialLinks: [
      { icon: 'instagram', link: 'https://instagram.com/gapersonal' },
      { icon: 'facebook', link: 'https://facebook.com/gapersonal' }
    ]
  },

  vite: {
    css: {
      preprocessorOptions: {
        scss: {
          additionalData: `@import "./docs/.vitepress/theme/styles/variables.scss";`
        }
      }
    }
  }
})
