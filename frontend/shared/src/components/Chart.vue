<template>
  <div class="chart-wrapper">
    <canvas ref="chartCanvas" />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler,
  type ChartType,
  type ChartOptions,
  type ChartData,
} from 'chart.js'
import { CHART_COLORS } from '@/constants'

// Register Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
)

export interface ChartProps {
  type: ChartType
  data: ChartData
  options?: ChartOptions
  height?: number
}

const props = withDefaults(defineProps<ChartProps>(), {
  height: 300,
})

const chartCanvas = ref<HTMLCanvasElement>()
let chartInstance: ChartJS | null = null

// Default options with GA Personal design system
const defaultOptions: ChartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      labels: {
        color: '#F5F5F0', // smoke
        font: {
          family: 'Outfit, sans-serif',
          size: 12,
        },
        padding: 12,
      },
    },
    tooltip: {
      backgroundColor: '#1A1A1A', // coal-light
      titleColor: '#F5F5F0', // smoke
      bodyColor: '#E5E5E0', // smoke-dark
      borderColor: '#2A2A2A', // coal-lighter
      borderWidth: 1,
      padding: 12,
      cornerRadius: 8,
      titleFont: {
        family: 'Outfit, sans-serif',
        size: 14,
        weight: 'bold',
      },
      bodyFont: {
        family: 'Outfit, sans-serif',
        size: 13,
      },
    },
  },
  scales: {
    x: {
      grid: {
        color: '#2A2A2A', // coal-lighter
        drawOnChartArea: true,
      },
      ticks: {
        color: '#E5E5E0', // smoke-dark
        font: {
          family: 'Outfit, sans-serif',
          size: 11,
        },
      },
    },
    y: {
      grid: {
        color: '#2A2A2A', // coal-lighter
        drawOnChartArea: true,
      },
      ticks: {
        color: '#E5E5E0', // smoke-dark
        font: {
          family: 'Outfit, sans-serif',
          size: 11,
        },
      },
    },
  },
}

const mergeOptions = (custom?: ChartOptions): ChartOptions => {
  if (!custom) return defaultOptions

  return {
    ...defaultOptions,
    ...custom,
    plugins: {
      ...defaultOptions.plugins,
      ...custom.plugins,
    },
    scales: {
      ...defaultOptions.scales,
      ...custom.scales,
    },
  }
}

const applyDefaultColors = (data: ChartData): ChartData => {
  const processedData = { ...data }

  if (processedData.datasets) {
    processedData.datasets = processedData.datasets.map((dataset, index) => {
      const defaultColor = CHART_COLORS.datasets[index % CHART_COLORS.datasets.length]

      return {
        ...dataset,
        backgroundColor: dataset.backgroundColor || CHART_COLORS.backgrounds[index % CHART_COLORS.backgrounds.length],
        borderColor: dataset.borderColor || defaultColor,
        borderWidth: dataset.borderWidth ?? 2,
      }
    })
  }

  return processedData
}

const createChart = () => {
  if (!chartCanvas.value) return

  const processedData = applyDefaultColors(props.data)
  const mergedOptions = mergeOptions(props.options)

  chartInstance = new ChartJS(chartCanvas.value, {
    type: props.type,
    data: processedData,
    options: mergedOptions,
  })
}

const updateChart = () => {
  if (!chartInstance) return

  const processedData = applyDefaultColors(props.data)
  chartInstance.data = processedData

  const mergedOptions = mergeOptions(props.options)
  chartInstance.options = mergedOptions

  chartInstance.update()
}

const destroyChart = () => {
  if (chartInstance) {
    chartInstance.destroy()
    chartInstance = null
  }
}

onMounted(() => {
  createChart()
})

onUnmounted(() => {
  destroyChart()
})

watch(
  () => [props.data, props.options],
  () => {
    updateChart()
  },
  { deep: true }
)

defineExpose({
  chart: chartInstance,
  update: updateChart,
  destroy: destroyChart,
})
</script>

<style scoped>
.chart-wrapper {
  @apply w-full;
}
</style>
