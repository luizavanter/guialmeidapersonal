# GA Personal — Projeto Guilherme Almeida

## Status do Projeto
✅ **Sistema em PRODUÇÃO** (2026-02-03, hardened 2026-02-27, AI Media Suite 2026-02-28)
- Backend Phoenix com 12 contextos - **DEPLOYED**
- 3 aplicações frontend (Trainer, Student, Site) - **DEPLOYED**
- Suporte bilíngue completo (PT-BR/EN-US)
- 20.000+ linhas de código em produção
- **Todos os endpoints funcionando** (90+ endpoints)
- **Login e navegação testados e funcionando**
- **Security hardening completo** (JWT refresh tokens, rate limiting, input sanitization)
- **Test coverage** (ExMachina factories, context + controller tests)
- **Email transacional** (Oban + Swoosh/Resend, 6 tipos de email automático)
- **Asaas payment integration** (Pix, Boleto, Cartão de crédito)
- **AI Media Suite** (GCS upload, Claude AI analysis, bioimpedance OCR, pose detection, LGPD compliance)

## Stack Tecnológica

### Backend
- **Elixir 1.15+ / Phoenix 1.8.3** - API REST com autenticação JWT
- **PostgreSQL 16** - Banco de dados com 28 tabelas
- **Guardian 2.4** - Autenticação JWT (access 15min + refresh 30 dias)
- **Oban 2.18** - Background jobs (10 workers, cron + async)
- **Hammer** - Rate limiting (ETS-backed)
- **Swoosh + Resend** - Email transacional (10 templates bilíngues)
- **Goth 1.4** - Google Cloud auth (metadata server, credentials)
- **Req** - HTTP client (Asaas API, Claude API, GCS)
- **Bcrypt** - Password hashing
- **Gettext** - Internacionalização (PT-BR/EN-US)
- **ExMachina** - Test factories (20 schemas)

### Frontend
- **Vue 3 (Composition API)** - 3 aplicações SPA
- **TypeScript** - Tipagem estrita em todo o código
- **Pinia** - Gerenciamento de estado
- **Vue Router** - Navegação com guards
- **Tailwind CSS** - Sistema de design
- **Vite** - Build tool
- **Chart.js** - Gráficos de evolução
- **Vue I18n** - Internacionalização

### Infraestrutura (Produção - GCP)
- **GCP Project:** `guialmeidapersonal`
- **Region:** `southamerica-east1` (São Paulo)
- **Cloud Run:** Backend Phoenix API
- **Cloud SQL:** PostgreSQL 16 (db-perf-optimized-N-2)
- **Memorystore:** Redis 7.0 (1GB)
- **Cloud Storage + CDN:** 3 frontend buckets
- **Global HTTPS Load Balancer:** SSL termination + routing
- **Certificate Manager:** Wildcard SSL for *.guialmeidapersonal.esp.br
- **Workload Identity Federation:** Secure CI/CD (no service account keys)

### Infraestrutura (Desenvolvimento)
- **100% Cloud (GCP)** - Sem ambiente local. Não há Docker, PostgreSQL ou Redis local.
- Todo desenvolvimento e teste acontece contra os serviços em produção no GCP.

## Estrutura do Projeto

```
ga-personal/
├── apps/
│   ├── ga_personal/           # Core - 12 contextos de negócio
│   │   ├── lib/ga_personal/
│   │   │   ├── ai/            # Claude API client (Haiku + Sonnet)
│   │   │   ├── ai_analysis/   # AI analysis records schema
│   │   │   ├── asaas/         # Asaas payment gateway client
│   │   │   ├── bioimpedance/  # Bioimpedance import schema
│   │   │   ├── gcs/           # Google Cloud Storage client
│   │   │   ├── media/         # Media file schema
│   │   │   ├── pose/          # Pose analysis schema
│   │   │   ├── privacy/       # LGPD consent + access logs
│   │   │   ├── workers/       # Oban background workers (10)
│   │   │   ├── emails/        # Email templates (Swoosh)
│   │   │   └── notification_service.ex  # Dual delivery hub
│   │   └── test/              # Context + factory tests
│   └── ga_personal_web/       # API Phoenix - 90+ endpoints
│       └── test/              # Controller tests
├── frontend/
│   ├── shared/                # @ga-personal/shared - Design system
│   ├── trainer-app/           # Painel do Personal (porta 3001)
│   ├── student-app/           # Portal do Aluno (porta 3002)
│   └── site/                  # Site Marketing VitePress (porta 3003)
├── reference/                 # Designs e especificações originais
├── docs/
│   └── plans/                 # Documentação de design e roadmaps
├── docker-compose.yml
├── MASTER_SUMMARY.md          # Resumo completo do sistema
└── CLAUDE.md                  # Este arquivo
```

## IMPORTANTE: Ambiente 100% Cloud (GCP)

> **MANDATÓRIO:** Este projeto NÃO roda localmente. Não há PostgreSQL, Redis, ou Docker local.
> Todo desenvolvimento, testes, e deploy acontecem exclusivamente no projeto GCP `guialmeidapersonal`.
> Nunca sugerir ou tentar rodar serviços locais (docker-compose, mix phx.server, npm run dev local).

### Como Fazer Deploy (Único Workflow)
```bash
# 1. Build e deploy backend
./infrastructure/gcp/09-build-backend.sh
./infrastructure/gcp/10-deploy-backend.sh

# 2. Run migrations
gcloud run jobs execute ga-personal-migrations --region=southamerica-east1 --project=guialmeidapersonal --wait

# 3. Deploy frontends
./infrastructure/gcp/13-deploy-frontends.sh
```

### Como Rodar Testes
Testes que precisam de banco de dados devem rodar contra o Cloud SQL no GCP.
Testes unitários sem dependência de banco podem ser compilados localmente com `mix compile`.

## URLs de Produção

| Serviço | URL |
|---------|-----|
| **API** | https://api.guialmeidapersonal.esp.br |
| **Admin (Trainer)** | https://admin.guialmeidapersonal.esp.br |
| **App (Student)** | https://app.guialmeidapersonal.esp.br |
| **Site Marketing** | https://guialmeidapersonal.esp.br |

**Load Balancer IP:** `34.149.155.125`

## Credenciais de Acesso

### Admin (Produção)
- **Email:** admin@guialmeidapersonal.esp.br
- **Senha:** Admin@123456
- **Role:** admin
- **Acesso:** https://admin.guialmeidapersonal.esp.br

### Personal Trainer (Guilherme) - Para Criar
- **Email:** guilherme@gapersonal.com
- **Senha:** trainer123
- **Acesso Produção:** https://admin.guialmeidapersonal.esp.br
- **Acesso Local:** http://localhost:3001

### Alunos (Estudantes) - Para Criar
- **Maria:** maria.silva@example.com / student123
- **Carlos:** carlos.santos@example.com / student123
- **Acesso Produção:** https://app.guialmeidapersonal.esp.br
- **Acesso Local:** http://localhost:3002

> **Nota:** Execute `gcloud run jobs execute ga-personal-migrations` para criar usuários seed em produção.

## Design System (GA Personal)

### Cores
- **Coal** `#0A0A0A` - Fundos escuros
- **Lime** `#C4F53A` - CTAs, ações primárias, destaques
- **Ocean** `#0EA5E9` - Links, elementos secundários
- **Smoke** `#F5F5F0` - Textos, bordas sutis

### Tipografia
- **Bebas Neue** - Headlines impactantes (display)
- **Outfit** - Texto corpo (300-700)
- **JetBrains Mono** - Dados, métricas, código

### Princípios
- Dark-first (fundos escuros por padrão)
- Cantos arredondados (6px-12px)
- Espaçamento grid 4px
- Hover effects sutis
- Mobile-first responsive

## Contextos do Backend (12 Módulos)

### 1. Accounts
- Usuários, autenticação, perfis
- Roles: `:trainer`, `:student`, `:admin`
- JWT access tokens (15min) + opaque refresh tokens (30 dias, DB-backed)
- Token rotation on refresh, revocation on logout
- Multi-tenant (dados isolados por trainer)
- Asaas customer sync automático na criação de aluno

### 2. Schedule
- Time slots (horários disponíveis)
- Appointments (agendamentos)
- Recorrência (semanal, quinzenal)
- Status: pending, confirmed, cancelled, done, no_show

### 3. Workouts
- Exercise library (biblioteca de exercícios)
- Workout plans (planilhas de treino)
- Workout logs (registro de execução)
- Sets/reps/weight/rest/tempo/RPE

### 4. Evolution
- Body assessments (avaliações físicas)
- Evolution photos (fotos comparativas)
- Goals (metas personalizadas)
- Cálculos: IMC, % gordura, massa magra

### 5. Finance
- Plans (planos de treino: mensal, trimestral)
- Subscriptions (assinaturas dos alunos, auto-renew, next_billing_date)
- Payments (controle de pagamentos com integração Asaas)
- Status: pending, completed, failed, refunded
- Métodos: pix, boleto, credit_card, debit_card, cash, bank_transfer
- Asaas: charge creation, QR code Pix, boleto URL, webhook sync

### 6. Messaging
- Messages (mensagens diretas trainer ↔ aluno)
- Notifications (notificações in-app com dual delivery email + in-app)
- NotificationService centralizado (5 event triggers)
- Broadcast (avisos em massa)

### 7. Content
- Blog posts (artigos e dicas)
- Testimonials (depoimentos)
- FAQs (perguntas frequentes)
- CMS para site institucional

### 8. System
- Settings (configurações do sistema)
- Audit logs (logs de auditoria)
- Sistema de preferências

## Aplicações Frontend

### 1. Shared Package (@ga-personal/shared)
**Localização:** `frontend/shared/`

**Componentes (10):**
- Button, Input, Textarea, Select
- Card, Modal, Badge, Avatar
- Table (sortable), Chart (Chart.js wrapper)

**Composables (3):**
- `useAuth` - Login, logout, refresh, role checking
- `useApi` - Axios com interceptors e auto-refresh
- `usePagination` - Gerenciamento de paginação

**Utilities (60+):**
- Date formatters (formatDate, getRelativeTime, addDays, etc.)
- Validators (isEmail, isPhone, isCPF, isCNPJ)
- Formatters (formatCurrency, formatPhone, formatWeight)

**i18n (290+ keys):**
- PT-BR (primário)
- EN-US (fallback)

### 2. Trainer App (Painel do Personal)
**Localização:** `frontend/trainer-app/`
**Porta:** 3001

**Telas (15):**
1. Login - Autenticação JWT
2. Dashboard - Stats, agenda de hoje, pagamentos pendentes
3. Students - Lista com busca, filtros, CRUD completo
4. Student Detail - Perfil completo com tabs
5. Agenda - Calendário (dia/semana/mês), agendamentos
6. Workouts Hub - Centro de navegação
7. Exercise Library - CRUD de exercícios
8. Workout Plans - Lista de planilhas
9. Plan Builder - Construtor de treinos
10. Evolution - Avaliações, fotos, metas
11. Finance Dashboard - Stats de faturamento
12. Payments - Rastreamento de pagamentos
13. Subscriptions - Gerenciamento de assinaturas
14. Pricing Plans - Configuração de pacotes
15. Messages - Inbox/envio
16. Settings - Perfil, troca de idioma

**Funcionalidades:**
- ✅ CRUD completo em alunos, exercícios, planos, pagamentos
- ✅ Calendário com visualizações dia/semana/mês
- ✅ Sistema de busca e filtros
- ✅ Indicadores de status e badges
- ✅ Cálculos de receita automáticos
- ✅ Dashboard com estatísticas em tempo real

### 3. Student App (Portal do Aluno)
**Localização:** `frontend/student-app/`
**Porta:** 3002

**Telas (8):**
1. Login - Autenticação (role: student)
2. Dashboard - Próxima aula, treino atual, progresso
3. My Workouts - Treinos atribuídos, histórico
4. Workout Detail - Treino completo com modal de logging
5. Evolution - Gráficos (peso/gordura), avaliações, metas, fotos
6. Schedule - Ver agendamentos, solicitar mudanças
7. Messages - Chat com personal trainer
8. Profile - Editar info, contato emergência

**Funcionalidades:**
- ✅ **Logging de treinos** - Peso/reps/RPE por série com validação
- ✅ **Gráficos de progresso** - Peso e % gordura (Chart.js)
- ✅ **Tracking de metas** - Barras de progresso visuais
- ✅ **Galeria de fotos** - Antes/depois comparativo
- ✅ **Gerenciamento de agenda** - Ver horários, solicitar mudanças
- ✅ **Mensagens** - Indicadores de não lidos

### 4. Site Marketing (VitePress)
**Localização:** `frontend/site/`
**Porta:** 3003

**Páginas PT-BR (11):**
1. Home - Hero, serviços, depoimentos, CTAs
2. Sobre - Bio do Guilherme (1.200 palavras), credenciais
3. Serviços - Hybrid training, perda de peso, ganho massa, 3 pacotes
4. Contato - Formulário, info comercial, 8 FAQs
5. Blog - Index + 5 posts completos:
   - Treinamento Híbrido (1.500 palavras)
   - 5 Erros na Perda de Peso (1.600 palavras)
   - Ganho de Massa Após 40 (1.700 palavras)
   - Importância da Nutrição (1.500 palavras)
   - Consistência no Treino (1.800 palavras)

**Páginas EN-US (5):**
- Home, About, Services, Contact, Blog Index

**Total:** 13.000+ palavras de conteúdo profissional

**Componentes Custom:**
- Hero (gradiente, dual CTAs)
- ServiceCard (checkmarks lima)
- TestimonialCard (5 estrelas)
- ContactForm (API Backend)
- LanguageSwitcher (PT/EN)

**SEO:**
- Meta tags otimizadas
- Structured data
- URLs semânticas
- Sitemap automático

## Funcionalidades Implementadas

### ✅ Prioridade 1 - Core Workflow
- Gerenciamento de Alunos (CRUD completo)
- Agenda/Calendário (booking, recorrência)
- Mensagens (comunicação direta)

### ✅ Prioridade 2 - Training Features
- Biblioteca de Exercícios (busca, filtros)
- Construtor de Planilhas (drag-drop structure)
- Visualização de Treinos (alunos)
- Logging de Treinos (peso/reps/RPE)

### ✅ Prioridade 3 - Progress Tracking
- Avaliações Físicas (entrada manual)
- Fotos de Evolução (galeria, comparação)
- Tracking de Metas (targets, progresso visual)
- Gráficos (peso, gordura ao longo do tempo)

### ✅ Prioridade 4 - Business Management
- Planos & Assinaturas (gestão de pacotes)
- Tracking de Pagamentos (status, overdue)
- Relatórios Financeiros (receita, pendências)
- Notificações (estrutura para lembretes)

## Suporte Bilíngue (PT-BR/EN-US)

### Implementação Completa:
- ✅ Todos os textos UI traduzidos (600+ keys)
- ✅ Mensagens de erro bilíngues
- ✅ Labels de formulários, botões, navegação
- ✅ Conteúdo do blog (PT-BR completo, EN-US páginas core)
- ✅ Language switcher em todos os apps
- ✅ Preferência de idioma persistida
- ✅ Header Accept-Language em APIs

### Cobertura:
- Backend: Mensagens de erro, emails
- Shared: Todos os componentes
- Trainer App: Todas as telas (290+ keys)
- Student App: Todas as telas (290+ keys)
- Website: Todo o conteúdo (13.000+ palavras)

## APIs REST (90+ endpoints)

### Autenticação
- `POST /api/v1/auth/register` - Registro
- `POST /api/v1/auth/login` - Login (retorna access token JWT + refresh token opaco)
- `POST /api/v1/auth/refresh` - Rotação de tokens (novo access + novo refresh)
- `POST /api/v1/auth/logout` - Logout (revoga refresh token no DB)
- `GET /api/v1/auth/me` - Dados do usuário autenticado

### Health Check
- `GET /api/v1/health` - Status do sistema (sem auth, usado por Cloud Run)

### Contact (Publico)
- `POST /api/v1/contact` - Enviar formulario de contato do site

### Students
- `GET /api/v1/students` - Listar (com filtros)
- `POST /api/v1/students` - Criar
- `GET /api/v1/students/:id` - Detalhe
- `PUT /api/v1/students/:id` - Atualizar
- `DELETE /api/v1/students/:id` - Deletar (soft delete)

### Appointments
- `GET /api/v1/appointments` - Listar
- `POST /api/v1/appointments` - Criar
- `PUT /api/v1/appointments/:id` - Atualizar
- `DELETE /api/v1/appointments/:id` - Cancelar

### Workouts
- `GET /api/v1/exercises` - Biblioteca de exercícios
- `GET /api/v1/workout-plans` - Listar planos
- `POST /api/v1/workout-plans` - Criar plano
- `GET /api/v1/workout-plans/:id` - Detalhe do plano
- `POST /api/v1/workout-logs` - Registrar execução

### Evolution
- `GET /api/v1/body-assessments` - Listar avaliações
- `POST /api/v1/body-assessments` - Criar avaliação
- `GET /api/v1/goals` - Listar metas
- `POST /api/v1/goals` - Criar meta
- `PUT /api/v1/goals/:id` - Atualizar progresso

### Finance
- `GET /api/v1/payments` - Listar pagamentos
- `POST /api/v1/payments` - Registrar pagamento
- `PUT /api/v1/payments/:id` - Atualizar pagamento
- `POST /api/v1/payments/:id/charge` - Criar cobrança Asaas (Pix/Boleto/Cartão)
- `GET /api/v1/subscriptions` - Listar assinaturas
- `POST /api/v1/subscriptions` - Criar assinatura

### Messages
- `GET /api/v1/messages` - Inbox
- `POST /api/v1/messages` - Enviar mensagem
- `PUT /api/v1/messages/:id/read` - Marcar como lida

### Notifications
- `GET /api/v1/notifications` - Listar notificações
- `POST /api/v1/notifications/:id/read` - Marcar como lida
- `POST /api/v1/notifications/read-all` - Marcar todas como lidas
- `DELETE /api/v1/notifications/:id` - Excluir notificação

### Webhooks
- `POST /api/v1/webhooks/calcom` - Cal.com booking events
- `POST /api/v1/webhooks/asaas` - Asaas payment events (PAYMENT_CONFIRMED, PAYMENT_RECEIVED, etc.)

### Media (Trainer)
- `POST /api/v1/media/upload-url` - Gerar URL assinada para upload
- `POST /api/v1/media/confirm-upload` - Confirmar upload completo
- `GET /api/v1/media/:id/download` - Gerar URL assinada para download
- `DELETE /api/v1/media/:id` - Soft delete de arquivo
- `GET /api/v1/students/:student_id/media` - Listar arquivos do aluno

### Media (Student)
- `POST /api/v1/student/media/upload-url` - Upload URL para aluno
- `POST /api/v1/student/media/confirm-upload` - Confirmar upload
- `GET /api/v1/student/media/:id/download` - Download
- `GET /api/v1/student/my-media` - Meus arquivos

### Privacy (LGPD)
- `POST /api/v1/privacy/consent` - Registrar consentimento
- `DELETE /api/v1/privacy/consent/:type` - Revogar consentimento
- `GET /api/v1/privacy/my-data` - Exportar dados pessoais
- `DELETE /api/v1/privacy/my-data` - Deletar dados pessoais

### Bioimpedance
- `POST /api/v1/bioimpedance/extract` - Iniciar extração OCR (Claude Haiku)
- `GET /api/v1/bioimpedance/imports` - Listar importações
- `GET /api/v1/bioimpedance/imports/:id` - Detalhe
- `PUT /api/v1/bioimpedance/imports/:id` - Atualizar (review)
- `POST /api/v1/bioimpedance/imports/:id/apply` - Aplicar dados extraídos
- `POST /api/v1/bioimpedance/imports/:id/reject` - Rejeitar

### AI Analysis (Trainer)
- `POST /api/v1/ai/analyze/visual` - Análise visual (Claude Sonnet)
- `POST /api/v1/ai/analyze/trends` - Análise de tendências (Claude Haiku)
- `POST /api/v1/ai/analyze/document` - Análise de documento (Haiku+Sonnet)
- `GET /api/v1/ai/analyses` - Listar análises
- `GET /api/v1/ai/analyses/:id` - Detalhe
- `PUT /api/v1/ai/analyses/:id/review` - Revisar análise
- `POST /api/v1/ai/analyses/:id/share` - Compartilhar com aluno
- `GET /api/v1/ai/usage` - Estatísticas de uso

### AI Analysis (Student)
- `GET /api/v1/student/ai/analyses` - Análises compartilhadas
- `GET /api/v1/student/ai/analyses/:id` - Detalhe

### Pose Detection (Trainer)
- `GET /api/v1/pose/results` - Listar resultados
- `GET /api/v1/pose/results/:id` - Detalhe
- `GET /api/v1/students/:student_id/pose` - Histórico do aluno

### Pose Detection (Student)
- `POST /api/v1/student/pose/results` - Salvar resultado
- `GET /api/v1/student/pose/results` - Meus resultados
- `GET /api/v1/student/pose/results/:id` - Detalhe

**Autenticação:** Todas as rotas (exceto login/register/health/webhooks) requerem `Authorization: Bearer <access_token>`

**Rate Limiting:**
- Auth (login/register/logout): 5 req/min por IP
- Refresh: 10 req/min por IP
- Contact: 3 req/min por IP

**Multi-tenant:** Todas as queries são automaticamente filtradas por `trainer_id`

## Roadmap de Robustez (2026-02-27) — Completo

### ✅ Fase 1 — Security Hardening
- JWT com refresh tokens opacos (DB-backed, rotação, revogação)
- Access token TTL: 15 minutos, Refresh token TTL: 30 dias
- Rate limiting via Hammer (login, register, contact, refresh)
- Health check endpoint (`GET /api/v1/health`)
- Input sanitization (HTML stripping via Sanitizer)

### ✅ Fase 2 — Test Coverage
- ExMachina factories para 20 schemas
- ConnCase helpers com autenticação por role (trainer, student, admin)
- Testes de contexto: Accounts, Schedule, Workouts, Evolution, Finance, Messaging, Content, Sanitizer
- Testes de controller: Auth, Student, Health, Exercise, Message

### ✅ Fase 3 — Email Transacional + Notifications
- Oban background jobs (4 workers + cron schedule)
- `EmailWorker` — Entrega assíncrona de emails via Resend
- `AppointmentReminder` — Cron diário 6AM, lembrete 24h antes
- `PaymentDueReminder` — Cron diário 6AM, vencimento em 3 dias + cobranças atrasadas
- `WeeklyTrainerSummary` — Cron segunda 7AM, resumo semanal HTML
- `NotificationService` — Dual delivery (email + in-app) para 5 eventos:
  - student_created, appointment_created, appointment_cancelled, payment_received, workout_plan_assigned
- Endpoint `POST /notifications/read-all` para marcar todas como lidas

### ✅ Fase 4 — Asaas Payment Integration
- `Asaas.Client` — HTTP client (Req) com suporte sandbox/production
- `Asaas.Customers` — CRUD de clientes, busca por CPF/email
- `Asaas.Charges` — Criação de cobranças (PIX, BOLETO, CREDIT_CARD), QR code, refund
- `AsaasCustomerSync` worker — Sincroniza aluno com Asaas automaticamente na criação
- `POST /payments/:id/charge` — Cria cobrança Asaas (retorna QR code Pix/URL boleto)
- `POST /webhooks/asaas` — Webhook para atualizar status de pagamento
- `AutoBillingWorker` — Cron diário 8AM, gera cobranças automáticas para assinaturas

### Variáveis de Ambiente (Novas — Fase 1-4):
| Variável | Descrição |
|----------|-----------|
| `ASAAS_API_KEY` | Chave da API Asaas |
| `ASAAS_ENVIRONMENT` | `sandbox` ou `production` |
| `ASAAS_WEBHOOK_TOKEN` | Token para verificar webhooks Asaas |

## AI Media Suite (2026-02-28) — Completo

### ✅ Phase A — Media Upload Infrastructure
- **GCS Signed URLs** (V4) para upload direto do browser para Cloud Storage
- **Goth** para autenticação GCP (metadata server no Cloud Run)
- **Media context** — upload URL, confirm, download com signed URLs, soft delete
- **Privacy context** — LGPD compliance (consent records, access logs, data export/deletion)
- **MediaCleanupWorker** — Cron diário 3AM, hard-delete após 30 dias
- GCS path: `media/{trainer_id}/{student_id}/{file_type}/{uuid}.{ext}`
- MIME types: jpeg, png, webp, pdf, xlsx, xls, csv
- Tabelas: media_files, consent_records, access_logs

### ✅ Phase B — Bioimpedance Import
- **Claude Haiku OCR** — Extração automática de dados de relatórios (PDF/foto)
- **Workflow** — pending_extraction → extracting → extracted → reviewed → applied/rejected
- **6 dispositivos** — Anovator, Relaxmedic, InBody, Tanita, Omron, Outro
- **BioimpedanceExtractionWorker** — Oban worker (:ai queue), Claude Haiku multimodal
- **apply_to_assessment** — Cria BodyAssessment automaticamente dos dados extraídos
- Tabela: bioimpedance_imports

### ✅ Phase C — AI Analysis
- **3 tipos de análise:**
  - `visual_body` — Claude Sonnet analisa fotos de evolução (composição, postura, músculo)
  - `numeric_trends` — Claude Haiku analisa histórico de avaliações (tendências, alertas)
  - `medical_document` — Two-step: Haiku extrai valores → Sonnet interpreta para fitness
- **Rate limiting** — 10 análises por trainer por hora (contagem DB)
- **Trainer review obrigatório** antes de compartilhar com aluno
- **Usage stats** — Agregação por hora e por mês
- Tabela: ai_analyses
- Workers: VisualAnalysisWorker, TrendsAnalysisWorker, DocumentAnalysisWorker

### ✅ Phase D — Pose Detection
- **Storage only** — Resultados de detecção de pose do browser (TensorFlow.js MoveNet)
- **Tipos** — posture (análise postural), exercise (avaliação de exercício)
- **Exercícios** — squat, deadlift, shoulder_press, plank, lunge
- **Auto-resolve trainer** — Para alunos, busca trainer_id via Accounts
- Tabela: pose_analyses

### Módulos de IA
- `GaPersonal.AI.Client` — Cliente Claude API centralizado (text + multimodal, haiku/sonnet)
- `GaPersonal.GCS.Client` — GCS V4 signed URL generation (upload/download)
- Modelos: claude-haiku-4-5-20241022, claude-sonnet-4-5-20250514

### Novos Controllers (5)
- `MediaController` — 6 ações (upload URL, confirm, download, index, my_files, delete)
- `PrivacyController` — 4 ações (grant/revoke consent, export/delete data)
- `BioimpedanceController` — 6 ações (extract, index, show, update, apply, reject)
- `AIAnalysisController` — 10 ações (analyze visual/trends/doc, CRUD, review, share, usage)
- `PoseController` — 6 ações (create, index, show, student_history, my_results, show_for_student)

### Novos Oban Workers (5)
- `MediaCleanupWorker` — Cron diário 3AM (cleanup)
- `BioimpedanceExtractionWorker` — Async Claude Haiku OCR (:ai queue)
- `VisualAnalysisWorker` — Claude Sonnet body analysis (:ai queue)
- `TrendsAnalysisWorker` — Claude Haiku trends (:ai queue)
- `DocumentAnalysisWorker` — Two-step Haiku+Sonnet (:ai queue)

### Variáveis de Ambiente (Novas):
| Variável | Descrição |
|----------|-----------|
| `GCS_BUCKET` | Bucket GCS (default: ga-personal-media) |
| `ANTHROPIC_API_KEY` | Chave Claude API (GCP Secret Manager) |

## Integrações Futuras
- WhatsApp Business API - Lembretes automáticos
- PWA - Progressive Web App
- Analytics - Métricas de uso

## Aparelhos Bioimpedância (Suportados)
- **Anovator** - Torre profissional, import via OCR (Claude Haiku)
- **Relaxmedic Intelligence Plus** - Balança Bluetooth, import via OCR
- **InBody, Tanita, Omron** - Import via OCR ou entrada manual
- **Manual Entry** - Formulário completo de avaliação

## Documentação

### Design & Planejamento
- `/docs/plans/2026-02-03-ga-personal-complete-system-design.md` - Design completo
- `/reference/GA_PERSONAL_PROJETO.md` - Especificação original

### Backend
- `/apps/ga_personal/README.md` - Visão geral
- `/apps/ga_personal/QUICKSTART.md` - Guia rápido
- `/apps/ga_personal/BUILD_SUMMARY.md` - Detalhes de build

### Frontend Shared
- `/frontend/shared/README.md` - Docs do package
- `/frontend/shared/COMPONENT_LIST.md` - Specs dos componentes

### Trainer App
- `/frontend/trainer-app/README.md` - Visão geral
- `/frontend/trainer-app/IMPLEMENTATION_SUMMARY.md` - Docs de features

### Student App
- `/frontend/student-app/README.md` - Visão geral
- `/frontend/student-app/IMPLEMENTATION_SUMMARY.md` - Docs de features
- `/frontend/student-app/FEATURES_CHECKLIST.md` - Checklist

### Website
- `/frontend/site/README.md` - Visão geral
- `/frontend/site/SITE_SUMMARY.md` - Docs técnicos
- `/frontend/site/DELIVERY.md` - Relatório de entrega

### Geral
- `/MASTER_SUMMARY.md` - Resumo completo do sistema

## Estatísticas do Projeto

### Código
- **320+ arquivos criados**
- **20.000+ linhas de código em produção**
- **13.000+ palavras de conteúdo**
- **600+ chaves de tradução**
- **30+ interfaces TypeScript**
- **90+ endpoints de API**
- **100+ test cases**

### Componentes
- Backend: 12 contextos, 180+ funções, 28 tabelas, 10 Oban workers
- Asaas: 3 módulos (Client, Customers, Charges)
- AI: 2 módulos (AI.Client, GCS.Client)
- Shared: 30 arquivos, 10 componentes, 60+ utils
- Trainer: 60+ arquivos, 15 telas
- Student: 40+ arquivos, 8 telas
- Website: 20+ arquivos, 16 páginas

### Tecnologias
- Elixir, Phoenix, Ecto, Oban
- Vue 3, TypeScript, Vite
- PostgreSQL, Redis
- Goth, Swoosh, Resend, Req
- Hammer, Guardian, Bcrypt
- Tailwind CSS, Chart.js
- VitePress, Vue I18n
- ExMachina (testes)
- Claude API (Haiku + Sonnet)
- Google Cloud Storage (signed URLs)

## Status de Produção

### Infraestrutura GCP (Completa)
- [x] VPC Network e Subnet (10.0.0.0/20)
- [x] VPC Connector para Cloud Run
- [x] Cloud SQL PostgreSQL 16 (private IP)
- [x] Memorystore Redis 7.0 (private IP)
- [x] Service Accounts (backend-sa, cicd-sa)
- [x] Secret Manager (database-url, redis-url, jwt-secret, secret-key-base, asaas-api-key*)
- [x] Cloud Storage buckets (admin, app, site, media)
- [x] Artifact Registry (Docker images)
- [x] Cloud Run service (ga-personal-api)
- [x] Global HTTPS Load Balancer
- [x] SSL Certificate (Certificate Manager)
- [x] Cloud DNS records
- [x] GitHub Actions CI/CD workflows
- [x] Uptime monitoring checks

### Assets Pendentes
- [ ] Foto do Guilherme (`/frontend/site/docs/public/images/guilherme-hero.jpg`)
- [ ] Logo GA Personal (`/frontend/site/docs/public/images/logo.svg`)
- [ ] Favicon (`/frontend/site/docs/public/favicon.ico`)

### Configurações Pendentes
- [x] ~~Formspree form ID no ContactForm.vue~~ - Substituido por endpoint proprio no backend
- [ ] Info de contato real (telefone, social links)
- [ ] Configurar GitHub Secrets (GCP_WORKLOAD_IDENTITY_PROVIDER, GCP_SERVICE_ACCOUNT)
- [ ] Configurar Asaas: `ASAAS_API_KEY`, `ASAAS_ENVIRONMENT`, `ASAAS_WEBHOOK_TOKEN` no Secret Manager
- [ ] Criar conta Asaas sandbox e obter API key

### Testes
- [x] Test infrastructure (ExMachina factories, ConnCase/DataCase helpers)
- [x] Context tests (8 contextos, 100+ test cases)
- [x] Controller tests (Auth, Student, Health, Exercise, Message)
- [ ] Testes E2E (Playwright ou Cypress)
- [ ] Testes de carga
- [ ] UAT com Guilherme

## Comandos Úteis

### Backend
```bash
mix phx.server              # Start server
mix ecto.setup              # Setup DB
mix ecto.migrate            # Run migrations
mix ecto.reset              # Reset DB
mix test                    # Run tests
mix phx.gen.typescript      # Generate TS types
```

### Frontend
```bash
npm run dev                 # Start dev server
npm run build               # Build for production
npm run preview             # Preview production build
npm run type-check          # TypeScript check
npm run lint                # ESLint
```

### Nota: Sem Ambiente Local
Não há Docker, PostgreSQL ou Redis local. Todos os serviços rodam no GCP.
Ver seção "IMPORTANTE: Ambiente 100% Cloud (GCP)" acima.

## Comandos GCP (Produção)

### Deploy
```bash
# Build e deploy backend
./infrastructure/gcp/09-build-backend.sh
./infrastructure/gcp/10-deploy-backend.sh

# Deploy frontends
./infrastructure/gcp/13-deploy-frontends.sh

# Run migrations
gcloud run jobs execute ga-personal-migrations --region=southamerica-east1 --project=guialmeidapersonal --wait
```

### Monitoramento
```bash
# Status do Cloud Run
gcloud run services describe ga-personal-api --region=southamerica-east1 --project=guialmeidapersonal

# Logs do backend
gcloud run services logs read ga-personal-api --region=southamerica-east1 --project=guialmeidapersonal --limit=50

# Status do SSL
gcloud certificate-manager certificates describe ga-personal-cert --project=guialmeidapersonal

# DNS records
gcloud dns record-sets list --zone=guialmeidapersonal --project=guialmeidapersonal
```

### Scaling
```bash
# Scale up (min 1 instance)
gcloud run services update ga-personal-api --min-instances=1 --region=southamerica-east1 --project=guialmeidapersonal

# Scale down (back to zero)
gcloud run services update ga-personal-api --min-instances=0 --region=southamerica-east1 --project=guialmeidapersonal
```

### Secrets
```bash
# View secret
gcloud secrets versions access latest --secret=jwt-secret --project=guialmeidapersonal

# Update secret
echo -n "new-value" | gcloud secrets versions add jwt-secret --data-file=- --project=guialmeidapersonal
```

## Fixes Aplicados (2026-02-03)

### Backend
1. **CORS** - Movido CORSPlug para `endpoint.ex` (antes do router) para suportar OPTIONS preflight
2. **Auth Response** - Atualizado formato para `{ user, tokens: { accessToken, refreshToken, expiresIn } }`

### Frontend (trainer-app)
1. **Router** - Permitido role 'admin' além de 'trainer' nas rotas protegidas
2. **Vue Imports** - Adicionado `computed` nos imports de `StudentsView.vue` e `ExercisesView.vue`
3. **Stores** - Corrigido `response.data` para `response` (useApi já extrai os dados)
4. **API Payload Format** - Todos os stores agora enviam dados no formato correto:
   - `{ student: data }`, `{ appointment: data }`, `{ payment: data }`, etc.
5. **Field Names** - Corrigidos nomes de campos para match com backend:
   - `scheduled_at` + `duration_minutes` (não start_time/end_time)
   - `amount_cents` (integer cents, não float)
   - `price_cents` + `duration_days` (não price + duration_type)
   - `muscle_groups`, `equipment_needed`, `difficulty_level`
6. **Modals** - Adicionados modals funcionais em todas as views:
   - StudentsView, AgendaView, ExercisesView, WorkoutPlansView
   - PaymentsView, SubscriptionsView, PlansView, MessagesView
7. **Traduções** - Adicionadas todas as traduções faltantes (pt-BR e en-US):
   - `common.firstName`, `common.lastName`, `common.phone`, etc.
   - `workouts.muscles.*`, `finance.*`, `messages.*`
8. **Evolution Route** - Adicionada rota base `/evolution` (sem studentId)

### Infraestrutura
1. **GCS SPA Routing** - Configurado error page = index.html para suportar rotas client-side
2. **CDN Cache** - Configurado no-cache para index.html, invalidação de CDN após deploys

### Documentação
- Detalhes completos em: `/docs/plans/2026-02-03-frontend-fixes-deployment.md`

## Fixes Aplicados (2026-02-04)

### Formulario de Contato
1. **Substituido Formspree por endpoint proprio** - Criado endpoint `POST /api/v1/contact` no backend Phoenix
2. **Arquivos criados:**
   - `/apps/ga_personal/lib/ga_personal/emails/contact_email.ex` - Templates de email bilingues
   - `/apps/ga_personal_web/lib/ga_personal_web/controllers/contact_controller.ex` - Controller
3. **ContactForm.vue atualizado** - Agora usa fetch API para enviar dados ao backend
4. **Funcionalidades:**
   - Email enviado ao trainer com dados do formulario
   - Email de confirmacao enviado ao remetente
   - Suporte bilingue (PT-BR/EN-US)
   - Validacao de campos obrigatorios
   - Estados de loading e erro

## API Payload Requirements

### IMPORTANTE: Formato dos Dados

O backend Phoenix espera dados **sempre wrappados** em uma chave específica:

```typescript
// ❌ ERRADO - causa 400 Bad Request
api.post('/students', { email: 'test@test.com', full_name: 'Test' })

// ✅ CORRETO
api.post('/students', { student: { email: 'test@test.com', full_name: 'Test' } })
```

### Chaves por Recurso:
| Recurso | Chave | Exemplo |
|---------|-------|---------|
| Students | `student` | `{ student: { email, full_name, phone, status } }` |
| Appointments | `appointment` | `{ appointment: { student_id, scheduled_at, duration_minutes } }` |
| Payments | `payment` | `{ payment: { student_id, amount_cents, due_date } }` |
| Subscriptions | `subscription` | `{ subscription: { student_id, plan_id, start_date } }` |
| Plans | `plan` | `{ plan: { name, price_cents, duration_days } }` |
| Exercises | `exercise` | `{ exercise: { name, category, muscle_groups } }` |
| Workout Plans | `workout_plan` | `{ workout_plan: { name, description, status } }` |
| Contact | `contact` | `{ contact: { name, email, phone, goal, message, locale } }` |

### Campos em Centavos:
- `amount_cents` - Valor em centavos (integer), não float
- `price_cents` - Preço em centavos (integer), não float
- Exemplo: R$ 150,00 = `15000`

### Campos de Data/Tempo:
- `scheduled_at` - ISO datetime (não start_time/end_time separados)
- `duration_minutes` - Duração em minutos (integer)
- `duration_days` - Duração em dias (integer, não duration_type)

## Troubleshooting

### Backend não responde (Produção)
```bash
# Verificar status do Cloud Run
gcloud run services describe ga-personal-api --region=southamerica-east1 --project=guialmeidapersonal

# Verificar logs
gcloud run services logs read ga-personal-api --region=southamerica-east1 --project=guialmeidapersonal --limit=50

# Health check
curl https://api.guialmeidapersonal.esp.br/api/v1/health
```

### Frontend não carrega (Produção)
```bash
# Verificar se os buckets estão acessíveis
curl -I https://admin.guialmeidapersonal.esp.br
curl -I https://app.guialmeidapersonal.esp.br
curl -I https://guialmeidapersonal.esp.br

# Re-deploy frontends se necessário
./infrastructure/gcp/13-deploy-frontends.sh
```

### Erro de SSL/DNS
```bash
# Verificar certificado
gcloud certificate-manager certificates describe ga-personal-cert --project=guialmeidapersonal

# Verificar DNS
gcloud dns record-sets list --zone=guialmeidapersonal --project=guialmeidapersonal
```

## Contato & Suporte

**Cliente:** Guilherme Almeida
**Localização:** Jurerê, Florianópolis/SC
**Especialidades:** Perda de peso, ganho de massa, hybrid training
**Experiência:** 20+ anos

---

**Sistema completo desenvolvido e deployado em 2026-02-03**
**Robustez & Integrações completas em 2026-02-27**
**Status:** ✅ EM PRODUÇÃO
**URLs:**
- API: https://api.guialmeidapersonal.esp.br
- Admin: https://admin.guialmeidapersonal.esp.br
- App: https://app.guialmeidapersonal.esp.br
- Site: https://guialmeidapersonal.esp.br

**Próximos passos:**
- Deploy AI Media Suite em produção (4 migrations + env vars GCS_BUCKET, ANTHROPIC_API_KEY)
- Configurar CORS no bucket GCS ga-personal-media
- Criar conta Asaas sandbox e configurar API key
- Upload de assets (imagens) e UAT com Guilherme
- Testes E2E completos via browser
