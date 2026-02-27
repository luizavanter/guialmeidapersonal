---
title: Contact
description: Get in touch to schedule your free assessment
---

<div class="page-header">
<p class="section-label">Contact</p>
<h1>Get in Touch</h1>
<p class="page-lead">Ready to start your transformation? Schedule a free assessment and let's find out which program is perfect for you.</p>
</div>

<div class="contact-grid">
<div class="contact-info">
<h2>Information</h2>
<div class="info-list">
<div class="info-item">
<h3>Location</h3>
<p>Jurerê, Florianópolis/SC<br>Service at partner studio or residence</p>
</div>
<div class="info-item">
<h3>WhatsApp</h3>
<p><a href="/en-US/contact">Contact us through the form</a></p>
</div>
<div class="info-item">
<h3>Email</h3>
<p><a href="mailto:contato@gapersonal.com.br">contato@gapersonal.com.br</a></p>
</div>
<div class="info-item">
<h3>Social Media</h3>
<p><a href="https://instagram.com/gapersonal" target="_blank">Instagram</a> · <a href="https://facebook.com/gapersonal" target="_blank">Facebook</a></p>
</div>
</div>
<div class="schedule-card">
<h3>Business Hours</h3>
<div class="schedule-row">
<span>Monday to Friday</span>
<span>6am — 9pm</span>
</div>
<div class="schedule-row">
<span>Saturday</span>
<span>7am — 12pm</span>
</div>
<div class="schedule-row">
<span>Sunday</span>
<span>Closed</span>
</div>
</div>
</div>
<div class="contact-form-section">
<h2>Request Free Assessment</h2>
<p class="form-subtitle">Fill out the form below and I will contact you within 24 hours.</p>

<ContactForm :labels="{ name: 'Full Name', email: 'Email', phone: 'Phone (WhatsApp)', goal: 'Main Goal', message: 'Message' }" :placeholders="{ name: 'Your full name', email: 'your@email.com', phone: '+55 (48) 99999-9999', goal: 'Select your goal', message: 'Tell me about your routine and exercise experience...' }" :goalOptions="[{ value: 'weight_loss', label: 'Weight Loss' }, { value: 'muscle_gain', label: 'Muscle Gain' }, { value: 'hybrid', label: 'Hybrid Training' }, { value: 'conditioning', label: 'Physical Conditioning' }, { value: 'other', label: 'Other' }]" submitText="Send Request" successMessage="Thank you! Your request has been sent." loadingText="Sending..." errorText="Failed to send. Please try again." locale="en" />

</div>
</div>

<style scoped>
.page-header {
  max-width: 700px;
  margin-bottom: 4rem;
}

.section-label {
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  color: #CDFA3E;
  margin-bottom: 0.75rem;
}

.page-lead {
  font-size: 1.125rem;
  color: rgba(245, 245, 240, 0.7);
  line-height: 1.7;
}

.contact-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 3rem;
  margin-bottom: 4rem;
}

.contact-info h2,
.contact-form-section h2 {
  font-family: 'Space Grotesk', sans-serif;
  font-weight: 700;
  font-size: 1.5rem;
  color: #F5F5F0;
  margin-bottom: 1.5rem;
  letter-spacing: -0.02em;
}

.info-list {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.info-item {
  padding: 1rem 0;
  border-bottom: 1px solid #1C1C1C;
}

.info-item:first-child {
  padding-top: 0;
}

.info-item h3 {
  font-family: 'Space Grotesk', sans-serif;
  font-weight: 600;
  font-size: 0.75rem;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: #8A8578;
  margin-bottom: 0.375rem;
}

.info-item p {
  color: rgba(245, 245, 240, 0.85);
  margin: 0;
  font-size: 0.9375rem;
}

.info-item a {
  color: #CDFA3E;
  text-decoration: none;
  transition: opacity 0.2s ease;
}

.info-item a:hover {
  opacity: 0.8;
}

.schedule-card {
  background-color: #111111;
  border: 1px solid #1C1C1C;
  border-radius: 0.75rem;
  padding: 1.25rem;
  margin-top: 1.5rem;
}

.schedule-card h3 {
  font-family: 'Space Grotesk', sans-serif;
  font-weight: 600;
  font-size: 0.75rem;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: #8A8578;
  margin-top: 0;
  margin-bottom: 1rem;
}

.schedule-row {
  display: flex;
  justify-content: space-between;
  padding: 0.375rem 0;
  font-size: 0.9375rem;
  color: rgba(245, 245, 240, 0.8);
}

.form-subtitle {
  color: rgba(245, 245, 240, 0.6);
  margin-bottom: 1.5rem;
  font-size: 0.9375rem;
}

@media (min-width: 768px) {
  .contact-grid {
    grid-template-columns: 0.8fr 1.2fr;
  }
}
</style>
