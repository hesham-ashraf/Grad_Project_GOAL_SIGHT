import React, { useState, useRef, useEffect } from 'react';
import '../styles/SettingsMenu.css';

/**
 * SettingsMenu Component
 * Dropdown menu with theme toggle and other settings
 * @param {Object} props
 * @param {string} props.theme - Current theme ('light' or 'dark')
 * @param {Function} props.toggleTheme - Function to toggle theme
 */
const SettingsMenu = ({ theme, toggleTheme }) => {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef(null);

  /**
   * Close menu when clicking outside
   */
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (menuRef.current && !menuRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  return (
    <div className="settings-menu" ref={menuRef}>
      {/* Settings Button */}
      <button 
        className="settings-button"
        onClick={() => setIsOpen(!isOpen)}
        aria-label="Settings"
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <circle cx="12" cy="12" r="3"/>
          <path d="M12 1v6m0 6v6m5.2-13.2-4.2 4.2m0 6-4.2 4.2M23 12h-6m-6 0H1m13.2 5.2-4.2-4.2m0-6-4.2-4.2"/>
        </svg>
      </button>

      {/* Dropdown Menu */}
      {isOpen && (
        <div className="settings-dropdown">
          <div className="settings-header">
            <h3>Preferences</h3>
            <p>Customize your experience</p>
          </div>

          <div className="settings-content">
            {/* Theme Toggle Section */}
            <div className="setting-item">
              <div className="setting-info">
                <div className="setting-icon">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364-.707-.707M6.343 6.343l-.707-.707m12.728 0-.707.707M6.343 17.657l-.707.707"/>
                    <circle cx="12" cy="12" r="5"/>
                  </svg>
                </div>
                <div className="setting-text">
                  <span className="setting-label">Appearance</span>
                  <span className="setting-description">
                    {theme === 'dark' ? 'Dark' : 'Light'} theme active
                  </span>
                </div>
              </div>
              
              <div className="theme-toggle">
                <button
                  className={`theme-option ${theme === 'light' ? 'active' : ''}`}
                  onClick={() => theme === 'dark' && toggleTheme()}
                  title="Light Mode"
                  aria-label="Light Mode"
                >
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <circle cx="12" cy="12" r="5"/>
                    <line x1="12" y1="1" x2="12" y2="3"/>
                    <line x1="12" y1="21" x2="12" y2="23"/>
                    <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>
                    <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
                    <line x1="1" y1="12" x2="3" y2="12"/>
                    <line x1="21" y1="12" x2="23" y2="12"/>
                    <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>
                    <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
                  </svg>
                </button>
                <button
                  className={`theme-option ${theme === 'dark' ? 'active' : ''}`}
                  onClick={() => theme === 'light' && toggleTheme()}
                  title="Dark Mode"
                  aria-label="Dark Mode"
                >
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/>
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default SettingsMenu;
