# GA Personal - Gap Analysis Completo

**Data:** 2026-02-04
**Status:** Sistema em Produção com Gaps Identificados

---

## Sumário Executivo

Análise completa do sistema GA Personal identificou **8 problemas críticos**, **7 problemas médios** e diversas oportunidades de melhoria. O sistema está funcional mas requer correções antes de uso em produção real.

### Scorecard Geral

| Área | Score | Status |
|------|-------|--------|
| Backend Phoenix | 75/100 | ⚠️ Segurança precisa atenção |
| Trainer App | 69/100 | ⚠️ CRUD incompleto |
| Student App | 80/100 | ✅ Funcional com 1 bug crítico |
| Site VitePress | 80/100 | ⚠️ Assets faltando |
| Infraestrutura | 90/100 | ✅ GCP bem configurado |

---

## 1. PROBLEMAS CRÍTICOS (8)

### 1.1 Backend - Field Names Inconsistentes

**Arquivos afetados:**
- `apps/ga_personal_web/lib/ga_personal_web/controllers/notification_controller.ex`
- `apps/ga_personal_web/lib/ga_personal_web/controllers/payment_controller.ex`
- `apps/ga_personal_web/lib/ga_personal_web/controllers/testimonial_controller.ex`
- `apps/ga_personal_web/lib/ga_personal_web/controllers/workout_plan_controller.ex`

**Problema:** Controllers referenciam campos que não existem nos schemas.

| Controller | Campo usado | Campo correto no schema |
|------------|-------------|-------------------------|
| notification_controller | `notification.notification_type` | `notification.type` |
| notification_controller | `notification.message` | `notification.body` |
| payment_controller | `payment.external_reference` | `payment.reference_number` |
| testimonial_controller | `testimonial.student_name` | `testimonial.author_name` |
| testimonial_controller | `testimonial.photo_url` | `testimonial.author_photo_url` |
| workout_plan_controller | `workout_plan.start_date` | `workout_plan.started_at` |
| workout_plan_controller | `workout_plan.end_date` | `workout_plan.completed_at` |
| workout_plan_controller | `we.order` | `we.order_in_workout` |

**Impacto:** RuntimeError ao serializar respostas da API.

**Correção necessária:** Atualizar controllers para usar nomes corretos.

---

### 1.2 Backend - Falta Autorização por Role

**Problema:** Não há verificação de role (trainer vs student vs admin). Qualquer usuário autenticado pode acessar qualquer endpoint.

**Exemplo:** Um student poderia chamar `/api/v1/students` e listar alunos.

**Correção necessária:**
```elixir
# Criar plug de autorização
defmodule GaPersonalWeb.Plugs.RequireRole do
  def call(conn, roles) do
    if conn.assigns.current_user.role in roles do
      conn
    else
      conn |> send_resp(403, "Forbidden") |> halt()
    end
  end
end
```

---

### 1.3 Backend - Falta Ownership Verification

**Problema:** Trainer A pode acessar dados de Trainer B se souber o ID.

**Exemplo:** `GET /api/v1/students/123` retorna o aluno mesmo que pertença a outro trainer.

**Correção necessária:** Adicionar filtro por `trainer_id` em todas as queries.

---

### 1.4 Trainer App - Sem Edit/Delete

**Problema:** Todas as views têm apenas modal de "Add". Não existe forma de editar ou deletar recursos.

**Views afetadas:**
- StudentsView - sem edit, sem delete
- AgendaView - sem edit, sem delete
- ExercisesView - sem edit, sem delete
- WorkoutPlansView - sem edit, sem delete
- PaymentsView - sem edit, sem delete
- SubscriptionsView - sem edit
- PlansView - sem edit
- MessagesView - sem delete

**Store methods existem mas não são usados:** `updateStudent`, `updateAppointment`, etc.

**Correção necessária:** Adicionar botões de edit/delete em cada card/row e criar modais de edição.

---

### 1.5 Student App - Receiver ID Hardcoded

**Arquivo:** `frontend/student-app/src/views/MessagesView.vue:161`

```typescript
receiverId: 'trainer-id', // This should come from student profile
```

**Impacto:** Envio de mensagens não funciona.

**Correção necessária:** Obter `trainerId` do store de profile ou auth.

---

### 1.6 Site - Logo SVG Faltando

**Status:** ✅ CORRIGIDO nesta sessão

**Arquivo criado:** `frontend/site/docs/public/images/logo.svg`

---

### 1.7 Site - Favicon Faltando

**Status:** ✅ CORRIGIDO nesta sessão

**Arquivo criado:** `frontend/site/docs/public/favicon.svg`
**Config atualizado:** `config.ts` linha 73

---

### 1.8 Site - Formspree Form ID Placeholder

**Arquivo:** `frontend/site/docs/.vitepress/theme/components/ContactForm.vue:5`

```html
action="https://formspree.io/f/YOUR_FORM_ID"
```

**Impacto:** Formulário de contato não envia emails.

**Correção necessária:**
1. Criar conta em formspree.io
2. Criar formulário
3. Substituir `YOUR_FORM_ID` pelo ID real

---

## 2. PROBLEMAS MÉDIOS (7)

### 2.1 Backend - Audit Logging Não Implementado

O módulo System.log_action/6 existe mas nunca é chamado pelos controllers.

**Correção:** Adicionar chamadas de log em create/update/delete.

### 2.2 Trainer App - StudentDetailView Tabs Vazias

Tabs 2-5 (Workouts, Evolution, Payments, History) mostram "no data".

**Correção:** Implementar componentes para cada tab.

### 2.3 Trainer App - Messages com Mock Data

MessagesView usa dados hardcoded, não conecta com backend.

**Correção:** Implementar store de messages e conectar com API.

### 2.4 Trainer App - AgendaView é Lista

Não há visualização de calendário real (grid por hora/dia).

**Correção:** Implementar grid de calendário ou usar biblioteca.

### 2.5 Site - Blog Posts EN-US Não Existem

Sidebar EN-US referencia 5 posts que não existem.

**Correção:** Traduzir posts ou remover links do sidebar EN-US.

### 2.6 Site - Conteúdo EN-US Reduzido

About e Services em EN-US têm ~50% do conteúdo de PT-BR.

**Correção:** Expandir conteúdo ou aceitar versão resumida.

### 2.7 Site - Telefone WhatsApp Placeholder

```
(48) 99999-9999
```

**Correção:** Atualizar com número real do Guilherme.

---

## 3. RECOMENDAÇÕES DE INTEGRAÇÃO

### 3.1 SMTP - Resend (Recomendado)

**Tier gratuito:** 3.000 emails/mês
**Preço pago:** $20/mês para 50.000 emails
**Integração Elixir:** Excelente via `{:resend, "~> 0.4.0"}`

**Implementação:**
```elixir
# mix.exs
{:resend, "~> 0.4.0"}

# config/runtime.exs
config :ga_personal, GaPersonal.Mailer,
  adapter: Resend.Swoosh.Adapter,
  api_key: System.get_env("RESEND_API_KEY")
```

**Alternativa:** Amazon SES ($0.10/1.000 emails)

### 3.2 Agendamento - Cal.com Self-Hosted (Recomendado)

**Custo:** Gratuito (apenas infra ~$10-20/mês)
**Vantagens:**
- Open source, controle total
- Webhooks inclusos
- Infraestrutura GCP compatível

**Fluxo proposto:**
```
Aluno → Cal.com embed → Webhook → GA Personal API → Cria Appointment
```

**Alternativa simples:** Google Calendar API (gratuito, sem interface de booking)

---

## 4. ASSETS PENDENTES

| Asset | Status | Ação Necessária |
|-------|--------|-----------------|
| Foto Guilherme | ✅ Adicionada | Copiar para production |
| Logo SVG | ✅ Criado | Validar design com cliente |
| Favicon SVG | ✅ Criado | OK |
| Formspree ID | ❌ Pendente | Criar conta e obter ID |
| WhatsApp real | ❌ Pendente | Obter número com cliente |
| Email real | ❌ Pendente | Confirmar email ativo |

---

## 5. PRÓXIMOS PASSOS PRIORIZADOS

### Fase 1 - Crítico (Esta semana)
1. [ ] Corrigir field names nos controllers
2. [ ] Implementar autorização por role
3. [ ] Implementar ownership verification
4. [ ] Corrigir receiverId hardcoded no Student App
5. [ ] Configurar Formspree Form ID

### Fase 2 - Alto (Próximas 2 semanas)
6. [ ] Adicionar edit/delete em Trainer App
7. [ ] Completar StudentDetailView tabs
8. [ ] Implementar Messages corretamente
9. [ ] Traduzir blog posts EN-US (ou remover links)

### Fase 3 - Médio (Próximo mês)
10. [ ] Integrar SMTP (Resend)
11. [ ] Integrar Cal.com ou Google Calendar
12. [ ] Implementar calendário visual no AgendaView
13. [ ] Adicionar audit logging

### Fase 4 - Melhoria Contínua
14. [ ] Melhorar validação de forms
15. [ ] Adicionar acessibilidade (aria-labels)
16. [ ] Adicionar structured data (schema.org)
17. [ ] Expandir conteúdo EN-US

---

## 6. ESTIMATIVA DE ESFORÇO

| Fase | Itens | Horas Estimadas |
|------|-------|-----------------|
| Fase 1 | 5 | 15-20h |
| Fase 2 | 4 | 40-60h |
| Fase 3 | 4 | 30-40h |
| Fase 4 | 4 | 20-30h |
| **Total** | **17** | **105-150h** |

---

## 7. ARQUIVOS CRIADOS/MODIFICADOS NESTA SESSÃO

1. ✅ `frontend/site/docs/public/images/guilherme-hero.jpg` - Foto copiada
2. ✅ `frontend/site/docs/public/images/logo.svg` - Logo criado
3. ✅ `frontend/site/docs/public/favicon.svg` - Favicon criado
4. ✅ `frontend/site/docs/.vitepress/config.ts` - Atualizado para usar favicon.svg
5. ✅ `docs/plans/2026-02-04-gap-analysis-complete.md` - Este documento

---

**Documento gerado automaticamente via análise de 6 agentes especializados.**
