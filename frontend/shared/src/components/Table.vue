<template>
  <div class="table-wrapper">
    <div class="table-container">
      <table class="table">
        <thead class="table-header">
          <tr>
            <th
              v-for="column in columns"
              :key="column.key as string"
              :style="{ width: column.width }"
              :class="[
                'table-header-cell',
                column.align ? `text-${column.align}` : 'text-left',
                column.sortable ? 'cursor-pointer select-none hover:bg-surface-3' : ''
              ]"
              @click="column.sortable ? handleSort(column.key as string) : null"
            >
              <div class="flex items-center gap-2" :class="column.align === 'center' ? 'justify-center' : column.align === 'right' ? 'justify-end' : 'justify-start'">
                <span>{{ column.label }}</span>
                <span v-if="column.sortable" class="sort-icon">
                  <svg
                    v-if="sortConfig?.key === column.key && sortConfig?.order === 'asc'"
                    class="w-4 h-4 text-lime"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                  </svg>
                  <svg
                    v-else-if="sortConfig?.key === column.key && sortConfig?.order === 'desc'"
                    class="w-4 h-4 text-lime"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                  </svg>
                  <svg
                    v-else
                    class="w-4 h-4 text-smoke-dark"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4" />
                  </svg>
                </span>
              </div>
            </th>
            <th v-if="$slots.actions" class="table-header-cell text-right">
              Actions
            </th>
          </tr>
        </thead>

        <tbody class="table-body">
          <tr
            v-for="(row, index) in data"
            :key="index"
            class="table-row"
            :class="{ 'cursor-pointer hover:bg-surface-3': clickable }"
            @click="clickable ? handleRowClick(row) : null"
          >
            <td
              v-for="column in columns"
              :key="column.key as string"
              :class="['table-cell', column.align ? `text-${column.align}` : 'text-left']"
            >
              <slot :name="`cell-${column.key as string}`" :row="row" :value="getColumnValue(row, column.key)">
                <span v-if="column.render">
                  {{ column.render(getColumnValue(row, column.key), row) }}
                </span>
                <span v-else-if="column.format">
                  {{ column.format(getColumnValue(row, column.key), row) }}
                </span>
                <span v-else>
                  {{ getColumnValue(row, column.key) }}
                </span>
              </slot>
            </td>
            <td v-if="$slots.actions" class="table-cell text-right">
              <slot name="actions" :row="row" />
            </td>
          </tr>

          <tr v-if="data.length === 0">
            <td :colspan="columns.length + ($slots.actions ? 1 : 0)" class="table-empty">
              <slot name="empty">
                {{ emptyText }}
              </slot>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts" generic="T extends Record<string, any>">
import { ref } from 'vue'
import type { TableColumn, SortConfig } from '@/types'

export interface TableProps<T> {
  columns: TableColumn<T>[]
  data: T[]
  clickable?: boolean
  emptyText?: string
}

const props = withDefaults(defineProps<TableProps<T>>(), {
  clickable: false,
  emptyText: 'No data available',
})

const emit = defineEmits<{
  sort: [config: SortConfig]
  rowClick: [row: T]
}>()

const sortConfig = ref<SortConfig | null>(null)

const getColumnValue = (row: T, key: string | keyof T): any => {
  if (typeof key === 'string' && key.includes('.')) {
    return key.split('.').reduce((obj, k) => obj?.[k], row as any)
  }
  return row[key as keyof T]
}

const handleSort = (key: string) => {
  if (sortConfig.value?.key === key) {
    sortConfig.value.order = sortConfig.value.order === 'asc' ? 'desc' : 'asc'
  } else {
    sortConfig.value = { key, order: 'asc' }
  }
  emit('sort', sortConfig.value)
}

const handleRowClick = (row: T) => {
  emit('rowClick', row)
}
</script>

<style scoped>
.table-wrapper {
  @apply w-full overflow-hidden rounded-ga border border-surface-3;
}

.table-container {
  @apply w-full overflow-x-auto;
}

.table {
  @apply w-full border-collapse;
}

.table-header {
  @apply bg-surface-1 border-b border-surface-3;
}

.table-header-cell {
  @apply px-6 py-4 text-sm font-medium text-smoke whitespace-nowrap;
}

.table-body {
  @apply divide-y divide-surface-3;
}

.table-row {
  @apply transition-colors;
}

.table-cell {
  @apply px-6 py-4 text-sm text-smoke-dark whitespace-nowrap;
}

.table-empty {
  @apply px-6 py-12 text-center text-smoke-dark;
}

.sort-icon {
  @apply flex items-center;
}
</style>
