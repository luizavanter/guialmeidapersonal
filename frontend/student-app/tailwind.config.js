/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{vue,js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        coal: '#0A0A0A',
        lime: '#C4F53A',
        ocean: '#0EA5E9',
        smoke: '#F5F5F0',
        'surface-1': '#121212',
        'surface-2': '#1A1A1A',
        'surface-3': '#2A2A2A',
      },
      fontFamily: {
        display: ['Bebas Neue', 'sans-serif'],
        body: ['Outfit', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
    },
  },
  plugins: [],
}
