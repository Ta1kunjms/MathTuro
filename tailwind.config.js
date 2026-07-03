/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './**/*.html',
    './shared/js/**/*.js',
    './teacher/assets/js/**/*.js',
    './student/assets/js/**/*.js',
    './admin/assets/js/**/*.js',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50:  '#f0fdf4',
          100: '#dcfce7',
          200: '#bbf7d0',
          300: '#86efac',
          400: '#4ade80',
          500: '#22c55e',
          600: '#16a34a',
          700: '#15803d',
          800: '#166534',
          900: '#14532d',
        },
        brand: '#005801',
        'brand-dark': '#004601',
        'brand-light': '#006B01',
        teacher: {
          50:  '#fdf2f8',
          100: '#fce7f3',
          200: '#fbcfe8',
          300: '#f9a8d4',
          400: '#f472b6',
          500: '#ec4899',
          600: '#db2777',
          700: '#be185d',
          800: '#9d174d',
          900: '#831843',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
