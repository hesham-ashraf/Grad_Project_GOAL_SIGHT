import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'
import LoginPage from './pages/LoginPage'
import RegisterPage from './pages/RegisterPage'
import HomePage from './pages/HomePage'
import MainLayout from './layouts/MainLayout'
import ProtectedRoute from './components/ProtectedRoute'

function App() {
  return (
    <>
      <Router>
        <Routes>
          {/* Public Routes */}
          <Route path="/" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/forgot-password" element={
            <div className="min-h-screen flex items-center justify-center">
              <p className="text-dark-500">Forgot Password page - Coming soon</p>
            </div>
          } />

          {/* Protected Routes with Sidebar Layout */}
          <Route path="/" element={
            <ProtectedRoute>
              <MainLayout />
            </ProtectedRoute>
          }>
            <Route path="home" element={<HomePage />} />
            <Route path="dashboard" element={
              <div className="p-6">
                <h1 className="text-2xl font-bold text-dark-900">Dashboard</h1>
                <p className="text-dark-500 mt-2">Coming soon...</p>
              </div>
            } />
            <Route path="analysis" element={
              <div className="p-6">
                <h1 className="text-2xl font-bold text-dark-900">Analysis</h1>
                <p className="text-dark-500 mt-2">Coming soon...</p>
              </div>
            } />
            <Route path="profile" element={
              <div className="p-6">
                <h1 className="text-2xl font-bold text-dark-900">Profile</h1>
                <p className="text-dark-500 mt-2">Coming soon...</p>
              </div>
            } />
          </Route>

          {/* Fallback */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Router>

      {/* Toast Notifications */}
      <Toaster
        position="top-right"
        toastOptions={{
          duration: 3000,
          style: {
            background: '#fff',
            color: '#0f172a',
            padding: '16px',
            borderRadius: '12px',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
          },
          success: {
            iconTheme: {
              primary: '#8b5cf6',
              secondary: '#fff',
            },
          },
        }}
      />
    </>
  )
}

export default App
