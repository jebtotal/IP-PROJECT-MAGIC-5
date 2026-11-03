tailwind.config = {
      darkMode: 'class',
      theme: {
        extend: {
          fontFamily: {
            sans: ['"DM Sans"', 'system-ui', 'sans-serif'],
          },
          colors: {
            brand: {
              50: '#ecfdf5',
              100: '#d1fae5',
              200: '#a7f3d0',
              500: '#10b981',
              600: '#059669', /* Emerald Green Primary */
              700: '#047857',
              800: '#065f46',
              900: '#064e3b',
            },
            indigo: { /* Remapped to Terracotta to recolor existing gradients */
              400: '#f97316',
              500: '#ea580c',
              600: '#c2410c',
            },
            sky: { /* Remapped to warm orange for gradient compatibility */
              400: '#fb923c',
              500: '#f97316',
            },
            slate: { /* Deep Forest / Charcoal tones */
              50: '#f5f5f4',
              100: '#e7e5e4',
              200: '#d6d3d1',
              300: '#a8a29e',
              400: '#78716c',
              500: '#57534e',
              600: '#44403c',
              700: '#292524',
              800: '#1c1917',
              850: '#171412',
              900: '#0c0a09',
              950: '#000000',
            }
          }
        }
      }
    }
