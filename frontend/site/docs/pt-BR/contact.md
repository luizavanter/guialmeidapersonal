---
title: Contato
description: Entre em contato para agendar sua avaliação gratuita
---

<div class="page-header">
<p class="section-label">Contato</p>
<h1>Entre em Contato</h1>
<p class="page-lead">Pronto para começar sua transformação? Agende uma avaliação gratuita e vamos descobrir qual programa é perfeito para você.</p>
</div>

<div class="contact-grid">
<div class="contact-info">
<h2>Informações</h2>
<div class="info-list">
<div class="info-item">
<h3>Localização</h3>
<p>Jurerê, Florianópolis/SC<br>Atendimento em estúdio parceiro ou residência</p>
</div>
<div class="info-item">
<h3>WhatsApp</h3>
<p><a href="/pt-BR/contact">Entre em contato pelo formulário</a></p>
</div>
<div class="info-item">
<h3>E-mail</h3>
<p><a href="mailto:contato@gapersonal.com.br">contato@gapersonal.com.br</a></p>
</div>
<div class="info-item">
<h3>Redes Sociais</h3>
<p><a href="https://instagram.com/gapersonal" target="_blank">Instagram</a> · <a href="https://facebook.com/gapersonal" target="_blank">Facebook</a></p>
</div>
</div>
<div class="schedule-card">
<h3>Horário de Atendimento</h3>
<div class="schedule-row">
<span>Segunda a Sexta</span>
<span>6h — 21h</span>
</div>
<div class="schedule-row">
<span>Sábado</span>
<span>7h — 12h</span>
</div>
<div class="schedule-row">
<span>Domingo</span>
<span>Fechado</span>
</div>
</div>
</div>
<div class="contact-form-section">
<h2>Solicitar Avaliação Gratuita</h2>
<p class="form-subtitle">Preencha o formulário abaixo e entrarei em contato em até 24 horas.</p>

<ContactForm :labels="{ name: 'Nome Completo', email: 'E-mail', phone: 'Telefone (WhatsApp)', goal: 'Objetivo Principal', message: 'Mensagem' }" :placeholders="{ name: 'Seu nome completo', email: 'seu@email.com', phone: '(48) 99999-9999', goal: 'Selecione seu objetivo', message: 'Conte um pouco sobre sua rotina...' }" :goalOptions="[{ value: 'weight_loss', label: 'Emagrecimento' }, { value: 'muscle_gain', label: 'Ganho de Massa Muscular' }, { value: 'hybrid', label: 'Treinamento Híbrido' }, { value: 'conditioning', label: 'Condicionamento Físico' }, { value: 'other', label: 'Outro' }]" submitText="Enviar Solicitação" successMessage="Obrigado! Sua solicitação foi enviada." loadingText="Enviando..." errorText="Erro ao enviar. Tente novamente." locale="pt" />

</div>
</div>

<div class="faq-section">
<div class="container">
<p class="section-label" style="text-align: center;">FAQ</p>
<h2 style="text-align: center; color: #F5F5F0;">Perguntas Frequentes</h2>
<div class="faq-grid">
<div class="faq-item">
<h3>A avaliação inicial é realmente gratuita?</h3>
<p>Sim! A primeira avaliação não tem nenhum custo. É uma oportunidade para nos conhecermos e descobrirmos se há compatibilidade para trabalharmos juntos.</p>
</div>
<div class="faq-item">
<h3>Onde são realizados os treinos?</h3>
<p>Atendo em estúdios parceiros em Jurerê e também faço atendimento em residências. A localização é definida na avaliação inicial.</p>
</div>
<div class="faq-item">
<h3>Preciso ter experiência com exercícios?</h3>
<p>Não! Atendo desde iniciantes completos até atletas avançados. O programa é totalmente personalizado para seu nível atual.</p>
</div>
<div class="faq-item">
<h3>Como funciona o pagamento?</h3>
<p>O pagamento é mensal, via PIX ou transferência bancária. Existe desconto de 10% para pagamento trimestral à vista.</p>
</div>
<div class="faq-item">
<h3>Posso cancelar a qualquer momento?</h3>
<p>Sim. Não há fidelidade. Se desejar cancelar, basta avisar com 30 dias de antecedência.</p>
</div>
<div class="faq-item">
<h3>Você dá orientação nutricional?</h3>
<p>Sim, forneço orientações básicas sobre nutrição esportiva. Para planos alimentares detalhados, trabalho em parceria com nutricionistas.</p>
</div>
<div class="faq-item">
<h3>Quanto tempo para ver resultados?</h3>
<p>Com dedicação, os primeiros resultados aparecem em 4-6 semanas. Resultados significativos geralmente são visíveis em 3 meses.</p>
</div>
<div class="faq-item">
<h3>Atende fora de Jurerê?</h3>
<p>Meu foco é Jurerê e região próxima. Para outras localidades, ofereço consultoria online com programação de treinos e acompanhamento remoto.</p>
</div>
</div>
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

/* Contact Grid */
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

/* Schedule Card */
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

/* Form */
.form-subtitle {
  color: rgba(245, 245, 240, 0.6);
  margin-bottom: 1.5rem;
  font-size: 0.9375rem;
}

/* FAQ Section */
.faq-section {
  padding: 4rem 0;
  border-top: 1px solid #1C1C1C;
}

.faq-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.25rem;
  margin-top: 2.5rem;
}

.faq-item {
  background-color: #111111;
  border: 1px solid #1C1C1C;
  border-radius: 0.75rem;
  padding: 1.5rem;
  transition: border-color 0.25s ease;
}

.faq-item:hover {
  border-color: rgba(205, 250, 62, 0.15);
}

.faq-item h3 {
  font-family: 'Space Grotesk', sans-serif;
  font-weight: 600;
  font-size: 1rem;
  color: #F5F5F0;
  margin-bottom: 0.75rem;
}

.faq-item p {
  color: rgba(245, 245, 240, 0.65);
  margin: 0;
  line-height: 1.6;
  font-size: 0.9375rem;
}

@media (min-width: 768px) {
  .contact-grid {
    grid-template-columns: 0.8fr 1.2fr;
  }
}
</style>
