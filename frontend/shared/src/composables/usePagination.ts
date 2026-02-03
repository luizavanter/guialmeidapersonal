/**
 * Pagination composable
 */

import { ref, computed, Ref, ComputedRef } from 'vue'
import { PAGINATION } from '@/constants'
import type { PaginationParams, PaginationMeta } from '@/types'

export interface UsePaginationOptions {
  initialPage?: number
  initialPerPage?: number
  initialTotal?: number
}

export interface UsePaginationReturn {
  page: Ref<number>
  perPage: Ref<number>
  total: Ref<number>
  totalPages: ComputedRef<number>
  from: ComputedRef<number>
  to: ComputedRef<number>
  hasNext: ComputedRef<boolean>
  hasPrev: ComputedRef<boolean>
  isFirstPage: ComputedRef<boolean>
  isLastPage: ComputedRef<boolean>
  params: ComputedRef<PaginationParams>
  setPage: (newPage: number) => void
  setPerPage: (newPerPage: number) => void
  setTotal: (newTotal: number) => void
  setMeta: (meta: PaginationMeta) => void
  nextPage: () => void
  prevPage: () => void
  firstPage: () => void
  lastPage: () => void
  reset: () => void
}

export const usePagination = (options: UsePaginationOptions = {}): UsePaginationReturn => {
  const page = ref(options.initialPage || PAGINATION.DEFAULT_PAGE)
  const perPage = ref(options.initialPerPage || PAGINATION.DEFAULT_PER_PAGE)
  const total = ref(options.initialTotal || 0)

  const totalPages = computed(() => {
    if (total.value === 0 || perPage.value === 0) return 0
    return Math.ceil(total.value / perPage.value)
  })

  const from = computed(() => {
    if (total.value === 0) return 0
    return (page.value - 1) * perPage.value + 1
  })

  const to = computed(() => {
    const end = page.value * perPage.value
    return end > total.value ? total.value : end
  })

  const hasNext = computed(() => page.value < totalPages.value)
  const hasPrev = computed(() => page.value > 1)
  const isFirstPage = computed(() => page.value === 1)
  const isLastPage = computed(() => page.value === totalPages.value)

  const params = computed((): PaginationParams => ({
    page: page.value,
    perPage: perPage.value,
  }))

  const setPage = (newPage: number) => {
    if (newPage >= 1 && newPage <= totalPages.value) {
      page.value = newPage
    }
  }

  const setPerPage = (newPerPage: number) => {
    perPage.value = newPerPage
    page.value = 1 // Reset to first page when changing per page
  }

  const setTotal = (newTotal: number) => {
    total.value = newTotal
  }

  const setMeta = (meta: PaginationMeta) => {
    page.value = meta.page
    perPage.value = meta.perPage
    total.value = meta.total
  }

  const nextPage = () => {
    if (hasNext.value) {
      page.value++
    }
  }

  const prevPage = () => {
    if (hasPrev.value) {
      page.value--
    }
  }

  const firstPage = () => {
    page.value = 1
  }

  const lastPage = () => {
    page.value = totalPages.value
  }

  const reset = () => {
    page.value = options.initialPage || PAGINATION.DEFAULT_PAGE
    perPage.value = options.initialPerPage || PAGINATION.DEFAULT_PER_PAGE
    total.value = options.initialTotal || 0
  }

  return {
    page,
    perPage,
    total,
    totalPages,
    from,
    to,
    hasNext,
    hasPrev,
    isFirstPage,
    isLastPage,
    params,
    setPage,
    setPerPage,
    setTotal,
    setMeta,
    nextPage,
    prevPage,
    firstPage,
    lastPage,
    reset,
  }
}
