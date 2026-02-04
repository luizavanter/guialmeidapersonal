---
title: Contact
description: Get in touch to schedule your free assessment
---

# Get in Touch

<div class="accent-line"></div>

<p class="lead">
  Ready to start your transformation? Schedule a free assessment and let's find out which program is perfect for you.
</p>

<div class="contact-grid">
  <div class="contact-info">
    <h2>Contact Information</h2>

    <div class="info-item">
      <div class="info-icon">📍</div>
      <div class="info-content">
        <h3>Location</h3>
        <p>Jurerê, Florianópolis/SC<br>
        Service at partner studio or residence</p>
      </div>
    </div>

    <div class="info-item">
      <div class="info-icon">📱</div>
      <div class="info-content">
        <h3>WhatsApp</h3>
        <p><a href="/en-US/contact">Contact us through the form</a></p>
      </div>
    </div>

    <div class="info-item">
      <div class="info-icon">📧</div>
      <div class="info-content">
        <h3>Email</h3>
        <p><a href="mailto:contato@gapersonal.com.br">contato@gapersonal.com.br</a></p>
      </div>
    </div>

    <div class="info-item">
      <div class="info-icon">📸</div>
      <div class="info-content">
        <h3>Social Media</h3>
        <p>
          <a href="https://instagram.com/gapersonal" target="_blank">Instagram</a> |
          <a href="https://facebook.com/gapersonal" target="_blank">Facebook</a>
        </p>
      </div>
    </div>

    <div class="schedule-info">
      <h3>Business Hours</h3>
      <ul>
        <li><strong>Monday to Friday:</strong> 6am - 9pm</li>
        <li><strong>Saturday:</strong> 7am - 12pm</li>
        <li><strong>Sunday:</strong> Closed</li>
      </ul>
    </div>
  </div>

  <div class="contact-form-section">
    <h2>Request Free Assessment</h2>
    <p>Fill out the form below and I will contact you within 24 hours.</p>

    <ContactForm
      :labels="{
        name: 'Full Name',
        email: 'Email',
        phone: 'Phone (WhatsApp)',
        goal: 'Main Goal',
        message: 'Message'
      }"
      :placeholders="{
        name: 'Your full name',
        email: 'your@email.com',
        phone: '+55 (48) 99999-9999',
        goal: 'Select your goal',
        message: 'Tell me about your routine, exercise experience and what you expect from training...'
      }"
      :goalOptions="[
        { value: 'weight-loss', label: 'Weight Loss' },
        { value: 'muscle-gain', label: 'Muscle Gain' },
        { value: 'hybrid', label: 'Hybrid Training' },
        { value: 'conditioning', label: 'Physical Conditioning' },
        { value: 'other', label: 'Other' }
      ]"
      submitText="Send Request"
      successMessage="Thank you! Your request has been sent. I will contact you soon."
    />
  </div>
</div>

<style scoped>
.lead {
  font-size: 1.2rem;
  line-height: 1.7;
  color: rgba(245, 245, 240, 0.9);
  margin-bottom: 3rem;
}

.contact-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 3rem;
  margin-bottom: 4rem;
}

@media (min-width: 768px) {
  .contact-grid {
    grid-template-columns: 1fr 1.5fr;
  }
}

.contact-info h2,
.contact-form-section h2 {
  color: #C4F53A;
  margin-bottom: 2rem;
}

.info-item {
  display: flex;
  gap: 1.5rem;
  margin-bottom: 2rem;
  align-items: flex-start;
}

.info-icon {
  font-size: 2rem;
  flex-shrink: 0;
}

.info-content h3 {
  color: #0EA5E9;
  font-size: 1.1rem;
  margin-bottom: 0.5rem;
}

.info-content p {
  color: rgba(245, 245, 240, 0.85);
  margin: 0;
}

.info-content a {
  color: #0EA5E9;
  text-decoration: none;
  transition: color 0.3s ease;
}

.info-content a:hover {
  color: #C4F53A;
}

.schedule-info {
  background: rgba(196, 245, 58, 0.05);
  padding: 1.5rem;
  border-radius: 8px;
  border-left: 4px solid #C4F53A;
  margin-top: 2rem;
}

.schedule-info h3 {
  color: #C4F53A;
  margin-top: 0;
  margin-bottom: 1rem;
}

.schedule-info ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.schedule-info li {
  padding: 0.5rem 0;
  color: rgba(245, 245, 240, 0.85);
}

.contact-form-section p {
  color: rgba(245, 245, 240, 0.8);
  margin-bottom: 2rem;
}
</style>
