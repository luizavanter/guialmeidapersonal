# 🏋️ GA Personal — Projeto Guilherme Almeida

## Sistema de Gestão para Personal Trainer

---

## 📋 Visão Geral

Sistema completo de gestão para **Guilherme Almeida**, personal trainer atuante no bairro de
Jurerê em Florianópolis/SC. Natural de Pelotas e com mais de 20 anos de vivência na ilha,
Guilherme atende uma vasta carteira de alunos de todas as idades, com foco em emagrecimento,
ganho de massa muscular e hybrid training.

O projeto contempla: **site institucional**, **sistema de gestão (painel do personal)** e
**portal do aluno** — tudo em uma única plataforma moderna e de fácil uso.

---

## 🛠️ Stack Tecnológica

| Camada | Tecnologia | Justificativa |
|---|---|---|
| **Backend** | Elixir + Phoenix | Performance, concorrência, LiveView para real-time |
| **Banco de Dados** | PostgreSQL | Robustez, extensões para geo, JSON, full-text search |
| **Frontend App** | Vue 3 (Composition API) | Reatividade, ecossistema maduro, DX excelente |
| **Site/Docs** | VitePress | Site estático rápido, SEO otimizado, Markdown-based |
| **Estilização** | Tailwind CSS | Utility-first, consistência, responsivo |
| **Auth** | Phoenix Auth + Guardian (JWT) | Segurança, tokens para API e portal do aluno |
| **Deploy** | Fly.io / Gigalixir | Otimizado para Elixir/Phoenix |
| **Storage** | S3 (MinIO ou AWS) | Fotos de evolução, vídeos de exercícios |

---

## 🏗️ Arquitetura do Sistema

```
┌─────────────────────────────────────────────────────────┐
│                    INTERNET / CDN                        │
├─────────────┬──────────────────┬────────────────────────┤
│  VitePress  │   Vue 3 SPA      │   Vue 3 SPA            │
│  (Site)     │   (Painel PT)    │   (Portal Aluno)       │
│  :3000      │   :3001           │   :3002                │
├─────────────┴──────────────────┴────────────────────────┤
│              Phoenix API (JSON + LiveView)                │
│              :4000                                        │
├──────────────────────────────────────────────────────────┤
│              Elixir/OTP Application                       │
│  ┌──────────┬───────────┬──────────┬──────────────────┐  │
│  │ Accounts │ Schedule  │ Workouts │ Evolution        │  │
│  │ Context  │ Context   │ Context  │ Context          │  │
│  ├──────────┼───────────┼──────────┼──────────────────┤  │
│  │ Finance  │ Messaging │ Content  │ Notifications    │  │
│  │ Context  │ Context   │ Context  │ Context          │  │
│  └──────────┴───────────┴──────────┴──────────────────┘  │
├──────────────────────────────────────────────────────────┤
│                    PostgreSQL 16                          │
│              + pg_trgm + PostGIS (futuro)                │
└──────────────────────────────────────────────────────────┘
```

---

## 📐 Contexts (Bounded Contexts — Phoenix)

### 1. `Accounts` — Usuários e Autenticação
- Registro e login (personal + alunos)
- Perfis de usuário com foto, dados pessoais
- Roles: `:trainer`, `:student`, `:admin`
- Recuperação de senha, sessões

### 2. `Schedule` — Agenda e Agendamentos
- Criação de slots de horário recorrentes
- Agendamento por aluno (recorrente ou avulso)
- Confirmação / cancelamento / reagendamento
- Lista de espera para horários lotados
- Visualização diária, semanal e mensal
- Notificações automáticas (WhatsApp API futura)

### 3. `Workouts` — Treinos e Exercícios
- Biblioteca de exercícios (nome, grupo muscular, vídeo, instruções)
- Montagem de planilhas de treino (Treino A, B, C...)
- Exercícios com séries, repetições, carga, descanso
- Templates reutilizáveis por objetivo
- Periodização (mesociclos, microciclos)
- Histórico de treinos por aluno

### 4. `Evolution` — Evolução e Métricas
- Registro de avaliações físicas (peso, medidas, dobras cutâneas)
- Cálculos automáticos (IMC, % gordura, massa magra)
- Fotos comparativas (antes/depois) com upload seguro
- Gráficos de evolução temporal
- Metas personalizadas com tracking de progresso
- Relatórios periódicos automáticos

### 5. `Finance` — Financeiro
- Cadastro de planos e pacotes (mensal, trimestral, avulso)
- Registro de pagamentos e vencimentos
- Controle de inadimplência
- Relatórios de faturamento (mensal, anual)
- Integração futura com gateway de pagamento

### 6. `Messaging` — Comunicação
- Mensagens diretas personal ↔ aluno
- Notificações de treino novo, alteração de horário
- Lembretes automáticos de agendamento
- Avisos e comunicados em massa
- Integração futura com WhatsApp Business API

### 7. `Content` — Conteúdo do Site
- Posts de blog / dicas de treino
- Depoimentos de alunos
- FAQs
- Gerenciamento de conteúdo do VitePress

---

## 🗃️ Schema do Banco de Dados (Principais Tabelas)

```sql
-- ===== ACCOUNTS =====
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'student', -- trainer, student, admin
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    birth_date DATE,
    avatar_url TEXT,
    active BOOLEAN DEFAULT true,
    inserted_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE student_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    trainer_id UUID REFERENCES users(id),
    objective VARCHAR(50), -- emagrecimento, hipertrofia, hybrid, funcional
    health_notes TEXT,
    emergency_contact VARCHAR(255),
    emergency_phone VARCHAR(20),
    start_date DATE,
    inserted_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== SCHEDULE =====
CREATE TABLE time_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID REFERENCES users(id),
    day_of_week INTEGER NOT NULL, -- 0=domingo, 6=sábado
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    max_students INTEGER DEFAULT 1,
    active BOOLEAN DEFAULT true
);

CREATE TABLE appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES users(id),
    trainer_id UUID REFERENCES users(id),
    slot_id UUID REFERENCES time_slots(id),
    scheduled_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- pending, confirmed, cancelled, done, no_show
    recurrence_type VARCHAR(20), -- weekly, biweekly, null
    notes TEXT,
    inserted_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== WORKOUTS =====
CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    muscle_group VARCHAR(100),
    equipment VARCHAR(100),
    instructions TEXT,
    video_url TEXT,
    image_url TEXT,
    difficulty VARCHAR(20), -- beginner, intermediate, advanced
    inserted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE workout_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES users(id),
    trainer_id UUID REFERENCES users(id),
    name VARCHAR(255) NOT NULL, -- "Treino A - Peito/Tríceps"
    objective VARCHAR(50),
    week_number INTEGER,
    mesocycle INTEGER,
    active BOOLEAN DEFAULT true,
    starts_at DATE,
    ends_at DATE,
    notes TEXT,
    inserted_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE workout_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_plan_id UUID REFERENCES workout_plans(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES exercises(id),
    order_index INTEGER NOT NULL,
    sets INTEGER,
    reps VARCHAR(20), -- "10" ou "8-12" ou "até falha"
    weight DECIMAL(6,2),
    rest_seconds INTEGER,
    tempo VARCHAR(20), -- "3-1-2-0"
    notes TEXT
);

CREATE TABLE workout_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES users(id),
    workout_plan_id UUID REFERENCES workout_plans(id),
    workout_exercise_id UUID REFERENCES workout_exercises(id),
    performed_at TIMESTAMPTZ DEFAULT NOW(),
    actual_sets INTEGER,
    actual_reps VARCHAR(20),
    actual_weight DECIMAL(6,2),
    rpe DECIMAL(3,1), -- Rate of Perceived Exertion
    notes TEXT
);

-- ===== EVOLUTION =====
CREATE TABLE body_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES users(id),
    trainer_id UUID REFERENCES users(id),
    assessed_at DATE NOT NULL,
    weight DECIMAL(5,2),
    height DECIMAL(4,2),
    body_fat_percentage DECIMAL(4,1),
    lean_mass DECIMAL(5,2),
    bmi DECIMAL(4,1),
    -- Medidas (cm)
    chest DECIMAL(5,1),
    waist DECIMAL(5,1),
    hip DECIMAL(5,1),
    right_arm DECIMAL(5,1),
    left_arm DECIMAL(5,1),
    right_thigh DECIMAL(5,1),
    left_thigh DECIMAL(5,1),
    right_calf DECIMAL(5,1),
    left_calf DECIMAL(5,1),
    -- Dobras cutâneas (mm)
    triceps_fold DECIMAL(4,1),
    subscapular_fold DECIMAL(4,1),
    suprailiac_fold DECIMAL(4,1),
    abdominal_fold DECIMAL(4,1),
    notes TEXT,
    inserted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE evolution_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES users(id),
    assessment_id UUID REFERENCES body_assessments(id),
    photo_url TEXT NOT NULL,
    photo_type VARCHAR(20), -- front, side, back
    taken_at DATE,
    inserted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES users(id),
    metric VARCHAR(50) NOT NULL, -- weight, body_fat, waist, etc
    target_value DECIMAL(6,2),
    current_value DECIMAL(6,2),
    deadline DATE,
    achieved BOOLEAN DEFAULT false,
    achieved_at TIMESTAMPTZ,
    inserted_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== FINANCE =====
CREATE TABLE plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    sessions_per_week INTEGER,
    duration_months INTEGER,
    price DECIMAL(8,2) NOT NULL,
    active BOOLEAN DEFAULT true
);

CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES users(id),
    plan_id UUID REFERENCES plans(id),
    starts_at DATE NOT NULL,
    ends_at DATE,
    status VARCHAR(20) DEFAULT 'active', -- active, paused, cancelled
    inserted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID REFERENCES subscriptions(id),
    student_id UUID REFERENCES users(id),
    amount DECIMAL(8,2) NOT NULL,
    due_date DATE NOT NULL,
    paid_at TIMESTAMPTZ,
    status VARCHAR(20) DEFAULT 'pending', -- pending, paid, overdue, cancelled
    payment_method VARCHAR(30), -- pix, card, cash, transfer
    notes TEXT,
    inserted_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== MESSAGING =====
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES users(id),
    receiver_id UUID REFERENCES users(id),
    content TEXT NOT NULL,
    read_at TIMESTAMPTZ,
    inserted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255),
    body TEXT,
    read BOOLEAN DEFAULT false,
    data JSONB,
    inserted_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 🗺️ Roadmap de Desenvolvimento

### Fase 1 — Fundação (Semanas 1-4)
- [x] Identidade visual e logo
- [x] Site institucional (VitePress)
- [ ] Setup do projeto Phoenix + PostgreSQL
- [ ] Módulo de autenticação (Accounts)
- [ ] CRUD de alunos
- [ ] Deploy inicial

### Fase 2 — Agenda (Semanas 5-8)
- [ ] Cadastro de slots de horário
- [ ] Agendamento de aulas (personal e aluno)
- [ ] Confirmação e cancelamento
- [ ] Visualização de agenda (dia/semana/mês)
- [ ] Recorrência automática

### Fase 3 — Treinos (Semanas 9-12)
- [ ] Biblioteca de exercícios
- [ ] Montagem de planilhas de treino
- [ ] Portal do aluno — visualização de treinos
- [ ] Registro de execução pelo aluno
- [ ] Templates de treino por objetivo

### Fase 4 — Evolução (Semanas 13-16)
- [ ] Avaliações físicas completas
- [ ] Upload de fotos comparativas
- [ ] Dashboard de evolução com gráficos
- [ ] Metas personalizadas
- [ ] Relatórios automáticos

### Fase 5 — Financeiro + Comunicação (Semanas 17-20)
- [ ] Planos e assinaturas
- [ ] Controle de pagamentos
- [ ] Mensagens diretas
- [ ] Notificações push
- [ ] Relatórios financeiros

### Fase 6 — Polimento + Extras (Semanas 21-24)
- [ ] Integração WhatsApp Business API
- [ ] App PWA (Progressive Web App)
- [ ] SEO avançado do site
- [ ] Analytics e métricas de uso
- [ ] Testes automatizados completos

---

## 🎨 Identidade Visual

**Nome:** GA Personal
**Tagline:** "Transforme seu corpo e sua mentalidade"

**Paleta de Cores:**
- Coal `#0A0A0A` — fundo principal
- Accent (Lima Elétrico) `#C4F53A` — energia, vitalidade, CTA
- Ocean Blue `#0EA5E9` — referência ao mar de Jurerê
- White Smoke `#F5F5F0` — textos claros

**Tipografia:**
- Display: Bebas Neue (títulos impactantes)
- Body: Outfit (leitura confortável)
- Mono: JetBrains Mono (dados, métricas)

**Tom de Comunicação:**
- Profissional mas acessível
- Motivador sem ser agressivo
- Técnico quando necessário, simples sempre

---

## 📁 Estrutura de Pastas do Projeto

```
ga_personal/
├── apps/
│   ├── ga_personal/          # Elixir - core business logic
│   │   ├── lib/
│   │   │   ├── ga_personal/
│   │   │   │   ├── accounts/     # Users, profiles, auth
│   │   │   │   ├── schedule/     # Slots, appointments
│   │   │   │   ├── workouts/     # Exercises, plans, logs
│   │   │   │   ├── evolution/    # Assessments, photos, goals
│   │   │   │   ├── finance/      # Plans, subscriptions, payments
│   │   │   │   ├── messaging/    # Messages, notifications
│   │   │   │   └── content/      # Blog, testimonials
│   │   │   └── ga_personal.ex
│   │   └── priv/
│   │       └── repo/migrations/
│   │
│   └── ga_personal_web/      # Phoenix - API + web interface
│       ├── lib/
│       │   ├── ga_personal_web/
│       │   │   ├── controllers/
│       │   │   ├── channels/
│       │   │   ├── plugs/
│       │   │   └── views/
│       │   └── ga_personal_web.ex
│       └── assets/
│
├── frontend/
│   ├── trainer-app/          # Vue 3 - Painel do Personal
│   │   ├── src/
│   │   │   ├── components/
│   │   │   ├── views/
│   │   │   ├── stores/       # Pinia
│   │   │   ├── composables/
│   │   │   └── router/
│   │   └── package.json
│   │
│   ├── student-app/          # Vue 3 - Portal do Aluno
│   │   ├── src/
│   │   │   ├── components/
│   │   │   ├── views/
│   │   │   ├── stores/
│   │   │   └── router/
│   │   └── package.json
│   │
│   └── site/                 # VitePress - Site institucional
│       ├── docs/
│       │   ├── index.md
│       │   ├── sobre.md
│       │   ├── servicos.md
│       │   └── blog/
│       └── package.json
│
├── docker-compose.yml
├── mix.exs
└── README.md
```

---

## 🚀 Como Rodar (Desenvolvimento)

```bash
# 1. Clone o repositório
git clone https://github.com/ga-personal/ga-personal.git
cd ga-personal

# 2. Setup do banco
mix ecto.setup

# 3. Inicie o Phoenix
mix phx.server

# 4. Em outro terminal - Frontend do Personal
cd frontend/trainer-app
npm install && npm run dev

# 5. Em outro terminal - Portal do Aluno
cd frontend/student-app
npm install && npm run dev

# 6. Em outro terminal - Site
cd frontend/site
npm install && npm run dev
```

---

## 📝 Notas Importantes

- O sistema foi pensado para **crescer incrementalmente** — cada fase entrega valor real
- A prioridade #1 é a **agenda**, pois resolve a dor mais imediata do Guilherme
- O portal do aluno incentiva engajamento e retenção
- A stack Elixir/Phoenix garante performance mesmo com muitos alunos simultâneos
- Vue 3 com Composition API facilita manutenção futura
- VitePress gera um site leve, rápido e ótimo para SEO

---

*Projeto desenvolvido com ❤️ para o Guilherme Almeida — GA Personal*
