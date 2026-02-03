# GA Personal — Projeto Guilherme Almeida

## Status do Projeto
✅ **Sistema em PRODUÇÃO** (2026-02-03)
- Backend Phoenix com 8 contextos - **DEPLOYED**
- 3 aplicações frontend (Trainer, Student, Site) - **DEPLOYED**
- Suporte bilíngue completo (PT-BR/EN-US)
- 15.000+ linhas de código em produção
- **Todos os endpoints funcionando**
- **Login e navegação testados e funcionando**

## Stack Tecnológica

### Backend
- **Elixir 1.15+ / Phoenix 1.8.3** - API REST com autenticação JWT
- **PostgreSQL 16** - Banco de dados com 20 tabelas
- **Guardian 2.4** - Autenticação JWT com refresh tokens
- **Redis 7** - Cache e blacklist de tokens
- **Gettext** - Internacionalização (PT-BR/EN-US)

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
- **Docker Compose** - PostgreSQL + Redis local

## Estrutura do Projeto

```
ga-personal/
├── apps/
│   ├── ga_personal/           # Core - 8 contextos de negócio
│   └── ga_personal_web/       # API Phoenix - 60+ endpoints
├── frontend/
│   ├── shared/                # @ga-personal/shared - Design system
│   ├── trainer-app/           # Painel do Personal (porta 3001)
│   ├── student-app/           # Portal do Aluno (porta 3002)
│   └── site/                  # Site Marketing VitePress (porta 3003)
├── reference/                 # Designs e especificações originais
├── docs/
│   └── plans/                 # Documentação de design
├── docker-compose.yml
├── MASTER_SUMMARY.md          # Resumo completo do sistema
└── CLAUDE.md                  # Este arquivo
```

## Como Rodar

### Primeira vez (Setup):
```bash
# 1. Backend
cd /Users/luizpenha/guipersonal
./bin/setup        # Cria banco, roda migrations, seeds
mix phx.server     # http://localhost:4000

# 2. Shared Package (em outro terminal)
cd frontend/shared
npm install && npm run build

# 3. Trainer App (em outro terminal)
cd frontend/trainer-app
npm install && npm run dev    # http://localhost:3001

# 4. Student App (em outro terminal)
cd frontend/student-app
npm install && npm run dev    # http://localhost:3002

# 5. Site Marketing (em outro terminal)
cd frontend/site
npm install && npm run dev    # http://localhost:3003
```

### Uso diário:
```bash
# Terminal 1: mix phx.server
# Terminal 2: cd frontend/trainer-app && npm run dev
# Terminal 3: cd frontend/student-app && npm run dev
# Terminal 4: cd frontend/site && npm run dev
```

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

## Contextos do Backend (8 Módulos)

### 1. Accounts
- Usuários, autenticação, perfis
- Roles: `:trainer`, `:student`, `:admin`
- JWT com refresh tokens
- Multi-tenant (dados isolados por trainer)

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
- Subscriptions (assinaturas dos alunos)
- Payments (controle de pagamentos)
- Status: pending, paid, overdue, cancelled

### 6. Messaging
- Messages (mensagens diretas trainer ↔ aluno)
- Notifications (notificações do sistema)
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
- ContactForm (Formspree)
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

## APIs REST (60+ endpoints)

### Autenticação
- `POST /api/v1/auth/register` - Registro
- `POST /api/v1/auth/login` - Login (retorna access + refresh token)
- `POST /api/v1/auth/refresh` - Renovar access token
- `POST /api/v1/auth/logout` - Logout (blacklist refresh token)

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
- `GET /api/v1/subscriptions` - Listar assinaturas
- `POST /api/v1/subscriptions` - Criar assinatura

### Messages
- `GET /api/v1/messages` - Inbox
- `POST /api/v1/messages` - Enviar mensagem
- `PUT /api/v1/messages/:id/read` - Marcar como lida

**Autenticação:** Todas as rotas (exceto login/register) requerem `Authorization: Bearer <access_token>`

**Multi-tenant:** Todas as queries são automaticamente filtradas por `trainer_id`

## Fase 2 (Futuro) - IA & Integrações

### IA Features (não implementado ainda)
- **TensorFlow.js MoveNet** - Detecção de pose no browser
- **Claude API Sonnet** - Análise visual corporal
- **Anovator Collector** - Import automático de bioimpedância

### Integrações Futuras
- WhatsApp Business API - Lembretes automáticos
- Gateway de Pagamento - Pix, cartão
- Email Service - Emails transacionais
- PWA - Progressive Web App
- Analytics - Métricas de uso

## Aparelhos Bioimpedância (Fase 2)
- **Anovator** - Torre profissional, import via URL
- **Relaxmedic Intelligence Plus** - Balança Bluetooth, app RelaxFIT
- **InBody, Tanita, Omron** - Entrada manual
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
- **250+ arquivos criados**
- **15.000+ linhas de código em produção**
- **13.000+ palavras de conteúdo**
- **600+ chaves de tradução**
- **30+ interfaces TypeScript**
- **60+ endpoints de API**

### Componentes
- Backend: 8 contextos, 100+ funções, 20 tabelas
- Shared: 30 arquivos, 10 componentes, 60+ utils
- Trainer: 60+ arquivos, 15 telas
- Student: 40+ arquivos, 8 telas
- Website: 20+ arquivos, 16 páginas

### Tecnologias
- Elixir, Phoenix, Ecto
- Vue 3, TypeScript, Vite
- PostgreSQL, Redis
- Tailwind CSS, Chart.js
- VitePress, Vue I18n

## Status de Produção

### Infraestrutura GCP (Completa)
- [x] VPC Network e Subnet (10.0.0.0/20)
- [x] VPC Connector para Cloud Run
- [x] Cloud SQL PostgreSQL 16 (private IP)
- [x] Memorystore Redis 7.0 (private IP)
- [x] Service Accounts (backend-sa, cicd-sa)
- [x] Secret Manager (database-url, redis-url, jwt-secret, secret-key-base)
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
- [ ] Formspree form ID no ContactForm.vue
- [ ] Info de contato real (telefone, social links)
- [ ] Configurar GitHub Secrets (GCP_WORKLOAD_IDENTITY_PROVIDER, GCP_SERVICE_ACCOUNT)

### Testes Pendentes
- [ ] Testes E2E (Playwright ou Cypress)
- [ ] Testes de integração
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

### Docker
```bash
docker-compose up           # Start PostgreSQL + Redis
docker-compose down         # Stop services
```

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

### Infraestrutura
1. **GCS SPA Routing** - Configurado error page = index.html para suportar rotas client-side
2. **CDN Cache** - Configurado no-cache para index.html, invalidação de CDN após deploys

### Documentação
- Detalhes completos em: `/docs/plans/2026-02-03-frontend-fixes-deployment.md`

## Troubleshooting

### Backend não inicia
```bash
# Verificar se PostgreSQL está rodando
docker-compose up -d postgres

# Recriar banco
mix ecto.reset
```

### Frontend não conecta na API
```bash
# Verificar .env
cat frontend/trainer-app/.env
# Deve ter: VITE_API_URL=http://localhost:4000

# Verificar se backend está rodando
curl http://localhost:4000/api/v1/health
```

### Erro de CORS
```bash
# Verificar configuração em config/dev.exs
# Endpoint deve ter origins: ["http://localhost:3001", "http://localhost:3002", "http://localhost:3003"]
```

## Contato & Suporte

**Cliente:** Guilherme Almeida
**Localização:** Jurerê, Florianópolis/SC
**Especialidades:** Perda de peso, ganho de massa, hybrid training
**Experiência:** 20+ anos

---

**Sistema completo desenvolvido e deployado em 2026-02-03**
**Status:** ✅ EM PRODUÇÃO
**URLs:**
- API: https://api.guialmeidapersonal.esp.br
- Admin: https://admin.guialmeidapersonal.esp.br
- App: https://app.guialmeidapersonal.esp.br
- Site: https://guialmeidapersonal.esp.br

**Próximo passo:** Upload de assets (imagens) e UAT com Guilherme
