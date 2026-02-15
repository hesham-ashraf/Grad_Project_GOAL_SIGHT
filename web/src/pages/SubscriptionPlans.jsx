import React from 'react';
import SidebarLayout from '../layouts/SidebarLayout';
import '../styles/Admin.css';

const SubscriptionPlans = ({ theme, toggleTheme }) => {
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

  const plans = [
    {
      name: 'Free',
      price: '$0',
      period: 'forever',
      features: ['Basic match statistics', 'Limited analytics', '5 matches per month', 'Community support'],
      popular: false
    },
    {
      name: 'Pro',
      price: '$29',
      period: 'per month',
      features: ['Advanced analytics', 'Unlimited matches', 'Heatmap visualization', 'Priority support', 'Export reports'],
      popular: true
    },
    {
      name: 'Enterprise',
      price: '$99',
      period: 'per month',
      features: ['Everything in Pro', 'Custom integrations', 'Dedicated manager', 'API access', 'White-label solution'],
      popular: false
    }
  ];

  return (
    <SidebarLayout menuItems={menuItems} user={user} theme={theme} toggleTheme={toggleTheme}>
      <div className="admin-content">
        {/* Header */}
        <div className="admin-header">
          <div>
            <h1 className="page-title">Subscription Plans</h1>
            <p className="page-subtitle">Manage platform subscription tiers (UI Preview)</p>
          </div>
        </div>

        {/* Plans Grid */}
        <div className="plans-grid">
          {plans.map((plan, index) => (
            <div key={index} className={`plan-card ${plan.popular ? 'popular' : ''}`}>
              {plan.popular && <div className="popular-badge">Most Popular</div>}
              <div className="plan-header">
                <h3 className="plan-name">{plan.name}</h3>
                <div className="plan-price">
                  <span className="price">{plan.price}</span>
                  <span className="period">/{plan.period}</span>
                </div>
              </div>
              <ul className="plan-features">
                {plan.features.map((feature, idx) => (
                  <li key={idx}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <polyline points="20 6 9 17 4 12"/>
                    </svg>
                    {feature}
                  </li>
                ))}
              </ul>
              <button className={`plan-button ${plan.popular ? 'primary' : 'secondary'}`}>
                Edit Plan
              </button>
            </div>
          ))}
        </div>
      </div>
    </SidebarLayout>
  );
};

export default SubscriptionPlans;
