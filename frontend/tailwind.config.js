/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                // Purple to Blue gradient theme
                primary: {
                    50: '#f5f3ff',
                    100: '#ede9fe',
                    200: '#ddd6fe',
                    300: '#c4b5fd',
                    400: '#a78bfa',
                    500: '#8b5cf6', // Main purple
                    600: '#7c3aed',
                    700: '#6d28d9',
                    800: '#5b21b6',
                    900: '#4c1d95',
                },
                secondary: {
                    50: '#eff6ff',
                    100: '#dbeafe',
                    200: '#bfdbfe',
                    300: '#93c5fd',
                    400: '#60a5fa',
                    500: '#3b82f6', // Main blue
                    600: '#2563eb',
                    700: '#1d4ed8',
                    800: '#1e40af',
                    900: '#1e3a8a',
                },
                dark: {
                    50: '#f8fafc',
                    100: '#f1f5f9',
                    200: '#e2e8f0',
                    300: '#cbd5e1',
                    400: '#94a3b8',
                    500: '#64748b',
                    600: '#475569',
                    700: '#334155',
                    800: '#1e293b',
                    900: '#0f172a',
                },
            },
            backgroundImage: {
                'gradient-primary': 'linear-gradient(135deg, #8b5cf6 0%, #3b82f6 100%)',
                'gradient-primary-hover': 'linear-gradient(135deg, #7c3aed 0%, #2563eb 100%)',
                'gradient-card': 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)',
            },
            boxShadow: {
                'soft': '0 2px 15px -3px rgba(139, 92, 246, 0.1), 0 4px 6px -2px rgba(59, 130, 246, 0.05)',
                'soft-lg': '0 10px 40px -10px rgba(139, 92, 246, 0.15), 0 8px 16px -4px rgba(59, 130, 246, 0.1)',
                'card': '0 4px 20px -2px rgba(0, 0, 0, 0.08)',
                'card-hover': '0 8px 30px -4px rgba(139, 92, 246, 0.2), 0 4px 10px -2px rgba(59, 130, 246, 0.1)',
            },
            borderRadius: {
                'card': '16px',
                'button': '12px',
            },
            fontFamily: {
                sans: ['Inter', 'system-ui', 'sans-serif'],
                display: ['Poppins', 'Inter', 'sans-serif'],
            },
            animation: {
                'fade-in': 'fadeIn 0.3s ease-in-out',
                'slide-up': 'slideUp 0.4s ease-out',
                'bounce-slow': 'bounce 3s infinite',
                'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
            },
            keyframes: {
                fadeIn: {
                    '0%': { opacity: '0' },
                    '100%': { opacity: '1' },
                },
                slideUp: {
                    '0%': { transform: 'translateY(20px)', opacity: '0' },
                    '100%': { transform: 'translateY(0)', opacity: '1' },
                },
            },
        },
    },
    plugins: [],
}