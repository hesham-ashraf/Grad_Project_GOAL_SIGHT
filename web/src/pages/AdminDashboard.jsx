import React, { useState } from 'react';
import SidebarLayout from '../layouts/SidebarLayout';
import '../styles/Admin.css';

const AdminDashboard = () => {
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

  const stats = [
    { label: 'Total Users', value: '2,847', change: '+12%', icon: '👥', color: 'blue' },
    { label: 'Active Matches', value: '156', change: '+8%', icon: '⚽', color: 'green' },
    { label: 'Subscriptions', value: '1,234', change: '+23%', icon: '💳', color: 'purple' },
    { label: 'Venues', value: '45', change: '+5%', icon: '📍', color: 'orange' }
  ];

  return (
    <SidebarLayout menuItems={menuItems} user={user}>
      <div className="admin-content">
        {/* Header */}
        <div className="admin-header">
          <div>
            <h1 className="page-title">Admin Dashboard</h1>
            <p className="page-subtitle">Manage your platform from here</p>
          </div>
        </div>

        {/* Stats Grid */}
        <div className="stats-grid">
          {stats.map((stat, index) => (
            <div key={index} className={`stat-card ${stat.color}`}>
              <div className="stat-icon-wrapper">
                <span className="stat-icon-large">{stat.icon}</span>
              </div>
              <div className="stat-details">
                <span className="stat-label">{stat.label}</span>
                <span className="stat-value-large">{stat.value}</span>
                <span className={`stat-change ${stat.change.startsWith('+') ? 'positive' : 'negative'}`}>
                  {stat.change} from last month
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* Recent Activity */}
        <div className="activity-section">
          <h2 className="section-title">Recent Activity</h2>
          <div className="activity-list">
            {[1, 2, 3, 4, 5].map((item, index) => (
              <div key={index} className="activity-item">
                <div className="activity-avatar">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <circle cx="12" cy="12" r="10"/>
                    <path d="M12 16v-4"/>
                    <path d="M12 8h.01"/>
                  </svg>
                </div>
                <div className="activity-content">
                  <p className="activity-text">
                    <strong>User #{1000 + index}</strong> registered a new account
                  </p>
                  <span className="activity-time">{5 * (index + 1)} minutes ago</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </SidebarLayout>
  );
};

export default AdminDashboard;
