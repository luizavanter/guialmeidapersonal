# GA Personal API Documentation / Documentação da API

**Base URL:** `https://api.guialmeidapersonal.esp.br/api/v1`

**Content-Type:** `application/json`

---

## Authentication / Autenticação

All endpoints (except public ones) require a Bearer token.
Todos os endpoints (exceto públicos) requerem um Bearer token.

```
Authorization: Bearer <access_token>
```

### Rate Limits

| Scope | Limit | Period |
|-------|-------|--------|
| Auth (login/register/logout) | 5 req | 1 min/IP |
| Token refresh | 10 req | 1 min/IP |
| Contact form | 3 req | 1 min/IP |

---

## Public Endpoints / Endpoints Públicos

### Health Check

```
GET /health
```

Returns system status. No authentication required.
Retorna status do sistema. Sem autenticação.

**Response / Resposta:**
```json
{ "status": "ok" }
```

---

### Register / Registro

```
POST /auth/register
```

**Body:**
```json
{
  "user": {
    "email": "user@example.com",
    "password": "securepassword",
    "first_name": "John",
    "last_name": "Doe",
    "role": "trainer"
  }
}
```

**Response / Resposta:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "trainer"
  },
  "tokens": {
    "accessToken": "jwt_token",
    "refreshToken": "opaque_token",
    "expiresIn": 900
  }
}
```

---

### Login

```
POST /auth/login
```

**Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response / Resposta:** Same as register / Mesmo que registro.

---

### Refresh Token / Renovar Token

```
POST /auth/refresh
```

**Body:**
```json
{
  "refresh_token": "opaque_token"
}
```

**Response / Resposta:**
```json
{
  "tokens": {
    "accessToken": "new_jwt",
    "refreshToken": "new_opaque_token",
    "expiresIn": 900
  }
}
```

Token rotation: old refresh token is invalidated.
Rotação de token: o refresh token antigo é invalidado.

---

### Logout

```
POST /auth/logout
```

Requires authentication. Revokes the refresh token.
Requer autenticação. Revoga o refresh token.

**Body:**
```json
{
  "refresh_token": "opaque_token"
}
```

---

### Get Current User / Usuário Atual

```
GET /auth/me
```

Returns the authenticated user's data.
Retorna dados do usuário autenticado.

---

### Contact Form / Formulário de Contato

```
POST /contact
```

**Body:**
```json
{
  "contact": {
    "name": "Maria Silva",
    "email": "maria@example.com",
    "phone": "+55 48 99999-9999",
    "goal": "Weight loss",
    "message": "I'd like to schedule an assessment",
    "locale": "pt-BR"
  }
}
```

---

## Webhooks

### Cal.com

```
POST /webhooks/calcom
```

Receives booking events from Cal.com.
Recebe eventos de agendamento do Cal.com.

### Asaas

```
POST /webhooks/asaas
```

Receives payment events from Asaas (PAYMENT_CONFIRMED, PAYMENT_RECEIVED, etc.).
Recebe eventos de pagamento do Asaas.

---

## Trainer/Admin Endpoints / Endpoints do Treinador/Admin

All require `Authorization: Bearer <token>` with role `trainer` or `admin`.
Todos requerem `Authorization: Bearer <token>` com role `trainer` ou `admin`.

### Students / Alunos

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/students` | List students / Listar alunos |
| `POST` | `/students` | Create student / Criar aluno |
| `GET` | `/students/:id` | Get student detail / Detalhe do aluno |
| `PUT` | `/students/:id` | Update student / Atualizar aluno |
| `DELETE` | `/students/:id` | Delete student (soft) / Deletar aluno |

**Create / Update Body:**
```json
{
  "student": {
    "email": "student@example.com",
    "first_name": "Maria",
    "last_name": "Silva",
    "phone": "+55 48 99999-9999",
    "status": "active",
    "goals": "Weight loss",
    "medical_notes": "No restrictions",
    "emergency_contact": "João Silva",
    "emergency_phone": "+55 48 88888-8888"
  }
}
```

---

### Appointments / Agendamentos

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/appointments` | List appointments / Listar agendamentos |
| `POST` | `/appointments` | Create appointment / Criar agendamento |
| `GET` | `/appointments/:id` | Get appointment / Ver agendamento |
| `PUT` | `/appointments/:id` | Update appointment / Atualizar agendamento |
| `DELETE` | `/appointments/:id` | Cancel appointment / Cancelar agendamento |

**Body:**
```json
{
  "appointment": {
    "student_id": "uuid",
    "scheduled_at": "2026-03-01T10:00:00Z",
    "duration_minutes": 60,
    "notes": "Focus on lower body",
    "status": "confirmed"
  }
}
```

**Status values / Valores de status:** `pending`, `confirmed`, `cancelled`, `done`, `no_show`

---

### Exercises / Exercícios

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/exercises` | List exercises / Listar exercícios |
| `POST` | `/exercises` | Create exercise / Criar exercício |
| `GET` | `/exercises/:id` | Get exercise / Ver exercício |
| `PUT` | `/exercises/:id` | Update exercise / Atualizar exercício |
| `DELETE` | `/exercises/:id` | Delete exercise / Deletar exercício |

**Body:**
```json
{
  "exercise": {
    "name": "Barbell Squat",
    "category": "strength",
    "muscle_groups": ["quadriceps", "glutes", "hamstrings"],
    "equipment_needed": "barbell",
    "difficulty_level": "intermediate",
    "instructions": "Stand with feet shoulder-width apart...",
    "video_url": "https://..."
  }
}
```

---

### Workout Plans / Planos de Treino

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/workout-plans` | List plans / Listar planos |
| `POST` | `/workout-plans` | Create plan / Criar plano |
| `GET` | `/workout-plans/:id` | Get plan with exercises / Ver plano com exercícios |
| `PUT` | `/workout-plans/:id` | Update plan / Atualizar plano |
| `DELETE` | `/workout-plans/:id` | Delete plan / Deletar plano |

**Body:**
```json
{
  "workout_plan": {
    "name": "Beginner Full Body",
    "description": "3x per week full body program",
    "status": "active",
    "is_template": true
  }
}
```

---

### Plans (Pricing) / Planos (Preços)

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/plans` | List pricing plans / Listar planos de preço |
| `POST` | `/plans` | Create plan / Criar plano |
| `GET` | `/plans/:id` | Get plan / Ver plano |
| `PUT` | `/plans/:id` | Update plan / Atualizar plano |
| `DELETE` | `/plans/:id` | Delete plan / Deletar plano |

**Body:**
```json
{
  "plan": {
    "name": "Monthly",
    "price_cents": 30000,
    "duration_days": 30,
    "description": "3 sessions per week",
    "active": true
  }
}
```

> **Note / Nota:** `price_cents` is in centavos (R$ 300.00 = `30000`).

---

### Subscriptions / Assinaturas

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/subscriptions` | List subscriptions / Listar assinaturas |
| `POST` | `/subscriptions` | Create subscription / Criar assinatura |
| `GET` | `/subscriptions/:id` | Get subscription / Ver assinatura |
| `PUT` | `/subscriptions/:id` | Update subscription / Atualizar assinatura |
| `DELETE` | `/subscriptions/:id` | Cancel subscription / Cancelar assinatura |

**Body:**
```json
{
  "subscription": {
    "student_id": "uuid",
    "plan_id": "uuid",
    "start_date": "2026-03-01",
    "auto_renew": true
  }
}
```

---

### Payments / Pagamentos

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/payments` | List payments / Listar pagamentos |
| `POST` | `/payments` | Create payment / Criar pagamento |
| `GET` | `/payments/:id` | Get payment / Ver pagamento |
| `PUT` | `/payments/:id` | Update payment / Atualizar pagamento |
| `POST` | `/payments/:id/charge` | Create Asaas charge / Criar cobrança Asaas |

**Create Body:**
```json
{
  "payment": {
    "student_id": "uuid",
    "amount_cents": 30000,
    "due_date": "2026-03-15",
    "description": "Monthly plan - March",
    "payment_method": "pix",
    "status": "pending"
  }
}
```

**Create Charge Body (Asaas):**
```json
{
  "billing_type": "PIX"
}
```

Returns QR code for Pix, URL for Boleto, or processes credit card.
Retorna QR code para Pix, URL para Boleto, ou processa cartão de crédito.

> **Note / Nota:** `amount_cents` is in centavos (R$ 300.00 = `30000`).

**Payment methods / Métodos:** `pix`, `boleto`, `credit_card`, `debit_card`, `cash`, `bank_transfer`

**Status values / Valores de status:** `pending`, `completed`, `failed`, `refunded`

---

### Body Assessments / Avaliações Físicas

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/body-assessments` | List assessments / Listar avaliações |
| `POST` | `/body-assessments` | Create assessment / Criar avaliação |
| `GET` | `/body-assessments/:id` | Get assessment / Ver avaliação |
| `PUT` | `/body-assessments/:id` | Update assessment / Atualizar avaliação |
| `DELETE` | `/body-assessments/:id` | Delete assessment / Deletar avaliação |

**Body:**
```json
{
  "body_assessment": {
    "student_id": "uuid",
    "assessment_date": "2026-03-01",
    "weight": 80.5,
    "height": 175,
    "body_fat_percentage": 22.0,
    "muscle_mass": 35.2,
    "bmi": 26.3,
    "waist": 85,
    "hips": 95,
    "chest": 100,
    "arms": 33,
    "thighs": 55,
    "notes": "Good progress this month"
  }
}
```

---

### Goals / Metas

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/goals` | List goals / Listar metas |
| `POST` | `/goals` | Create goal / Criar meta |
| `GET` | `/goals/:id` | Get goal / Ver meta |
| `PUT` | `/goals/:id` | Update goal / Atualizar meta |
| `DELETE` | `/goals/:id` | Delete goal / Deletar meta |

**Body:**
```json
{
  "goal": {
    "student_id": "uuid",
    "title": "Lose 10kg",
    "description": "Reach 70kg by June",
    "target_value": 70.0,
    "current_value": 80.0,
    "unit": "kg",
    "target_date": "2026-06-01",
    "status": "in_progress"
  }
}
```

---

### Content Management / Gestão de Conteúdo

#### Blog Posts

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/blog-posts` | List posts / Listar posts |
| `POST` | `/blog-posts` | Create post / Criar post |
| `GET` | `/blog-posts/:id` | Get post / Ver post |
| `PUT` | `/blog-posts/:id` | Update post / Atualizar post |
| `DELETE` | `/blog-posts/:id` | Delete post / Deletar post |

#### Testimonials / Depoimentos

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/testimonials` | List / Listar |
| `POST` | `/testimonials` | Create / Criar |
| `PUT` | `/testimonials/:id` | Update / Atualizar |
| `DELETE` | `/testimonials/:id` | Delete / Deletar |

#### FAQs

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/faqs` | List / Listar |
| `POST` | `/faqs` | Create / Criar |
| `PUT` | `/faqs/:id` | Update / Atualizar |
| `DELETE` | `/faqs/:id` | Delete / Deletar |

---

### Media Management / Gestão de Mídia

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `POST` | `/media/upload-url` | Generate signed upload URL / Gerar URL de upload assinada |
| `POST` | `/media/confirm-upload` | Confirm upload completed / Confirmar upload concluído |
| `GET` | `/media/:id/download` | Get signed download URL / Obter URL de download assinada |
| `DELETE` | `/media/:id` | Soft delete media / Deletar mídia (soft) |
| `GET` | `/students/:student_id/media` | List student media / Listar mídia do aluno |

**Upload URL Body:**
```json
{
  "file_type": "evolution_photo",
  "content_type": "image/jpeg",
  "student_id": "uuid"
}
```

**file_type values:** `evolution_photo`, `medical_document`, `bioimpedance_report`

---

### Bioimpedance Import / Importação de Bioimpedância

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `POST` | `/bioimpedance/extract` | Start AI extraction from report / Iniciar extração IA do relatório |
| `GET` | `/bioimpedance/imports` | List imports / Listar importações |
| `GET` | `/bioimpedance/imports/:id` | Get import detail / Ver detalhe da importação |
| `PUT` | `/bioimpedance/imports/:id` | Update extracted data / Atualizar dados extraídos |
| `POST` | `/bioimpedance/imports/:id/apply` | Apply to body assessment / Aplicar à avaliação física |
| `POST` | `/bioimpedance/imports/:id/reject` | Reject import / Rejeitar importação |

---

### AI Analysis / Análise IA

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `POST` | `/ai/analyze/visual` | Visual body analysis (Claude) / Análise visual corporal |
| `POST` | `/ai/analyze/trends` | Body composition trends / Tendências de composição corporal |
| `POST` | `/ai/analyze/document` | Medical document analysis / Análise de documento médico |
| `GET` | `/ai/analyses` | List analyses / Listar análises |
| `GET` | `/ai/analyses/:id` | Get analysis / Ver análise |
| `PUT` | `/ai/analyses/:id/review` | Review/approve analysis / Revisar/aprovar análise |
| `POST` | `/ai/analyses/:id/share` | Share with student / Compartilhar com aluno |
| `GET` | `/ai/usage` | Check API usage / Verificar uso da API |

---

### Pose Detection / Detecção de Pose

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/pose/results` | List pose results / Listar resultados de pose |
| `GET` | `/pose/results/:id` | Get pose result / Ver resultado de pose |
| `GET` | `/students/:student_id/pose` | Student pose history / Histórico de pose do aluno |

---

## Messages & Notifications / Mensagens & Notificações

Available to all authenticated users.
Disponível para todos os usuários autenticados.

### Messages / Mensagens

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/messages` | List messages / Listar mensagens |
| `POST` | `/messages` | Send message / Enviar mensagem |
| `GET` | `/messages/:id` | Get message / Ver mensagem |
| `DELETE` | `/messages/:id` | Delete message / Deletar mensagem |
| `GET` | `/messages/inbox` | Inbox / Caixa de entrada |
| `GET` | `/messages/sent` | Sent messages / Mensagens enviadas |

**Send Body:**
```json
{
  "message": {
    "recipient_id": "uuid",
    "subject": "Training update",
    "body": "Your new plan is ready!"
  }
}
```

### Notifications / Notificações

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/notifications` | List notifications / Listar notificações |
| `GET` | `/notifications/:id` | Get notification / Ver notificação |
| `PUT` | `/notifications/:id` | Update notification / Atualizar notificação |
| `DELETE` | `/notifications/:id` | Delete notification / Deletar notificação |
| `POST` | `/notifications/:id/read` | Mark as read / Marcar como lida |
| `POST` | `/notifications/read-all` | Mark all as read / Marcar todas como lidas |

---

### Privacy (LGPD) / Privacidade (LGPD)

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `POST` | `/privacy/consent` | Grant consent / Conceder consentimento |
| `DELETE` | `/privacy/consent/:type` | Revoke consent / Revogar consentimento |
| `GET` | `/privacy/my-data` | Export personal data / Exportar dados pessoais |
| `DELETE` | `/privacy/my-data` | Delete personal data / Deletar dados pessoais |

**consent_type values:** `media_upload`, `ai_analysis`, `data_retention`

---

## Student Endpoints / Endpoints do Aluno

All require `Authorization: Bearer <token>` with role `student`.
Todos requerem `Authorization: Bearer <token>` com role `student`.

Base path: `/api/v1/student`

| Method | Endpoint | Description / Descrição |
|--------|----------|------------------------|
| `GET` | `/student/workout-plans` | My workout plans / Meus planos de treino |
| `GET` | `/student/workout-plans/:id` | Plan detail / Detalhe do plano |
| `GET` | `/student/workout-logs` | My workout logs / Meus registros de treino |
| `POST` | `/student/workout-logs` | Log workout / Registrar treino |
| `GET` | `/student/workout-logs/:id` | Log detail / Detalhe do registro |
| `GET` | `/student/appointments` | My appointments / Meus agendamentos |
| `GET` | `/student/appointments/:id` | Appointment detail / Detalhe do agendamento |
| `GET` | `/student/body-assessments` | My assessments / Minhas avaliações |
| `GET` | `/student/body-assessments/:id` | Assessment detail / Detalhe da avaliação |
| `GET` | `/student/goals` | My goals / Minhas metas |
| `GET` | `/student/goals/:id` | Goal detail / Detalhe da meta |
| `PUT` | `/student/goals/:id/progress` | Update progress / Atualizar progresso |
| `GET` | `/student/subscription` | My subscription / Minha assinatura |
| `GET` | `/student/payments` | My payments / Meus pagamentos |
| `POST` | `/student/media/upload-url` | Upload URL / URL de upload |
| `POST` | `/student/media/confirm-upload` | Confirm upload / Confirmar upload |
| `GET` | `/student/media/:id/download` | Download file / Baixar arquivo |
| `GET` | `/student/my-media` | My media files / Meus arquivos de mídia |
| `GET` | `/student/ai/analyses` | My AI analyses / Minhas análises IA |
| `GET` | `/student/ai/analyses/:id` | Analysis detail / Detalhe da análise |
| `POST` | `/student/pose/results` | Save pose result / Salvar resultado de pose |
| `GET` | `/student/pose/results` | My pose results / Meus resultados de pose |
| `GET` | `/student/pose/results/:id` | Pose detail / Detalhe de pose |

**Workout Log Body:**
```json
{
  "workout_log": {
    "workout_plan_id": "uuid",
    "exercise_id": "uuid",
    "sets": 3,
    "reps": 10,
    "weight": 60.0,
    "rest_seconds": 90,
    "rpe": 8,
    "notes": "Felt strong today"
  }
}
```

---

## Error Responses / Respostas de Erro

### 400 Bad Request
```json
{
  "errors": {
    "field_name": ["error message"]
  }
}
```

### 401 Unauthorized / Não Autorizado
```json
{
  "error": "Invalid credentials"
}
```

### 403 Forbidden / Proibido
```json
{
  "error": "Forbidden"
}
```

### 404 Not Found / Não Encontrado
```json
{
  "error": "Not found"
}
```

### 429 Too Many Requests / Muitas Requisições
```json
{
  "error": "Rate limit exceeded"
}
```

---

## Multi-Tenant / Multi-Inquilino

All data is automatically filtered by `trainer_id`. Trainers can only access their own students and data.
Todos os dados são automaticamente filtrados por `trainer_id`. Treinadores só acessam seus próprios alunos e dados.

---

## Payload Format / Formato de Payload

All create/update requests must wrap data in a resource key.
Todas as requisições de criação/atualização devem envolver dados em uma chave de recurso.

```
✅ { "student": { "email": "..." } }
❌ { "email": "..." }
```

| Resource / Recurso | Key / Chave |
|---------------------|-------------|
| Students / Alunos | `student` |
| Appointments / Agendamentos | `appointment` |
| Exercises / Exercícios | `exercise` |
| Workout Plans / Planos de Treino | `workout_plan` |
| Workout Logs / Registros de Treino | `workout_log` |
| Plans / Planos (preço) | `plan` |
| Subscriptions / Assinaturas | `subscription` |
| Payments / Pagamentos | `payment` |
| Body Assessments / Avaliações | `body_assessment` |
| Goals / Metas | `goal` |
| Messages / Mensagens | `message` |
| Blog Posts | `blog_post` |
| Testimonials / Depoimentos | `testimonial` |
| FAQs | `faq` |
| Contact / Contato | `contact` |

---

## Currency / Moeda

All monetary values are in **centavos** (integer).
Todos os valores monetários são em **centavos** (inteiro).

- R$ 150.00 = `15000`
- R$ 300.00 = `30000`

Fields / Campos: `amount_cents`, `price_cents`
