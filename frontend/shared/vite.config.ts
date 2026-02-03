import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [
    vue()
  ],
  resolve: {
    alias: {
      '@': resolve(__dirname, './src')
    }
  },
  build: {
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),
      name: 'GaPersonalShared',
      formats: ['es', 'umd'],
      fileName: (format) => `ga-personal-shared.${format}.js`
    },
    rollupOptions: {
      external: ['vue', 'axios', 'vue-i18n', 'chart.js', 'vue-chartjs'],
      output: {
        globals: {
          vue: 'Vue',
          axios: 'axios',
          'vue-i18n': 'VueI18n',
          'chart.js': 'Chart',
          'vue-chartjs': 'VueChartjs'
        },
        assetFileNames: (assetInfo) => {
          if (assetInfo.name === 'style.css') return 'style.css'
          return assetInfo.name || ''
        }
      }
    }
  }
})
