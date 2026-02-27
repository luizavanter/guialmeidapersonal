---
layout: home
title: GA Personal - Personal Trainer in Jurerê, Florianópolis
description: Personalized training with Guilherme Almeida. Over 20 years transforming lives through fitness in Jurerê, Florianópolis/SC.
---

<Hero
  title="Transform Your Body, Transform Your Life"
  subtitle="Personalized training with Guilherme Almeida. Over 20 years of experience helping you achieve your fitness goals in Jurerê, Florianópolis/SC."
  primaryCta="Schedule Your Assessment"
  primaryCtaLink="/en-US/contact"
  secondaryCta="View Services"
  secondaryCtaLink="/en-US/services"
  image="/images/guilherme-hero.jpg"
  imageAlt="Guilherme Almeida - Personal Trainer"
/>

<div class="section">
<div class="container">

<div class="stats-row">
<div class="stat-item">
<span class="stat-number">20+</span>
<span class="stat-label">Years of Experience</span>
</div>
<div class="stat-divider"></div>
<div class="stat-item">
<span class="stat-number">500+</span>
<span class="stat-label">Lives Transformed</span>
</div>
<div class="stat-divider"></div>
<div class="stat-item">
<span class="stat-number">98%</span>
<span class="stat-label">Satisfaction Rate</span>
</div>
</div>

</div>
</div>

<div class="section section-alt">
<div class="container">
<div class="split-layout">
<div class="split-content">
<p class="section-label">Services</p>
<h2>Programs Designed For You</h2>
<p class="section-text">Each program is created specifically for your needs, goals, and routine. Nothing is generic — everything is designed for your results.</p>
<a href="/en-US/services" class="btn btn-primary" style="margin-top: 1.5rem;">View All Services</a>
</div>
<div class="split-cards">

<ServiceCard title="Hybrid Training" description="Combine strength and cardio for maximum results" :features="['Weight Training + HIIT', 'Smart periodization', 'Adapted to your level']" link="/en-US/services#hybrid" linkText="Learn more" />

<ServiceCard title="Weight Loss" description="Lose weight in a healthy and sustainable way" :features="['Personalized training', 'Nutritional guidance', 'Weekly monitoring']" link="/en-US/services#weight-loss" linkText="Learn more" />

<ServiceCard title="Muscle Gain" description="Build muscle and define your body" :features="['Hypertrophy training', 'Load progression', 'Advanced techniques']" link="/en-US/services#muscle-gain" linkText="Learn more" />

</div>
</div>
</div>
</div>

<div class="section">
<div class="container">
<div class="text-center" style="margin-bottom: 3rem;">
<p class="section-label" style="text-align: center;">Testimonials</p>
<h2>What My Students Say</h2>
</div>
<div class="grid grid-3">

<TestimonialCard text="I lost 18kg in 6 months with Guilherme. His methodology is incredible and the follow-up is very close. Highly recommend!" name="Mariana Silva" meta="Weight Loss | 6 months" />

<TestimonialCard text="At 45 I thought I couldn't gain muscle. With GA Personal I not only gained muscle but greatly improved my overall health." name="Roberto Santos" meta="Muscle Gain | 8 months" />

<TestimonialCard text="Hybrid training changed my life! I got stronger, faster and with much more energy. Gui is an excellent professional." name="Juliana Costa" meta="Hybrid Training | 1 year" />

</div>
</div>
</div>

<div class="section cta-section">
<div class="container text-center">
<h2 style="color: #F5F5F0;">Ready to Get Started?</h2>
<p style="max-width: 600px; margin: 0 auto 2rem; font-size: 1.125rem; color: rgba(245, 245, 240, 0.8);">Schedule a free assessment and discover how I can help you achieve your goals</p>
<div style="display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap;">
<a href="/en-US/contact" class="btn btn-primary" style="font-size: 1.05rem; padding: 0.875rem 2rem;">Schedule Free Assessment</a>
<a href="/en-US/about" class="btn btn-secondary" style="font-size: 1.05rem; padding: 0.875rem 2rem;">Meet Guilherme</a>
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
