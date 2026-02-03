# GA Personal - VitePress Marketing Site

Complete bilingual marketing website for GA Personal Training.

## Features

- Fully bilingual (PT-BR/EN-US) with language switcher
- Custom GA Personal design system (Coal, Lime, Ocean, Smoke)
- Responsive design
- SEO optimized
- Custom Vue components
- 5 comprehensive blog posts
- Contact form with Formspree integration

## Structure

```
docs/
├── .vitepress/
│   ├── config.ts          # Site configuration
│   └── theme/
│       ├── index.ts       # Custom theme
│       ├── components/    # Vue components
│       │   ├── Hero.vue
│       │   ├── ServiceCard.vue
│       │   ├── TestimonialCard.vue
│       │   ├── ContactForm.vue
│       │   └── LanguageSwitcher.vue
│       └── styles/
│           ├── variables.scss
│           └── custom.scss
├── pt-BR/                 # Portuguese content
│   ├── index.md          # Home
│   ├── about.md          # About Guilherme
│   ├── services.md       # Services & Pricing
│   ├── contact.md        # Contact form
│   └── blog/
│       ├── index.md
│       ├── hybrid-training.md
│       ├── weight-loss-mistakes.md
│       ├── muscle-gain-over-40.md
│       ├── nutrition-importance.md
│       └── training-consistency.md
└── en-US/                 # English content
    └── index.md          # (Additional pages to be created)
```

## Pages Created

### Portuguese (PT-BR) - Complete
1. **Home** - Hero, services overview, testimonials, CTAs
2. **About** - Guilherme's bio, credentials, 20+ years experience, philosophy
3. **Services** - Hybrid training, weight loss, muscle gain, packages/pricing
4. **Blog Index** - 5 blog posts listed
5. **Contact** - Form, info, FAQs

### Blog Posts (PT-BR)
1. Treinamento Híbrido: O Melhor dos Dois Mundos
2. 5 Erros Comuns na Perda de Peso
3. Ganho de Massa Muscular Após os 40
4. Importância da Nutrição no Treino
5. Como Manter a Consistência no Treino

### English (EN-US)
- Home page created
- Other pages to be translated

## Design System

### Colors
- **Coal** (#0A0A0A) - Backgrounds
- **Lime** (#C4F53A) - Primary CTAs
- **Ocean** (#0EA5E9) - Secondary, links
- **Smoke** (#F5F5F0) - Light text, cards

### Typography
- **Display**: Bebas Neue (impact headlines)
- **Body**: Outfit (comfortable reading)

### Components
- Hero - Full-width hero with image
- ServiceCard - Service descriptions with features
- TestimonialCard - Customer testimonials
- ContactForm - Contact/booking form
- LanguageSwitcher - PT/EN toggle

## Development

```bash
# Install dependencies
npm install

# Start dev server (port 3003)
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## TODO

- [ ] Add Guilherme's professional photo to `/docs/public/images/guilherme-hero.jpg`
- [ ] Add logo to `/docs/public/images/logo.svg`
- [ ] Update Formspree form ID in ContactForm.vue
- [ ] Create English translations for About, Services, Contact, Blog
- [ ] Add favicon
- [ ] Configure meta tags for SEO
- [ ] Add structured data for local business

## Contact Form Setup

The contact form uses Formspree. To activate:

1. Go to https://formspree.io
2. Create account and new form
3. Copy form ID
4. Update `ContactForm.vue` line 5:
   ```vue
   action="https://formspree.io/f/YOUR_FORM_ID"
   ```

## Deployment

Recommended: Deploy to Vercel or Netlify

```bash
# Build
npm run build

# Deploy dist/docs folder
```

## Key Content

- **Location**: Jurerê, Florianópolis/SC
- **Trainer**: Guilherme Almeida
- **Experience**: 20+ years
- **Specialties**: Hybrid training, weight loss, muscle gain
- **Target Market**: Local (Jurerê) + Portuguese/English speakers
