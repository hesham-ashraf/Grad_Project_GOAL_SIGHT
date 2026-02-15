import { useState, useEffect } from 'react';

/**
 * Custom hook for managing theme (light/dark mode)
 * Stores theme preference in localStorage
 * Supports system preference detection on first visit
 * @returns {Object} theme - Current theme ('light' or 'dark')
 * @returns {Function} toggleTheme - Function to toggle between themes
 */
export const useTheme = () => {
  // Get initial theme from localStorage or system preference or default to 'dark'
  const [theme, setTheme] = useState(() => {
    const savedTheme = localStorage.getItem('goalSightTheme');
    if (savedTheme) return savedTheme;
    
    // Check system preference on first visit
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches) {
      return 'light';
    }
    
    return 'dark'; // Default to dark
  });

  /**
   * Apply theme to document root
   */
  useEffect(() => {
    // Update data-theme attribute on root element
    document.documentElement.setAttribute('data-theme', theme);
    
    // Save to localStorage
    localStorage.setItem('goalSightTheme', theme);
  }, [theme]);

  /**
   * Toggle between light and dark themes
   */
  const toggleTheme = () => {
    setTheme((prevTheme) => (prevTheme === 'dark' ? 'light' : 'dark'));
  };

  return { theme, toggleTheme };
};
