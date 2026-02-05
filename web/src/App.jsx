import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import MatchDetails from './pages/MatchDetails';
import AdminDashboard from './pages/AdminDashboard';
import UsersManagement from './pages/UsersManagement';
import MatchesManagement from './pages/MatchesManagement';
import SubscriptionPlans from './pages/SubscriptionPlans';
import VenueConfig from './pages/VenueConfig';
import ManagerDashboard from './pages/ManagerDashboard';
import { getCurrentUser, logout } from './services/auth';
import { useTheme } from './hooks/useTheme';

/**
 * Main App Component
 * Handles authentication state, routing, and theme management
 */
function App() {
  // Theme management
  const { theme, toggleTheme } = useTheme();
  
  // State to track current user and authentication status
  const [user, setUser] = useState(getCurrentUser());
  
  // State to toggle between Login and Register views
  const [showRegister, setShowRegister] = useState(false);

  /**
   * Handle successful login
   * @param {Object} user - User object with token, role, and email
   */
  const handleLogin = (user) => {
    setUser(user);
  };

  /**
   * Handle successful registration
   * @param {Object} user - User object with token, role, and email
   */
  const handleRegister = (user) => {
    setUser(user);
    setShowRegister(false);
  };

  /**
   * Handle user logout
   * Clears user data from localStorage and resets state
   */
  const handleLogout = () => {
    logout();
    setUser(null);
  };

  // If user is not logged in, show Login or Register page
  if (!user) {
    return showRegister ? (
      <Register 
        onRegister={handleRegister} 
        onSwitchToLogin={() => setShowRegister(false)}
      />
    ) : (
      <Login 
        onLogin={handleLogin} 
        onSwitchToRegister={() => setShowRegister(true)}
      />
    );
  }

  // If user is logged in, show Dashboard with routing
  return (
    <Router>
      <Routes>
        {/* Redirect based on user role */}
        <Route 
          path="/" 
          element={
            user.role === 'admin' ? <Navigate to="/admin" replace /> :
            user.role === 'manager' ? <Navigate to="/manager" replace /> :
            <Dashboard 
              user={user} 
              onLogout={handleLogout} 
              theme={theme}
              toggleTheme={toggleTheme}
            />
          } 
        />
        <Route 
          path="/match/:id" 
          element={
            <MatchDetails 
              user={user} 
              onLogout={handleLogout}
              theme={theme}
              toggleTheme={toggleTheme}
            />
          } 
        />
        
        {/* Admin Routes */}
        <Route path="/admin" element={<AdminDashboard />} />
        <Route path="/admin/users" element={<UsersManagement />} />
        <Route path="/admin/matches" element={<MatchesManagement />} />
        <Route path="/admin/subscriptions" element={<SubscriptionPlans />} />
        <Route path="/admin/venues" element={<VenueConfig />} />
        
        {/* Manager Routes */}
        <Route path="/manager" element={<ManagerDashboard />} />
        
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Router>
  );
}

export default App;
