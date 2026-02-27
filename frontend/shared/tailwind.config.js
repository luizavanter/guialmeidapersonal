/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        coal: '#0A0A0A',
        lime: '#CDFA3E',
        ocean: '#0EA5E9',
        smoke: '#F5F5F0',
        stone: '#8A8578',
        // Surface layers (depth system)
        'surface-1': '#111111',
        'surface-2': '#161616',
        'surface-3': '#1C1C1C',
        'surface-4': '#242424',
        // Extended
        'coal-light': '#1A1A1A',
        'coal-lighter': '#2A2A2A',
        'lime-dark': '#A8D32E',
        'lime-glow': 'rgba(205, 250, 62, 0.08)',
        'ocean-dark': '#0C87BB',
        'smoke-dark': '#E5E5E0',
        'smoke-muted': '#A8A89E',
      },
      fontFamily: {
        display: ['Space Grotesk', 'sans-serif'],
        sans: ['Inter', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      fontSize: {
        'display-xl': ['4rem', { lineHeight: '1.05', letterSpacing: '-0.02em', fontWeight: '700' }],
        'display-lg': ['3rem', { lineHeight: '1.1', letterSpacing: '-0.02em', fontWeight: '700' }],
        'display-md': ['2.25rem', { lineHeight: '1.15', letterSpacing: '-0.01em', fontWeight: '600' }],
        'display-sm': ['1.75rem', { lineHeight: '1.2', letterSpacing: '-0.01em', fontWeight: '600' }],
      },
      spacing: {
        '18': '4.5rem',
        '22': '5.5rem',
        '26': '6.5rem',
      },
      borderRadius: {
        'ga': '0.75rem',
        'ga-lg': '1rem',
      },
      boxShadow: {
        'ga': '0 4px 20px rgba(205, 250, 62, 0.06)',
        'ga-lg': '0 8px 40px rgba(205, 250, 62, 0.1)',
        'coal': '0 4px 20px rgba(10, 10, 10, 0.5)',
        'elevated': '0 8px 32px rgba(0, 0, 0, 0.4)',
        'inset-subtle': 'inset 0 1px 0 rgba(255, 255, 255, 0.03)',
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-in-out',
        'slide-up': 'slideUp 0.4s cubic-bezier(0.16, 1, 0.3, 1)',
        'slide-down': 'slideDown 0.4s cubic-bezier(0.16, 1, 0.3, 1)',
        'scale-in': 'scaleIn 0.25s cubic-bezier(0.16, 1, 0.3, 1)',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        slideDown: {
          '0%': { transform: 'translateY(-10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        scaleIn: {
          '0%': { transform: 'scale(0.97)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
      },
    },
  },
  plugins: [],
}
