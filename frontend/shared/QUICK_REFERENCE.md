# GA Personal Shared Package - Quick Reference

## Import Patterns

```typescript
// Components
import {
  Button, Input, Textarea, Select,
  Card, Modal, Badge, Avatar,
  Table, Chart
} from '@ga-personal/shared'

// Composables
import {
  useAuth,
  useApi,
  usePagination
} from '@ga-personal/shared'

// Utils
import {
  formatDate,
  formatCurrency,
  isEmail,
  validateField
} from '@ga-personal/shared'

// Types
import type {
  User,
  Student,
  Appointment,
  ApiResponse
} from '@ga-personal/shared'

// Constants
import {
  API_ENDPOINTS,
  COLORS,
  CHART_COLORS
} from '@ga-personal/shared'

// i18n
import { createI18n } from '@ga-personal/shared'
```

---

## Common Patterns

### Authentication Flow

```typescript
import { useAuth } from '@ga-personal/shared'

const { user, isAuthenticated, login, logout } = useAuth()

// Login
const handleLogin = async () => {
  try {
    await login({
      email: email.value,
      password: password.value
    })
    router.push('/dashboard')
  } catch (error) {
    console.error('Login failed:', error)
  }
}

// Check auth in router guard
router.beforeEach((to, from, next) => {
  if (to.meta.requiresAuth && !isAuthenticated.value) {
    next('/login')
  } else {
    next()
  }
})
```

---

### API Calls with Pagination

```typescript
import { useApi, usePagination, API_ENDPOINTS } from '@ga-personal/shared'

const api = useApi()
const pagination = usePagination({ initialPerPage: 20 })
const students = ref([])

const fetchStudents = async () => {
  try {
    const response = await api.get(API_ENDPOINTS.STUDENTS, {
      params: pagination.params.value
    })
    students.value = response.data
    pagination.setMeta(response.meta)
  } catch (error) {
    console.error('Failed to fetch students:', error)
  }
}

// Watch pagination changes
watch(() => pagination.page.value, fetchStudents)
```

---

### Form Validation

```typescript
import { ref, computed } from 'vue'
import { validateField, isEmail, isRequired } from '@ga-personal/shared'

const email = ref('')
const emailError = computed(() => {
  return validateField(email.value, [
    { type: 'required', message: 'Email is required' },
    { type: 'email', message: 'Invalid email format' }
  ])
})

const isFormValid = computed(() => {
  return !emailError.value && email.value.length > 0
})
```

---

### Data Table with Actions

```vue
<template>
  <Table
    :columns="columns"
    :data="students"
    @sort="handleSort"
  >
    <template #cell-status="{ value }">
      <Badge :variant="value === 'active' ? 'success' : 'default'">
        {{ value }}
      </Badge>
    </template>

    <template #actions="{ row }">
      <div class="flex gap-2">
        <Button variant="ghost" size="sm" @click="editStudent(row)">
          Edit
        </Button>
        <Button variant="danger" size="sm" @click="deleteStudent(row)">
          Delete
        </Button>
      </div>
    </template>
  </Table>
</template>

<script setup>
import { Table, Button, Badge } from '@ga-personal/shared'

const columns = [
  { key: 'name', label: 'Name', sortable: true },
  { key: 'email', label: 'Email', sortable: true },
  { key: 'status', label: 'Status' },
  {
    key: 'createdAt',
    label: 'Created',
    format: (date) => formatDate(date)
  }
]
</script>
```

---

### Modal Workflow

```vue
<template>
  <Button @click="showModal = true">
    Add Student
  </Button>

  <Modal v-model="showModal" title="Add New Student">
    <form @submit.prevent="handleSubmit">
      <Input
        v-model="form.name"
        label="Name"
        :error="errors.name"
        required
      />

      <Input
        v-model="form.email"
        type="email"
        label="Email"
        :error="errors.email"
        required
      />
    </form>

    <template #footer>
      <Button variant="ghost" @click="showModal = false">
        Cancel
      </Button>
      <Button
        variant="primary"
        :loading="saving"
        @click="handleSubmit"
      >
        Save
      </Button>
    </template>
  </Modal>
</template>

<script setup>
import { ref } from 'vue'
import { Modal, Button, Input, useApi } from '@ga-personal/shared'

const showModal = ref(false)
const saving = ref(false)
const form = ref({ name: '', email: '' })
const errors = ref({})
</script>
```

---

### Chart Integration

```vue
<template>
  <Card title="Weight Progress">
    <Chart
      type="line"
      :data="chartData"
      :height="300"
    />
  </Card>
</template>

<script setup>
import { computed } from 'vue'
import { Card, Chart, formatDate } from '@ga-personal/shared'

const assessments = ref([])

const chartData = computed(() => ({
  labels: assessments.value.map(a => formatDate(a.assessedAt)),
  datasets: [{
    label: 'Weight (kg)',
    data: assessments.value.map(a => a.weight),
    tension: 0.4
  }]
}))
</script>
```

---

### i18n Usage

```vue
<template>
  <div>
    <h1>{{ $t('dashboard.title') }}</h1>
    <p>{{ $t('dashboard.welcome', { name: user.firstName }) }}</p>

    <Button>{{ $t('common.save') }}</Button>

    <select v-model="locale">
      <option value="pt-BR">Português</option>
      <option value="en-US">English</option>
    </select>
  </div>
</template>

<script setup>
import { useI18n } from 'vue-i18n'
import { Button } from '@ga-personal/shared'

const { t, locale } = useI18n()

// Use in JS
const successMessage = t('success.saved')
</script>
```

---

## Tailwind Classes Reference

### Colors

```html
<!-- Backgrounds -->
<div class="bg-coal">Dark background</div>
<div class="bg-coal-light">Card background</div>
<div class="bg-lime">Primary CTA</div>
<div class="bg-ocean">Secondary action</div>

<!-- Text -->
<p class="text-smoke">Primary text</p>
<p class="text-smoke-dark">Secondary text</p>
<p class="text-lime">Accent text</p>

<!-- Borders -->
<div class="border border-coal-lighter">Subtle border</div>
<div class="border border-lime">Accent border</div>
```

### Typography

```html
<!-- Display fonts -->
<h1 class="font-display text-display-xl text-lime">Hero Title</h1>
<h2 class="font-display text-display-lg">Page Title</h2>

<!-- Body text -->
<p class="font-sans text-smoke">Body content</p>

<!-- Monospace -->
<code class="font-mono text-sm">12.5kg</code>
```

### Utility Classes

```html
<!-- Focus ring -->
<input class="focus-ring" />

<!-- Card -->
<div class="card">Card content</div>

<!-- Animations -->
<div class="animate-fade-in">Fades in</div>
<div class="animate-slide-up">Slides up</div>

<!-- Glass effect -->
<div class="glass p-6">Glass morphism</div>

<!-- Text gradients -->
<h1 class="text-gradient-lime">Gradient text</h1>
```

---

## Component Props Quick Ref

### Button
- variant: primary | secondary | ghost | danger | success
- size: sm | md | lg
- loading, disabled, block, rounded

### Input/Textarea/Select
- v-model, label, placeholder
- error, hint
- required, disabled, readonly

### Card
- title, padding: sm | md | lg
- hover, clickable

### Modal
- v-model, title
- size: sm | md | lg | xl | full
- showClose, closeOnOverlay

### Badge
- variant: default | primary | success | warning | danger | info
- size: sm | md | lg
- rounded, outline

### Avatar
- src, name, alt
- size: xs | sm | md | lg | xl | 2xl
- rounded: square | rounded | full
- status: online | offline | busy | away

### Table
- columns: Array<TableColumn>
- data: Array<any>
- clickable, emptyText

### Chart
- type: line | bar | pie | doughnut | radar | polarArea
- data: ChartData
- options: ChartOptions
- height: number

---

## Utility Functions Quick Ref

### Date
```typescript
formatDate('2024-01-15')           // '15/01/2024'
formatDateTime(date)                // '15/01/2024 10:30'
getRelativeTime(date)               // '5 minutos atrás'
addDays(date, 7)                    // Date + 7 days
getDaysBetween(date1, date2)        // number
```

### Validators
```typescript
isEmail('user@example.com')         // boolean
isPhone('+55 48 99999-9999')       // boolean
isCPF('123.456.789-00')            // boolean
isRequired(value)                   // boolean
validateField(value, rules)         // error string | null
```

### Formatters
```typescript
formatCurrency(1500.50)             // 'R$ 1.500,50'
formatCPF('12345678900')           // '123.456.789-00'
formatPhone('48999998888')         // '(48) 99999-8888'
formatWeight(75.5)                 // '75.5 kg'
initials('John Doe')               // 'JD'
truncate('Long text...', 10)       // 'Long te...'
```

---

## Constants Quick Ref

```typescript
// API
API_ENDPOINTS.STUDENTS              // '/students'
API_ENDPOINTS.STUDENT('123')        // '/students/123'

// Colors
COLORS.coal                         // '#0A0A0A'
COLORS.lime                         // '#C4F53A'

// Chart colors
CHART_COLORS.primary                // lime
CHART_COLORS.datasets[0]            // First dataset color

// Pagination
PAGINATION.DEFAULT_PER_PAGE         // 20

// Status options
STATUS_OPTIONS.student              // [{ value: 'active', label: 'Active' }, ...]
```

---

## Type Definitions Quick Ref

```typescript
// User
interface User {
  id: string
  email: string
  role: 'trainer' | 'student' | 'admin'
  firstName: string
  lastName: string
  phone?: string
  avatarUrl?: string
  locale: 'en-US' | 'pt-BR'
}

// API Response
interface ApiResponse<T> {
  data: T
  meta?: PaginationMeta
  errors?: ApiError[]
}

// Table Column
interface TableColumn<T> {
  key: keyof T | string
  label: string
  sortable?: boolean
  width?: string
  align?: 'left' | 'center' | 'right'
  format?: (value: any, row: T) => string
  render?: (value: any, row: T) => any
}
```

---

## Project Structure

```
frontend/shared/
├── src/
│   ├── components/         # 10 UI components
│   │   ├── Button.vue
│   │   ├── Input.vue
│   │   ├── Textarea.vue
│   │   ├── Select.vue
│   │   ├── Card.vue
│   │   ├── Modal.vue
│   │   ├── Badge.vue
│   │   ├── Avatar.vue
│   │   ├── Table.vue
│   │   └── Chart.vue
│   ├── composables/        # 3 composables
│   │   ├── useAuth.ts
│   │   ├── useApi.ts
│   │   └── usePagination.ts
│   ├── types/              # TypeScript types
│   │   └── index.ts
│   ├── constants/          # Constants & config
│   │   └── index.ts
│   ├── utils/              # Utility functions
│   │   ├── date.ts
│   │   ├── validators.ts
│   │   └── format.ts
│   ├── i18n/               # Internationalization
│   │   ├── index.ts
│   │   └── locales/
│   │       ├── en-US.json
│   │       └── pt-BR.json
│   ├── styles/             # Global styles
│   │   └── main.css
│   └── index.ts            # Main export
├── package.json
├── tsconfig.json
├── vite.config.ts
├── tailwind.config.js
└── README.md
```

---

**Package Stats:**
- **27 source files**
- **4,168 lines of code**
- **10 components**
- **3 composables**
- **60+ utility functions**
- **30+ TypeScript types**
- **2 languages (PT-BR, EN-US)**

**Design System:**
- 4 brand colors + variants
- 3 font families
- Custom spacing, animations, shadows
- Dark-first approach

**Ready for:**
- Trainer Dashboard App
- Student Portal App
- Marketing Website

---

**Built with:** Vue 3 + TypeScript + Vite + Tailwind CSS + Chart.js
