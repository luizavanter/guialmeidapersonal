---
title: Contato
description: Entre em contato para agendar sua avaliação gratuita
---

# Entre em Contato

<div class="accent-line"></div>

<p class="lead">Pronto para começar sua transformação? Agende uma avaliação gratuita e vamos descobrir qual programa é perfeito para você.</p>

<div class="contact-grid">
<div class="contact-info">
<h2>Informações de Contato</h2>
<div class="info-item">
<div class="info-icon">📍</div>
<div class="info-content">
<h3>Localização</h3>
<p>Jurerê, Florianópolis/SC<br>Atendimento em estúdio parceiro ou residência</p>
</div>
</div>
<div class="info-item">
<div class="info-icon">📱</div>
<div class="info-content">
<h3>WhatsApp</h3>
<p><a href="/pt-BR/contact">Entre em contato pelo formulário</a></p>
</div>
</div>
<div class="info-item">
<div class="info-icon">📧</div>
<div class="info-content">
<h3>E-mail</h3>
<p><a href="mailto:contato@gapersonal.com.br">contato@gapersonal.com.br</a></p>
</div>
</div>
<div class="info-item">
<div class="info-icon">📸</div>
<div class="info-content">
<h3>Redes Sociais</h3>
<p><a href="https://instagram.com/gapersonal" target="_blank">Instagram</a> | <a href="https://facebook.com/gapersonal" target="_blank">Facebook</a></p>
</div>
</div>
<div class="schedule-info">
<h3>Horário de Atendimento</h3>
<ul>
<li><strong>Segunda a Sexta:</strong> 6h às 21h</li>
<li><strong>Sábado:</strong> 7h às 12h</li>
<li><strong>Domingo:</strong> Fechado</li>
</ul>
</div>
</div>
<div class="contact-form-section">
<h2>Solicitar Avaliação Gratuita</h2>
<p>Preencha o formulário abaixo e entrarei em contato em até 24 horas.</p>

<ContactForm :labels="{ name: 'Nome Completo', email: 'E-mail', phone: 'Telefone (WhatsApp)', goal: 'Objetivo Principal', message: 'Mensagem' }" :placeholders="{ name: 'Seu nome completo', email: 'seu@email.com', phone: '(48) 99999-9999', goal: 'Selecione seu objetivo', message: 'Conte um pouco sobre sua rotina...' }" :goalOptions="[{ value: 'weight_loss', label: 'Emagrecimento' }, { value: 'muscle_gain', label: 'Ganho de Massa Muscular' }, { value: 'hybrid', label: 'Treinamento Híbrido' }, { value: 'conditioning', label: 'Condicionamento Físico' }, { value: 'other', label: 'Outro' }]" submitText="Enviar Solicitação" successMessage="Obrigado! Sua solicitação foi enviada." loadingText="Enviando..." errorText="Erro ao enviar. Tente novamente." locale="pt" />

</div>
</div>

<div class="faq-section">
<h2>Perguntas Frequentes</h2>
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

<style scoped>
.lead { font-size: 1.2rem; line-height: 1.7; color: rgba(245, 245, 240, 0.9); margin-bottom: 3rem; }
.contact-grid { display: grid; grid-template-columns: 1fr; gap: 3rem; margin-bottom: 4rem; }
@media (min-width: 768px) { .contact-grid { grid-template-columns: 1fr 1.5fr; } }
.contact-info h2, .contact-form-section h2 { color: #C4F53A; margin-bottom: 2rem; }
.info-item { display: flex; gap: 1.5rem; margin-bottom: 2rem; align-items: flex-start; }
.info-icon { font-size: 2rem; flex-shrink: 0; }
.info-content h3 { color: #0EA5E9; font-size: 1.1rem; margin-bottom: 0.5rem; }
.info-content p { color: rgba(245, 245, 240, 0.85); margin: 0; }
.info-content a { color: #0EA5E9; text-decoration: none; }
.info-content a:hover { color: #C4F53A; }
.schedule-info { background: rgba(196, 245, 58, 0.05); padding: 1.5rem; border-radius: 8px; border-left: 4px solid #C4F53A; margin-top: 2rem; }
.schedule-info h3 { color: #C4F53A; margin-top: 0; margin-bottom: 1rem; }
.schedule-info ul { list-style: none; padding: 0; margin: 0; }
.schedule-info li { padding: 0.5rem 0; color: rgba(245, 245, 240, 0.85); }
.contact-form-section p { color: rgba(245, 245, 240, 0.8); margin-bottom: 2rem; }
.faq-section { margin-top: 4rem; padding-top: 4rem; border-top: 1px solid rgba(245, 245, 240, 0.1); }
.faq-section h2 { color: #C4F53A; text-align: center; margin-bottom: 3rem; }
.faq-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2rem; }
.faq-item { background: rgba(245, 245, 240, 0.03); padding: 1.5rem; border-radius: 8px; border: 1px solid rgba(245, 245, 240, 0.1); }
.faq-item:hover { border-color: rgba(196, 245, 58, 0.3); }
.faq-item h3 { color: #0EA5E9; font-size: 1.1rem; margin-bottom: 1rem; }
.faq-item p { color: rgba(245, 245, 240, 0.85); margin: 0; line-height: 1.6; }
</style>
