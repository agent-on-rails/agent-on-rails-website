/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        ink: {
          DEFAULT: '#0B1F3A',
          soft: '#1A3358',
          mute: '#4A6285',
        },
        rail: {
          DEFAULT: '#2EB6FF',
          deep: '#1490D4',
          wash: '#E8F6FF',
        },
        paper: {
          DEFAULT: '#F7FBFF',
          warm: '#EEF4FA',
        },
      },
      fontFamily: {
        display: ['"Bricolage Grotesque"', 'Georgia', 'serif'],
        sans: ['"Figtree"', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        rail: '0 24px 60px -28px rgba(11, 31, 58, 0.35)',
      },
      keyframes: {
        'rise-in': {
          '0%': { opacity: '0', transform: 'translateY(18px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'track-draw': {
          '0%': { strokeDashoffset: '240' },
          '100%': { strokeDashoffset: '0' },
        },
        'soft-float': {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-10px)' },
        },
      },
      animation: {
        'rise-in': 'rise-in 0.8s cubic-bezier(0.22, 1, 0.36, 1) both',
        'track-draw': 'track-draw 1.4s ease-out both',
        'soft-float': 'soft-float 6s ease-in-out infinite',
      },
    },
  },
  plugins: [],
};
