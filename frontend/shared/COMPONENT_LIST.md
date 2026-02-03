# GA Personal Shared Package - Component List

## Package Overview

**Location:** `/Users/luizpenha/guipersonal/frontend/shared/`
**Package Name:** `@ga-personal/shared`
**Version:** 0.1.0

Complete shared frontend package with design system, utilities, and bilingual support.

---

## 1. Design System Components

### Button Component
**File:** `src/components/Button.vue`

**Variants:**
- `primary` - Lime background, coal text (main CTAs)
- `secondary` - Ocean background, white text
- `ghost` - Transparent with border, hover effects
- `danger` - Red for destructive actions
- `success` - Green for positive actions

**Sizes:** `sm`, `md`, `lg`

**Features:**
- Loading state with spinner
- Icon slots (left/right)
- Disabled state
- Block (full width) option
- Rounded (pill shape) option
- Active scale animation

**Usage:**
```vue
<Button variant="primary" size="md" :loading="saving" @click="save">
  Save Changes
</Button>
```

---

### Input Component
**File:** `src/components/Input.vue`

**Types:** text, email, password, number, tel, url, search, date, time, datetime-local

**Features:**
- Label with required indicator
- Icon slots (left/right)
- Error and hint messages
- Disabled/readonly states
- Dark-first design with coal backgrounds
- Focus ring with lime accent
- Auto-complete support

**Usage:**
```vue
<Input
  v-model="email"
  type="email"
  label="Email Address"
  placeholder="you@example.com"
  :error="errors.email"
  required
>
  <template #icon-left>
    <MailIcon />
  </template>
</Input>
```

---

### Textarea Component
**File:** `src/components/Textarea.vue`

**Features:**
- Label with required indicator
- Character counter with max length
- Error and hint messages
- Resizable vertically
- Rows configuration
- Dark-first styling

**Usage:**
```vue
<Textarea
  v-model="notes"
  label="Notes"
  :rows="4"
  :max-length="500"
  placeholder="Enter your notes..."
/>
```

---

### Select Component
**File:** `src/components/Select.vue`

**Features:**
- Label with required indicator
- Options array with label/value pairs
- Disabled options support
- Custom icon indicator
- Error and hint messages
- Dark-first styling

**Usage:**
```vue
<Select
  v-model="status"
  label="Status"
  :options="[
    { label: 'Active', value: 'active' },
    { label: 'Inactive', value: 'inactive' }
  ]"
  placeholder="Select status"
/>
```

---

### Card Component
**File:** `src/components/Card.vue`

**Features:**
- Header, body, and footer slots
- Optional title
- Padding options: none, sm, md, lg
- Hover effect with lime border
- Clickable variant
- Dark-first with coal backgrounds

**Usage:**
```vue
<Card title="Student Profile" hover clickable>
  <p>Card content here</p>

  <template #footer>
    <Button variant="primary">Save</Button>
  </template>
</Card>
```

---

### Modal Component
**File:** `src/components/Modal.vue`

**Sizes:** sm, md, lg, xl, full

**Features:**
- Backdrop blur overlay
- Close button (optional)
- Close on overlay click (optional)
- Header, body, footer slots
- Prevents body scroll when open
- Scale-in animation
- Teleported to body

**Usage:**
```vue
<Modal v-model="showModal" title="Confirm Delete" size="md">
  <p>Are you sure you want to delete this student?</p>

  <template #footer>
    <Button variant="ghost" @click="showModal = false">Cancel</Button>
    <Button variant="danger" @click="confirmDelete">Delete</Button>
  </template>
</Modal>
```

---

### Badge Component
**File:** `src/components/Badge.vue`

**Variants:** default, primary, success, warning, danger, info

**Sizes:** sm, md, lg

**Features:**
- Solid or outline style
- Rounded or pill shape
- Color-coded variants
- Inline display

**Usage:**
```vue
<Badge variant="success">Active</Badge>
<Badge variant="warning" outline>Pending</Badge>
<Badge variant="danger" rounded>Overdue</Badge>
```

---

### Avatar Component
**File:** `src/components/Avatar.vue`

**Sizes:** xs, sm, md, lg, xl, 2xl

**Rounded Options:** square, rounded, full

**Features:**
- Image with fallback to initials
- Automatic initials from name
- Status indicator (online, offline, busy, away)
- Fallback on image error
- Multiple shape options

**Usage:**
```vue
<Avatar
  :src="user.avatarUrl"
  :name="user.name"
  size="lg"
  status="online"
  rounded="full"
/>
```

---

### Table Component
**File:** `src/components/Table.vue`

**Features:**
- Sortable columns with visual indicators
- Column formatting and rendering
- Custom cell slots
- Actions column slot
- Empty state slot
- Clickable rows
- Responsive with horizontal scroll
- Dark-first design

**Usage:**
```vue
<Table
  :columns="[
    { key: 'name', label: 'Name', sortable: true },
    { key: 'email', label: 'Email' },
    { key: 'status', label: 'Status', format: (v) => capitalize(v) }
  ]"
  :data="students"
  clickable
  @sort="handleSort"
  @row-click="viewStudent"
>
  <template #cell-status="{ value }">
    <Badge :variant="getStatusColor(value)">{{ value }}</Badge>
  </template>

  <template #actions="{ row }">
    <Button variant="ghost" size="sm">Edit</Button>
  </template>
</Table>
```

---

### Chart Component
**File:** `src/components/Chart.vue`

**Chart Types:** line, bar, pie, doughnut, radar, polarArea

**Features:**
- Chart.js integration
- Pre-configured with GA colors
- Automatic color assignment
- Dark-first theme
- Responsive
- Custom options support
- Tooltips with GA styling

**Usage:**
```vue
<Chart
  type="line"
  :data="{
    labels: ['Jan', 'Feb', 'Mar', 'Apr'],
    datasets: [{
      label: 'Weight (kg)',
      data: [85, 84, 83, 82]
    }]
  }"
  :height="300"
/>
```

---

## 2. Composables

### useAuth
**File:** `src/composables/useAuth.ts`

**Features:**
- User state management
- Login/logout/register
- Token refresh
- Profile updates
- Role checking (trainer, student, admin)
- Authentication guards
- Persistent session

**Exports:**
```typescript
{
  user,               // Current user ref
  isAuthenticated,    // Computed boolean
  isTrainer,          // Computed boolean
  isStudent,          // Computed boolean
  isAdmin,            // Computed boolean
  loading,            // Loading state
  error,              // Error state
  login,              // (credentials) => Promise<User>
  logout,             // () => Promise<void>
  register,           // (userData) => Promise<User>
  refreshToken,       // () => Promise<void>
  updateProfile,      // (data) => Promise<User>
  checkAuth,          // () => boolean
  requireAuth,        // () => void (throws if not authenticated)
  requireRole,        // (role) => void (throws if insufficient permissions)
}
```

---

### useApi
**File:** `src/composables/useApi.ts`

**Features:**
- Axios wrapper with interceptors
- Automatic token injection
- Token refresh on 401
- Loading and error state
- API response unwrapping
- Locale header injection
- Type-safe requests

**Exports:**
```typescript
{
  loading,     // Ref<boolean>
  error,       // Ref<ApiError | null>
  get,         // <T>(url, config?) => Promise<T>
  post,        // <T>(url, data?, config?) => Promise<T>
  put,         // <T>(url, data?, config?) => Promise<T>
  patch,       // <T>(url, data?, config?) => Promise<T>
  delete,      // <T>(url, config?) => Promise<T>
  request,     // <T>(config) => Promise<T>
  instance,    // AxiosInstance
}
```

---

### usePagination
**File:** `src/composables/usePagination.ts`

**Features:**
- Page state management
- Computed pagination values
- Navigation helpers
- Meta data syncing
- Reset functionality

**Exports:**
```typescript
{
  page,          // Ref<number>
  perPage,       // Ref<number>
  total,         // Ref<number>
  totalPages,    // Computed<number>
  from,          // Computed<number>
  to,            // Computed<number>
  hasNext,       // Computed<boolean>
  hasPrev,       // Computed<boolean>
  isFirstPage,   // Computed<boolean>
  isLastPage,    // Computed<boolean>
  params,        // Computed<PaginationParams>
  setPage,       // (page) => void
  setPerPage,    // (perPage) => void
  setTotal,      // (total) => void
  setMeta,       // (meta) => void
  nextPage,      // () => void
  prevPage,      // () => void
  firstPage,     // () => void
  lastPage,      // () => void
  reset,         // () => void
}
```

---

## 3. Utilities

### Date Utilities
**File:** `src/utils/date.ts`

**Functions:**
- `formatDate(date, format)` - Format date string
- `formatDateTime(date)` - Format date with time
- `formatTime(date)` - Format time only
- `parseDate(dateStr)` - Parse date string
- `isToday(date)` - Check if date is today
- `isTomorrow(date)` - Check if date is tomorrow
- `isYesterday(date)` - Check if date is yesterday
- `getRelativeTime(date, locale)` - "5 minutos atrás"
- `addDays(date, days)` - Add days to date
- `addWeeks(date, weeks)` - Add weeks to date
- `addMonths(date, months)` - Add months to date
- `getDaysBetween(date1, date2)` - Days between dates
- `getStartOfDay(date)` - Start of day
- `getEndOfDay(date)` - End of day
- `getStartOfWeek(date)` - Start of week
- `getEndOfWeek(date)` - End of week
- `getStartOfMonth(date)` - Start of month
- `getEndOfMonth(date)` - End of month
- `isValidDate(date)` - Validate date
- `formatDuration(minutes, locale)` - "1h 30min"

---

### Validators
**File:** `src/utils/validators.ts`

**Functions:**
- `isRequired(value)` - Check if value exists
- `isEmail(email)` - Validate email format
- `isPhone(phone)` - Validate phone format
- `isUrl(url)` - Validate URL
- `isPassword(password)` - Validate password strength
- `minLength(value, min)` - Check minimum length
- `maxLength(value, max)` - Check maximum length
- `min(value, minValue)` - Check minimum value
- `max(value, maxValue)` - Check maximum value
- `isNumeric(value)` - Check if numeric
- `isInteger(value)` - Check if integer
- `isPositive(value)` - Check if positive
- `isNegative(value)` - Check if negative
- `isBetween(value, min, max)` - Check if in range
- `matches(value, pattern)` - Check regex match
- `isDate(value)` - Validate date
- `isAfter(date, compareDate)` - Check if date is after
- `isBefore(date, compareDate)` - Check if date is before
- `isCPF(cpf)` - Validate Brazilian CPF
- `isCNPJ(cnpj)` - Validate Brazilian CNPJ
- `validateField(value, rules)` - Validate with rules array

---

### Formatters
**File:** `src/utils/format.ts`

**Functions:**
- `formatCurrency(value, currency, locale)` - "R$ 1.500,50"
- `formatNumber(value, decimals, locale)` - "1.500,50"
- `formatPercent(value, decimals, locale)` - "75,5%"
- `formatCPF(cpf)` - "123.456.789-00"
- `formatCNPJ(cnpj)` - "12.345.678/0001-00"
- `formatPhone(phone)` - "(48) 99999-8888"
- `formatCEP(cep)` - "88000-000"
- `formatWeight(kg, locale)` - "75.5 kg"
- `formatHeight(cm, locale)` - "175 cm"
- `formatBodyFat(percentage, locale)` - "18.5%"
- `formatMeasurement(cm, locale)` - "42 cm"
- `formatFileSize(bytes)` - "1.5 MB"
- `truncate(text, length, suffix)` - Truncate with "..."
- `capitalize(text)` - Capitalize first letter
- `titleCase(text)` - Title Case Text
- `kebabCase(text)` - kebab-case-text
- `camelCase(text)` - camelCaseText
- `snakeCase(text)` - snake_case_text
- `pluralize(count, singular, plural)` - "1 item" / "2 items"
- `initials(name)` - "JD" from "John Doe"
- `maskEmail(email)` - "jo***@example.com"
- `maskPhone(phone)` - "(48) ****-8888"
- `slugify(text)` - "hello-world"

---

## 4. TypeScript Types

**File:** `src/types/index.ts`

**Core Entities:**
- `User` - User account
- `Student` - Student profile
- `Appointment` - Schedule appointment
- `Exercise` - Exercise definition
- `WorkoutPlan` - Workout plan
- `WorkoutExercise` - Exercise in plan
- `WorkoutLog` - Completed workout log
- `BodyAssessment` - Body measurements
- `EvolutionPhoto` - Progress photo
- `Goal` - Student goal
- `Message` - Direct message
- `Notification` - System notification
- `Plan` - Subscription plan
- `Subscription` - Student subscription
- `Payment` - Payment record

**API Types:**
- `ApiResponse<T>` - Standard API response
- `ApiError` - Error object
- `PaginationParams` - Pagination query params
- `PaginationMeta` - Pagination metadata
- `LoginCredentials` - Login request
- `AuthTokens` - Access/refresh tokens
- `AuthResponse` - Login/register response

**UI Types:**
- `ChartData` - Chart.js data
- `ChartDataset` - Chart dataset
- `FormField` - Form field configuration
- `SelectOption` - Select option
- `ValidationRule` - Validation rule
- `FilterConfig` - Filter configuration
- `TableColumn<T>` - Table column definition
- `SortConfig` - Sort configuration

---

## 5. Constants

**File:** `src/constants/index.ts`

**API Configuration:**
- `API_BASE_URL` - Base URL for API
- `API_VERSION` - API version
- `API_TIMEOUT` - Request timeout

**API Endpoints:**
```typescript
API_ENDPOINTS = {
  LOGIN, LOGOUT, REFRESH, REGISTER,
  STUDENTS, STUDENT(id),
  APPOINTMENTS, APPOINTMENT(id),
  EXERCISES, EXERCISE(id),
  WORKOUT_PLANS, WORKOUT_PLAN(id),
  // ... and more
}
```

**Storage Keys:**
- `ACCESS_TOKEN`
- `REFRESH_TOKEN`
- `USER`
- `LOCALE`
- `THEME`

**Colors:**
```typescript
COLORS = {
  coal: '#0A0A0A',
  lime: '#C4F53A',
  ocean: '#0EA5E9',
  smoke: '#F5F5F0',
  // ... with variants
}
```

**Chart Colors:**
```typescript
CHART_COLORS = {
  primary, secondary, success, warning, danger, info,
  datasets: [...], // 6 colors
  backgrounds: [...], // With opacity
  borders: [...],
}
```

**Other Constants:**
- `PAGINATION` - Pagination defaults
- `DATE_FORMATS` - Date format strings
- `STATUS_OPTIONS` - Status dropdowns
- `MUSCLE_GROUPS` - Exercise categories
- `EQUIPMENT_TYPES` - Equipment options
- `DIFFICULTY_LEVELS` - Exercise difficulty
- `GOAL_TYPES` - Goal categories
- `PAYMENT_METHODS` - Payment options
- `NOTIFICATION_TYPES` - Notification categories
- `DAYS_OF_WEEK` - Day options
- `REGEX` - Common patterns
- `VALIDATION_MESSAGES` - Error messages

---

## 6. i18n (Internationalization)

**Files:**
- `src/i18n/index.ts` - i18n setup
- `src/i18n/locales/pt-BR.json` - Portuguese (Brazil)
- `src/i18n/locales/en-US.json` - English (US)

**Supported Languages:**
- Portuguese (PT-BR) - Default
- English (EN-US) - Fallback

**Translation Namespaces:**
- `common` - Common UI strings
- `auth` - Authentication
- `nav` - Navigation
- `dashboard` - Dashboard
- `students` - Student management
- `appointments` - Appointments
- `agenda` - Calendar/Schedule
- `workouts` - Workout management
- `evolution` - Progress tracking
- `finance` - Financial management
- `messages` - Messaging
- `validation` - Validation errors
- `errors` - Error messages
- `success` - Success messages

**Setup:**
```typescript
import { createI18n } from '@ga-personal/shared'
app.use(createI18n())
```

**Usage:**
```vue
<template>
  {{ $t('students.title') }}
  {{ $t('common.save') }}
</template>

<script setup>
import { useI18n } from 'vue-i18n'
const { t, locale } = useI18n()

// Change language
locale.value = 'en-US'
</script>
```

---

## 7. Styles

**File:** `src/styles/main.css`

**Includes:**
- Google Fonts import (Bebas Neue, Outfit, JetBrains Mono)
- Tailwind base, components, utilities
- Custom base styles (body, headings, scrollbar)
- Component utilities (focus-ring, card, btn-base)
- Animation utilities (fade-in, slide-up, scale-in)
- Text gradient utilities
- Glass morphism effect

**Custom Classes:**
- `.focus-ring` - Focus outline with lime
- `.card` - Card container
- `.btn-base` - Button base styles
- `.text-gradient-lime` - Lime gradient text
- `.text-gradient-ocean` - Ocean gradient text
- `.glass` - Glass morphism effect

---

## 8. Design System

### Color Palette

**Primary Colors:**
- **Coal** (`#0A0A0A`) - Main background, dark surfaces
- **Lime** (`#C4F53A`) - Primary CTAs, accents, highlights
- **Ocean** (`#0EA5E9`) - Secondary actions, links, info
- **Smoke** (`#F5F5F0`) - Primary text, light elements

**Extended Colors:**
- `coal-light` (`#1A1A1A`) - Card backgrounds
- `coal-lighter` (`#2A2A2A`) - Borders, dividers
- `lime-dark` (`#A8D32E`) - Hover states
- `ocean-dark` (`#0C87BB`) - Hover states
- `smoke-dark` (`#E5E5E0`) - Secondary text

### Typography

**Font Families:**
```css
font-display: Bebas Neue     /* Impact headlines, titles */
font-sans: Outfit             /* Body text, UI elements */
font-mono: JetBrains Mono     /* Metrics, code, data */
```

**Display Sizes:**
```css
text-display-xl: 4.5rem       /* Hero headlines */
text-display-lg: 3.5rem       /* Page titles */
text-display-md: 2.5rem       /* Section headers */
text-display-sm: 2rem         /* Card titles */
```

### Spacing

Standard Tailwind spacing + custom:
- `18` (4.5rem)
- `22` (5.5rem)
- `26` (6.5rem)

### Border Radius

- `rounded-ga` (0.75rem) - Brand consistent radius

### Shadows

- `shadow-ga` - Lime glow effect
- `shadow-ga-lg` - Larger lime glow
- `shadow-coal` - Dark shadow for modals

### Animations

- `animate-fade-in` - Fade in
- `animate-slide-up` - Slide up
- `animate-slide-down` - Slide down
- `animate-scale-in` - Scale in (modals)

---

## 9. Build Configuration

### Vite Config
**File:** `vite.config.ts`

- Library mode build
- ES and UMD formats
- Type declarations with DTS plugin
- External dependencies (Vue, axios, etc.)
- Path aliases (@/)

### TypeScript Config
**Files:** `tsconfig.json`, `tsconfig.node.json`

- Strict mode enabled
- DOM types
- Vue 3 support
- Path aliases
- Declaration generation

### Tailwind Config
**File:** `tailwind.config.js`

- Extended color palette
- Custom font families
- Custom spacing
- Custom animations
- Dark mode class strategy

---

## 10. Usage Quick Start

### Installation

```bash
cd /Users/luizpenha/guipersonal/frontend/shared
npm install
```

### Development

```bash
npm run dev      # Start dev server
npm run build    # Build library
npm run type-check  # Check TypeScript
```

### In Another Project

```json
{
  "dependencies": {
    "@ga-personal/shared": "file:../shared"
  }
}
```

```typescript
// main.ts
import { createI18n } from '@ga-personal/shared'
import '@ga-personal/shared/styles'

app.use(createI18n())
```

```vue
<!-- Component.vue -->
<script setup>
import {
  Button,
  Input,
  Card,
  useAuth,
  useApi,
  formatDate
} from '@ga-personal/shared'
</script>
```

---

## Summary

**Total Components:** 10 (Button, Input, Textarea, Select, Card, Modal, Badge, Avatar, Table, Chart)

**Total Composables:** 3 (useAuth, useApi, usePagination)

**Total Utilities:** 60+ functions across date, validators, formatters

**Total Types:** 30+ TypeScript interfaces

**i18n:** Full bilingual support (PT-BR/EN-US)

**Design System:** Complete color palette, typography, spacing

**Ready for:** Trainer App, Student App, Marketing Site

---

Built with Vue 3, TypeScript, Tailwind CSS, and Chart.js
Dark-first design | Type-safe | Accessible | Bilingual
