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
        // --- Redesign tokens (additive, Phase 0) ---
        // Namespaced as 'forest'/'plum'/'paper'/'ink' rather than Tailwind's
        // built-in 'green'/'purple' keys so this does NOT override the
        // default Tailwind green/purple scale used elsewhere in the app.
        forest: {
          50:  '#f0f7f3',
          100: '#dcece3',
          600: '#2f7756',
          800: '#1b4332',
          900: '#122d22',
        },
        plum: {
          50:  '#fbf1f8',
          100: '#f5dced',
          600: '#9a0573',
          800: '#720455',
          900: '#4d0339',
        },
        paper: {
          0:   '#ffffff',
          50:  '#faf9f7',
          100: '#f2f0ec',
        },
        ink: {
          300: '#a8a49c',
          500: '#6b6862',
          700: '#3f3d3a',
          900: '#1c1b1a',
        },
        line: '#e4e1da',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
