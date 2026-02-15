import React from 'react';
import SidebarLayout from '../layouts/SidebarLayout';
import '../styles/Admin.css';

const VenueConfig = ({ theme, toggleTheme }) => {
  const user = {
    email: localStorage.getItem('userEmail'),
    role: localStorage.getItem('userRole')
  };

  const menuItems = [
    {
      path: '/admin',
      label: 'Dashboard',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <rect x="3" y="3" width="7" height="7"/>
          <rect x="14" y="3" width="7" height="7"/>
          <rect x="14" y="14" width="7" height="7"/>
          <rect x="3" y="14" width="7" height="7"/>
        </svg>
      )
    },
    {
      path: '/admin/users',
      label: 'Users',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
          <circle cx="9" cy="7" r="4"/>
          <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
          <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
        </svg>
      )
    },
    {
      path: '/admin/matches',
      label: 'Matches',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10"/>
          <line x1="12" y1="2" x2="12" y2="12"/>
          <line x1="12" y1="12" x2="16" y2="16"/>
        </svg>
      )
    },
    {
      path: '/admin/subscriptions',
      label: 'Subscriptions',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <rect x="3" y="8" width="18" height="13" rx="2"/>
          <path d="M21 8V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v2"/>
        </svg>
      )
    },
    {
      path: '/admin/venues',
      label: 'Venues',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
          <circle cx="12" cy="10" r="3"/>
        </svg>
      )
    }
  ];

  return (
    <SidebarLayout menuItems={menuItems} user={user} theme={theme} toggleTheme={toggleTheme}>
      <div className="admin-content">
        {/* Header */}
        <div className="admin-header">
          <div>
            <h1 className="page-title">Venue Configuration</h1>
            <p className="page-subtitle">Configure stadium and venue settings (Placeholder)</p>
          </div>
        </div>

        {/* Placeholder Content */}
        <div className="placeholder-container">
          <div className="placeholder-icon">
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
              <circle cx="12" cy="10" r="3"/>
            </svg>
          </div>
          <h2>Venue Configuration Coming Soon</h2>
          <p>This feature will allow you to manage stadium configurations, camera placements, and venue-specific analytics settings.</p>
        </div>
      </div>
    </SidebarLayout>
  );
};

export default VenueConfig;
