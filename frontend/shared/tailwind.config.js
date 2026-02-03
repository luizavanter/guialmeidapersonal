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
        lime: '#C4F53A',
        ocean: '#0EA5E9',
        smoke: '#F5F5F0',
        // Extended palette
        'coal-light': '#1A1A1A',
        'coal-lighter': '#2A2A2A',
        'lime-dark': '#A8D32E',
        'ocean-dark': '#0C87BB',
        'smoke-dark': '#E5E5E0',
      },
      fontFamily: {
        display: ['Bebas Neue', 'sans-serif'],
        sans: ['Outfit', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      fontSize: {
        'display-xl': ['4.5rem', { lineHeight: '1', letterSpacing: '0.02em' }],
        'display-lg': ['3.5rem', { lineHeight: '1.1', letterSpacing: '0.02em' }],
        'display-md': ['2.5rem', { lineHeight: '1.2', letterSpacing: '0.02em' }],
        'display-sm': ['2rem', { lineHeight: '1.2', letterSpacing: '0.02em' }],
      },
      spacing: {
        '18': '4.5rem',
        '22': '5.5rem',
        '26': '6.5rem',
      },
      borderRadius: {
        'ga': '0.75rem',
      },
      boxShadow: {
        'ga': '0 4px 20px rgba(196, 245, 58, 0.1)',
        'ga-lg': '0 8px 40px rgba(196, 245, 58, 0.15)',
        'coal': '0 4px 20px rgba(10, 10, 10, 0.5)',
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'slide-down': 'slideDown 0.3s ease-out',
        'scale-in': 'scaleIn 0.2s ease-out',
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
          '0%': { transform: 'scale(0.95)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
      },
    },
  },
  plugins: [],
}
