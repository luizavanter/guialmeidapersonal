---
layout: home
title: GA Personal - Personal Trainer em Jurerê, Florianópolis
description: Treinamento personalizado com Guilherme Almeida. Mais de 20 anos transformando vidas através do fitness em Jurerê, Florianópolis/SC.
---

<Hero
  title="Transforme Seu Corpo, Transforme Sua Vida"
  subtitle="Treinamento personalizado com Guilherme Almeida. Mais de 20 anos de experiência ajudando você a alcançar seus objetivos de fitness em Jurerê, Florianópolis/SC."
  primaryCta="Agende Sua Avaliação"
  primaryCtaLink="/pt-BR/contact"
  secondaryCta="Conheça os Serviços"
  secondaryCtaLink="/pt-BR/services"
  image="/images/guilherme-hero.jpg"
  imageAlt="Guilherme Almeida - Personal Trainer"
/>

<div class="section">
<div class="container">

<div class="stats-row">
<div class="stat-item">
<span class="stat-number">20+</span>
<span class="stat-label">Anos de Experiência</span>
</div>
<div class="stat-divider"></div>
<div class="stat-item">
<span class="stat-number">500+</span>
<span class="stat-label">Alunos Transformados</span>
</div>
<div class="stat-divider"></div>
<div class="stat-item">
<span class="stat-number">98%</span>
<span class="stat-label">Taxa de Satisfação</span>
</div>
</div>

</div>
</div>

<div class="section section-alt">
<div class="container">
<div class="split-layout">
<div class="split-content">
<p class="section-label">Serviços</p>
<h2>Programas Desenvolvidos Para Você</h2>
<p class="section-text">Cada programa é criado especificamente para suas necessidades, objetivos e rotina. Nada é genérico — tudo é pensado para o seu resultado.</p>
<a href="/pt-BR/services" class="btn btn-primary" style="margin-top: 1.5rem;">Ver Todos os Serviços</a>
</div>
<div class="split-cards">

<ServiceCard title="Treinamento Híbrido" description="Combine força e cardio para resultados máximos" :features="['Musculação + HIIT', 'Periodização inteligente', 'Adaptado ao seu nível']" link="/pt-BR/services#hybrid" linkText="Saiba mais" />

<ServiceCard title="Emagrecimento" description="Perca peso de forma saudável e sustentável" :features="['Treino personalizado', 'Orientação nutricional', 'Acompanhamento semanal']" link="/pt-BR/services#weight-loss" linkText="Saiba mais" />

<ServiceCard title="Ganho de Massa" description="Construa músculos e defina seu corpo" :features="['Treino de hipertrofia', 'Progressão de carga', 'Técnicas avançadas']" link="/pt-BR/services#muscle-gain" linkText="Saiba mais" />

</div>
</div>
</div>
</div>

<div class="section">
<div class="container">
<div class="text-center" style="margin-bottom: 3rem;">
<p class="section-label" style="text-align: center;">Depoimentos</p>
<h2>O Que Meus Alunos Dizem</h2>
</div>
<div class="grid grid-3">

<TestimonialCard text="Perdi 18kg em 6 meses com o Guilherme. A metodologia dele é incrível e o acompanhamento é super próximo. Recomendo muito!" name="Mariana Silva" meta="Emagrecimento | 6 meses" />

<TestimonialCard text="Aos 45 anos achei que não conseguiria ganhar massa muscular. Com o GA Personal não só ganhei músculos como melhorei muito minha saúde geral." name="Roberto Santos" meta="Ganho de Massa | 8 meses" />

<TestimonialCard text="O treinamento híbrido mudou minha vida! Fiquei mais forte, mais rápida e com muito mais disposição. O Gui é um excelente profissional." name="Juliana Costa" meta="Treinamento Híbrido | 1 ano" />

</div>
</div>
</div>

<div class="section cta-section">
<div class="container text-center">
<h2 style="color: #F5F5F0;">Pronto Para Começar?</h2>
<p style="max-width: 600px; margin: 0 auto 2rem; font-size: 1.125rem; color: rgba(245, 245, 240, 0.8);">Agende uma avaliação gratuita e descubra como posso ajudar você a alcançar seus objetivos</p>
<div style="display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap;">
<a href="/pt-BR/contact" class="btn btn-primary" style="font-size: 1.05rem; padding: 0.875rem 2rem;">Agendar Avaliação Gratuita</a>
<a href="/pt-BR/about" class="btn btn-secondary" style="font-size: 1.05rem; padding: 0.875rem 2rem;">Conhecer Guilherme</a>
</div>
</div>
</div>

<style scoped>
.section {
  padding: 5rem 0;
}

.section-alt {
  background-color: rgba(17, 17, 17, 0.6);
}

.section-label {
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  color: #CDFA3E;
  margin-bottom: 0.75rem;
}

.section-text {
  font-size: 1.125rem;
  color: rgba(245, 245, 240, 0.7);
  line-height: 1.7;
  max-width: 440px;
}

/* Stats Row */
.stats-row {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 3rem;
  padding: 3rem 0;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.stat-number {
  font-family: 'Space Grotesk', sans-serif;
  font-size: clamp(2.5rem, 5vw, 3.5rem);
  font-weight: 700;
  color: #CDFA3E;
  letter-spacing: -0.03em;
  line-height: 1;
}

.stat-label {
  font-size: 0.875rem;
  color: #8A8578;
  font-weight: 500;
  letter-spacing: 0.02em;
}

.stat-divider {
  width: 1px;
  height: 48px;
  background: linear-gradient(to bottom, transparent, #1C1C1C, transparent);
}

/* Split Layout */
.split-layout {
  display: grid;
  grid-template-columns: 1fr;
  gap: 3rem;
  align-items: start;
}

.split-cards {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

/* CTA Section */
.cta-section {
  background: linear-gradient(135deg, #0A0A0A 0%, #111111 100%);
  border-top: 1px solid #1C1C1C;
}

@media (min-width: 768px) {
  .split-layout {
    grid-template-columns: 1fr 1.2fr;
    gap: 4rem;
  }

  .split-content {
    position: sticky;
    top: 6rem;
  }
}

@media (max-width: 640px) {
  .stats-row {
    flex-direction: column;
    gap: 2rem;
  }

  .stat-divider {
    width: 48px;
    height: 1px;
  }

  .section {
    padding: 3rem 0;
  }
}
</style>
