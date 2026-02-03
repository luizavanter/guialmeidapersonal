# @ga-personal/shared

Shared frontend package for GA Personal system with design system components, composables, utilities, and bilingual support.

## Features

- **Design System Components**: Button, Input, Textarea, Select, Card, Modal, Badge, Avatar, Table, Chart
- **Composables**: useAuth, useApi, usePagination
- **TypeScript Types**: Full type definitions for all entities
- **i18n Support**: English and Brazilian Portuguese translations
- **Utilities**: Date formatting, validators, formatters
- **Tailwind Config**: GA Personal color palette and design tokens
- **Chart.js Integration**: Pre-configured charts with GA colors

## Installation

```bash
npm install @ga-personal/shared
```

## Setup

### 1. Import Styles

In your main app file:

```typescript
import '@ga-personal/shared/styles'
```

### 2. Configure Tailwind

Extend your Tailwind config:

```javascript
// tailwind.config.js
import sharedConfig from '@ga-personal/shared/tailwind.config'

export default {
  ...sharedConfig,
  content: [
    './src/**/*.{vue,js,ts,jsx,tsx}',
    './node_modules/@ga-personal/shared/dist/**/*.js',
  ],
}
```

### 3. Setup i18n

```typescript
import { createI18n } from '@ga-personal/shared'

const app = createApp(App)
app.use(createI18n())
```

## Components

### Button

```vue
<template>
  <Button variant="primary" size="md" @click="handleClick">
    Save
  </Button>

  <Button variant="secondary" :loading="isLoading">
    Submit
  </Button>

  <Button variant="ghost" rounded>
    <template #icon-left>
      <PlusIcon />
    </template>
    Add Item
  </Button>
</template>

<script setup>
import { Button } from '@ga-personal/shared'
</script>
```

**Props:**
- `variant`: 'primary' | 'secondary' | 'ghost' | 'danger' | 'success'
- `size`: 'sm' | 'md' | 'lg'
- `loading`: boolean
- `disabled`: boolean
- `block`: boolean (full width)
- `rounded`: boolean (pill shape)

### Input

```vue
<template>
  <Input
    v-model="email"
    type="email"
    label="Email"
    placeholder="Enter your email"
    :error="emailError"
    required
  >
    <template #icon-left>
      <MailIcon />
    </template>
  </Input>
</template>

<script setup>
import { ref } from 'vue'
import { Input } from '@ga-personal/shared'

const email = ref('')
const emailError = ref('')
</script>
```

**Props:**
- `modelValue`: string | number
- `type`: 'text' | 'email' | 'password' | 'number' | 'tel' | 'url' | 'date' | etc.
- `label`: string
- `placeholder`: string
- `error`: string
- `hint`: string
- `disabled`: boolean
- `readonly`: boolean
- `required`: boolean

### Select

```vue
<template>
  <Select
    v-model="status"
    label="Status"
    :options="statusOptions"
    placeholder="Select status"
  />
</template>

<script setup>
import { ref } from 'vue'
import { Select } from '@ga-personal/shared'

const status = ref('')
const statusOptions = [
  { label: 'Active', value: 'active' },
  { label: 'Inactive', value: 'inactive' },
]
</script>
```

### Card

```vue
<template>
  <Card title="Student Information" hover>
    <p>Card content goes here</p>

    <template #footer>
      <Button variant="primary">Save</Button>
    </template>
  </Card>
</template>

<script setup>
import { Card, Button } from '@ga-personal/shared'
</script>
```

### Modal

```vue
<template>
  <Button @click="showModal = true">Open Modal</Button>

  <Modal
    v-model="showModal"
    title="Confirm Action"
    size="md"
  >
    <p>Are you sure you want to proceed?</p>

    <template #footer>
      <Button variant="ghost" @click="showModal = false">
        Cancel
      </Button>
      <Button variant="primary" @click="handleConfirm">
        Confirm
      </Button>
    </template>
  </Modal>
</template>

<script setup>
import { ref } from 'vue'
import { Modal, Button } from '@ga-personal/shared'

const showModal = ref(false)
</script>
```

### Badge

```vue
<template>
  <Badge variant="success">Active</Badge>
  <Badge variant="warning" outline>Pending</Badge>
  <Badge variant="danger" rounded>Overdue</Badge>
</template>

<script setup>
import { Badge } from '@ga-personal/shared'
</script>
```

### Avatar

```vue
<template>
  <Avatar
    :src="user.avatarUrl"
    :name="user.name"
    size="lg"
    status="online"
  />
</template>

<script setup>
import { Avatar } from '@ga-personal/shared'
</script>
```

### Table

```vue
<template>
  <Table
    :columns="columns"
    :data="students"
    clickable
    @sort="handleSort"
    @row-click="handleRowClick"
  >
    <template #cell-status="{ value }">
      <Badge :variant="getStatusVariant(value)">
        {{ value }}
      </Badge>
    </template>

    <template #actions="{ row }">
      <Button variant="ghost" size="sm" @click="editStudent(row)">
        Edit
      </Button>
    </template>
  </Table>
</template>

<script setup>
import { Table, Badge, Button } from '@ga-personal/shared'

const columns = [
  { key: 'name', label: 'Name', sortable: true },
  { key: 'email', label: 'Email', sortable: true },
  { key: 'status', label: 'Status', sortable: true },
  {
    key: 'createdAt',
    label: 'Created',
    sortable: true,
    format: (value) => formatDate(value)
  },
]
</script>
```

### Chart

```vue
<template>
  <Chart
    type="line"
    :data="chartData"
    :options="chartOptions"
    :height="300"
  />
</template>

<script setup>
import { Chart } from '@ga-personal/shared'

const chartData = {
  labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
  datasets: [
    {
      label: 'Weight (kg)',
      data: [85, 84, 83, 82, 81, 80],
    },
  ],
}

const chartOptions = {
  plugins: {
    title: {
      display: true,
      text: 'Weight Progress',
    },
  },
}
</script>
```

## Composables

### useAuth

```typescript
import { useAuth } from '@ga-personal/shared'

const {
  user,
  isAuthenticated,
  isTrainer,
  isStudent,
  login,
  logout,
  register,
  updateProfile,
} = useAuth()

// Login
await login({ email: 'user@example.com', password: 'password' })

// Check authentication
if (isAuthenticated.value) {
  console.log('User:', user.value)
}

// Logout
await logout()
```

### useApi

```typescript
import { useApi, API_ENDPOINTS } from '@ga-personal/shared'

const api = useApi()

// GET request
const students = await api.get(API_ENDPOINTS.STUDENTS)

// POST request
const newStudent = await api.post(API_ENDPOINTS.STUDENTS, {
  name: 'John Doe',
  email: 'john@example.com',
})

// PUT request
const updated = await api.put(API_ENDPOINTS.STUDENT('123'), {
  name: 'Jane Doe',
})

// DELETE request
await api.delete(API_ENDPOINTS.STUDENT('123'))

// Loading state
if (api.loading.value) {
  console.log('Loading...')
}

// Error handling
if (api.error.value) {
  console.error('Error:', api.error.value.message)
}
```

### usePagination

```typescript
import { usePagination } from '@ga-personal/shared'

const {
  page,
  perPage,
  total,
  totalPages,
  from,
  to,
  hasNext,
  hasPrev,
  params,
  setPage,
  nextPage,
  prevPage,
  setMeta,
} = usePagination({ initialPerPage: 20 })

// Use with API calls
const fetchStudents = async () => {
  const response = await api.get(API_ENDPOINTS.STUDENTS, {
    params: params.value,
  })
  setMeta(response.meta)
}

// Navigate pages
nextPage() // Go to next page
prevPage() // Go to previous page
setPage(5) // Go to specific page
```

## Utilities

### Date Formatting

```typescript
import { formatDate, formatDateTime, formatTime, getRelativeTime } from '@ga-personal/shared'

formatDate('2024-01-15') // '15/01/2024'
formatDateTime('2024-01-15T10:30:00') // '15/01/2024 10:30'
formatTime('2024-01-15T10:30:00') // '10:30'
getRelativeTime('2024-01-15T10:00:00') // '5 minutos atrás'
```

### Validators

```typescript
import { isEmail, isPhone, isCPF, validateField } from '@ga-personal/shared'

isEmail('user@example.com') // true
isPhone('+55 48 99999-9999') // true
isCPF('123.456.789-00') // true/false

// Field validation with rules
const error = validateField(email, [
  { type: 'required', message: 'Email is required' },
  { type: 'email', message: 'Invalid email format' },
])
```

### Formatters

```typescript
import {
  formatCurrency,
  formatCPF,
  formatPhone,
  formatWeight,
  initials
} from '@ga-personal/shared'

formatCurrency(1500.50) // 'R$ 1.500,50'
formatCPF('12345678900') // '123.456.789-00'
formatPhone('48999998888') // '(48) 99999-8888'
formatWeight(75.5) // '75.5 kg'
initials('John Doe') // 'JD'
```

## Design System

### Colors

- **Coal** (`#0A0A0A`): Primary background
- **Lime** (`#C4F53A`): Primary actions, CTAs
- **Ocean** (`#0EA5E9`): Secondary actions, links
- **Smoke** (`#F5F5F0`): Primary text, light elements

### Typography

- **Display**: Bebas Neue (impact headlines)
- **Body**: Outfit (comfortable reading)
- **Mono**: JetBrains Mono (metrics, data, code)

### Usage

```vue
<h1 class="font-display text-display-lg text-lime">
  GA Personal
</h1>

<p class="font-sans text-smoke">
  Body text with Outfit font
</p>

<code class="font-mono text-sm">
  12.5kg
</code>
```

## i18n Usage

```vue
<template>
  <h1>{{ $t('dashboard.title') }}</h1>
  <p>{{ $t('dashboard.welcome', { name: user.name }) }}</p>

  <Button>{{ $t('common.save') }}</Button>
</template>

<script setup>
import { useI18n } from 'vue-i18n'

const { t, locale } = useI18n()

// Change language
locale.value = 'en-US' // or 'pt-BR'

// Use in script
const message = t('common.loading')
</script>
```

## TypeScript Types

All types are exported from the package:

```typescript
import type {
  User,
  Student,
  Appointment,
  Exercise,
  WorkoutPlan,
  BodyAssessment,
  Goal,
  ApiResponse,
} from '@ga-personal/shared'
```

## License

MIT

---

**Built for GA Personal Training System**
Dark-first design | Bilingual support | TypeScript | Vue 3
