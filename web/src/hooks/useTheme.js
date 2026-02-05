import { useState, useEffect } from 'react';

/**
 * Custom hook for managing theme (light/dark mode)
 * Stores theme preference in localStorage
 * @returns {Object} theme - Current theme ('light' or 'dark')
 * @returns {Function} toggleTheme - Function to toggle between themes
 */
export const useTheme = () => {
  // Get initial theme from localStorage or default to 'dark'
  const [theme, setTheme] = useState(() => {
    const savedTheme = localStorage.getItem('goalSightTheme');
    return savedTheme || 'dark';
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
