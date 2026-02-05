import React, { useState } from 'react';
import { register } from '../services/auth';
import '../styles/Auth.css';

const Register = ({ onRegister, onSwitchToLogin }) => {
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [role, setRole] = useState('fan');
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    try {
      const user = await register(email, password, role, username);
      onRegister(user);
    } catch (err) {
      setError(err.message || 'Registration failed');
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-header">
        <div className="logo">Welcome to</div>
        <h1>GOAL SIGHT</h1>
        <p>Fill in your name, email and set your password to register</p>
      </div>

      <form className="auth-form" onSubmit={handleSubmit}>
        <div className="form-group">
          <label>Username</label>
          <div className="input-wrapper">
            <input 
              type="text" 
              placeholder="Hesham Ashraf"
              value={username} 
              onChange={e => setUsername(e.target.value)} 
              required 
            />
          </div>
        </div>

        <div className="form-group">
          <label>Email</label>
          <div className="input-wrapper">
            <input 
              type="email" 
              placeholder="heshemashraf@gmail.com"
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

        <div className="form-group">
          <label>Role</label>
          <select value={role} onChange={e => setRole(e.target.value)}>
            <option value="fan">Fan</option>
            <option value="manager">Manager</option>
            <option value="admin">Admin</option>
          </select>
        </div>

        <button type="submit" className="submit-button">Register</button>

        {error && <div className="error-message">{error}</div>}
      </form>

      <div className="auth-footer">
        Don't have an account? <a onClick={onSwitchToLogin}>Sign In</a>
      </div>
    </div>
  );
};

export default Register;
