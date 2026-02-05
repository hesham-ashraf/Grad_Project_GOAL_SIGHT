import React, { useState } from 'react';
import { login } from '../services/auth';
import '../styles/Auth.css';

const Login = ({ onLogin, onSwitchToRegister }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    try {
      const user = await login(email, password);
      onLogin(user);
    } catch (err) {
      setError(err.message || 'Login failed');
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-header">
        <div className="logo">Welcome to</div>
        <h1>GOAL SIGHT</h1>
        <p>Enter your email address and password to use application</p>
      </div>

      <form className="auth-form" onSubmit={handleSubmit}>
        <div className="form-group">
          <label>Username</label>
          <div className="input-wrapper">
            <input 
              type="email" 
              placeholder="Enter your email"
              value={email} 
              onChange={e => setEmail(e.target.value)} 
              required 
            />
          </div>
        </div>

        <div className="form-group">
          <label>Password</label>
          <div className="input-wrapper">
            <input 
              type={showPassword ? "text" : "password"}
              placeholder="••••••••••••"
              value={password} 
              onChange={e => setPassword(e.target.value)} 
              required 
            />
            <span 
              className="eye-icon" 
              onClick={() => setShowPassword(!showPassword)}
            >
              {showPassword ? '👁️' : '👁️‍🗨️'}
            </span>
          </div>
        </div>

        <div className="form-options">
          <div className="remember-me">
            <input 
              type="checkbox" 
              id="remember" 
              checked={rememberMe}
              onChange={e => setRememberMe(e.target.checked)}
            />
            <label htmlFor="remember">Remember Me</label>
          </div>
          <a className="forgot-password">Forgot Password?</a>
        </div>

        <button type="submit" className="submit-button">Sign In</button>

        {error && <div className="error-message">{error}</div>}
      </form>

      <div className="social-login">
        <div className="social-buttons">
          <button type="button" className="social-button facebook">
            <span>📘</span> Facebook
          </button>
          <button type="button" className="social-button google">
            <span>🔍</span> Google
          </button>
        </div>
      </div>

      <div className="auth-footer">
        Don't have an account? <a onClick={onSwitchToRegister}>Sign Up</a>
      </div>
    </div>
  );
};

export default Login;
