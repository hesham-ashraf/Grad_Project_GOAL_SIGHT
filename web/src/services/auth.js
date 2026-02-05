// src/services/auth.js
// Placeholder for authentication API calls

export async function login(email, password) {
  // Replace with real API call
  if (email === 'admin@example.com' && password === 'admin') {
    const user = { email, role: 'admin', token: 'fake-jwt-admin' };
    localStorage.setItem('token', user.token);
    localStorage.setItem('role', user.role);
    localStorage.setItem('email', user.email);
    return user;
  } else if (email === 'manager@example.com' && password === 'manager') {
    const user = { email, role: 'manager', token: 'fake-jwt-manager' };
    localStorage.setItem('token', user.token);
    localStorage.setItem('role', user.role);
    localStorage.setItem('email', user.email);
    return user;
  } else if (email === 'fan@example.com' && password === 'fan') {
    const user = { email, role: 'fan', token: 'fake-jwt-fan' };
    localStorage.setItem('token', user.token);
    localStorage.setItem('role', user.role);
    localStorage.setItem('email', user.email);
    return user;
  } else {
    throw new Error('Invalid credentials');
  }
}

export async function register(email, password, role, username) {
  // Replace with real API call
  if (!email || !password || !role || !username) throw new Error('Missing fields');
  // Simulate registration
  const user = { email, role, username, token: 'fake-jwt-' + role };
  localStorage.setItem('token', user.token);
  localStorage.setItem('role', user.role);
  localStorage.setItem('email', user.email);
  localStorage.setItem('username', user.username);
  return user;
}

export function logout() {
  localStorage.removeItem('token');
  localStorage.removeItem('role');
  localStorage.removeItem('email');
  localStorage.removeItem('username');
}

export function getCurrentUser() {
  const token = localStorage.getItem('token');
  const role = localStorage.getItem('role');
  const email = localStorage.getItem('email');
  if (token && role) return { token, role, email };
  return null;
}
