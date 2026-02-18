import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { FaEye, FaEyeSlash, FaFacebookF, FaGoogle } from 'react-icons/fa'
import { IoFootballOutline } from 'react-icons/io5'
import toast from 'react-hot-toast'
import useAuthStore from '../context/authStore'
import { mockUser } from '../data/mockData'

function LoginPage() {
  const navigate = useNavigate()
  const setAuth = useAuthStore((state) => state.setAuth)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [rememberMe, setRememberMe] = useState(false)
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)

    try {
      // Using mock data for demo
      const demoUser = {
        ...mockUser,
        email: email,
        name: email.split('@')[0].replace('.', ' ').split(' ').map(word => 
          word.charAt(0).toUpperCase() + word.slice(1)
        ).join(' ')
      }
      
      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 800))
      
      setAuth(demoUser, 'demo-token-' + Date.now())
      
      toast.success('Login successful! Welcome to GOALSIGHT 🎉')
      navigate('/home')
    } catch (error) {
      toast.error(error.message || 'Login failed. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const handleSocialLogin = (provider) => {
    toast.info(`${provider} login coming soon!`)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 via-white to-secondary-50 flex items-center justify-center px-4 py-8">
      {/* Background Pattern */}
      <div className="absolute inset-0 opacity-5">
        <div className="absolute top-10 left-10 w-64 h-64 bg-gradient-primary rounded-full blur-3xl"></div>
        <div className="absolute bottom-10 right-10 w-96 h-96 bg-gradient-primary rounded-full blur-3xl"></div>
      </div>

      {/* Login Card */}
      <div className="relative w-full max-w-md">
        {/* Logo Section */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-primary rounded-2xl mb-4">
            <IoFootballOutline className="text-white text-3xl" />
          </div>
          <h1 className="text-3xl font-bold bg-gradient-primary bg-clip-text text-transparent">
            GOALSIGHT
          </h1>
          <p className="text-dark-500 text-sm mt-1">Football Analytics Platform</p>
        </div>

        {/* Card */}
        <div className="bg-white rounded-2xl shadow-xl p-8 border border-dark-100">
          {/* Header */}
          <div className="mb-6">
            <h2 className="text-2xl font-bold text-dark-900 mb-2">
              Welcome to GOALSIGHT
            </h2>
            <p className="text-dark-500 text-sm">
              Enter your email address and password to use the application.
            </p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Email Input */}
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-dark-700 mb-2">
                Email / Username
              </label>
              <input
                type="text"
                id="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Enter your email or username"
                className="w-full px-4 py-3 rounded-xl border border-dark-200 focus:border-primary-500 focus:ring-2 focus:ring-primary-100 outline-none transition-all duration-200 text-dark-900 placeholder:text-dark-400"
                required
              />
            </div>

            {/* Password Input */}
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-dark-700 mb-2">
                Password
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  id="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter your password"
                  className="w-full px-4 py-3 pr-12 rounded-xl border border-dark-200 focus:border-primary-500 focus:ring-2 focus:ring-primary-100 outline-none transition-all duration-200 text-dark-900 placeholder:text-dark-400"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-dark-400 hover:text-primary-500 transition-colors duration-200"
                >
                  {showPassword ? <FaEyeSlash size={18} /> : <FaEye size={18} />}
                </button>
              </div>
            </div>

            {/* Remember Me & Forget Password */}
            <div className="flex items-center justify-between text-sm">
              <label className="flex items-center cursor-pointer group">
                <input
                  type="checkbox"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="w-4 h-4 rounded border-dark-300 text-primary-500 focus:ring-2 focus:ring-primary-100 cursor-pointer"
                />
                <span className="ml-2 text-dark-600 group-hover:text-dark-900 transition-colors duration-200">
                  Remember Me
                </span>
              </label>
              <Link
                to="/forgot-password"
                className="text-primary-500 hover:text-primary-600 font-medium transition-colors duration-200"
              >
                Forget Password?
              </Link>
            </div>

            {/* Sign In Button */}
            <button
              type="submit"
              disabled={loading}
              className="w-full py-3.5 bg-gradient-primary hover:bg-gradient-primary-hover text-white font-semibold rounded-xl shadow-lg shadow-primary-500/30 hover:shadow-xl hover:shadow-primary-500/40 transition-all duration-300 transform hover:-translate-y-0.5 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
            >
              {loading ? 'SIGNING IN...' : 'SIGN IN'}
            </button>
          </form>

          {/* Divider */}
          <div className="relative my-6">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-dark-200"></div>
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-4 bg-white text-dark-500">Or login with</span>
            </div>
          </div>

          {/* Social Login */}
          <div className="grid grid-cols-2 gap-3">
            <button
              type="button"
              onClick={() => handleSocialLogin('facebook')}
              className="flex items-center justify-center gap-2 py-3 px-4 border border-dark-200 rounded-xl hover:bg-dark-50 hover:border-[#1877F2] hover:text-[#1877F2] transition-all duration-200 text-dark-700 font-medium"
            >
              <FaFacebookF size={18} className="text-[#1877F2]" />
              Facebook
            </button>
            <button
              type="button"
              onClick={() => handleSocialLogin('google')}
              className="flex items-center justify-center gap-2 py-3 px-4 border border-dark-200 rounded-xl hover:bg-dark-50 hover:border-dark-400 transition-all duration-200 text-dark-700 font-medium"
            >
              <FaGoogle size={18} className="text-[#DB4437]" />
              Google
            </button>
          </div>

          {/* Register Link */}
          <div className="mt-6 text-center text-sm">
            <span className="text-dark-600">Don't have an account? </span>
            <Link
              to="/register"
              className="text-primary-500 hover:text-primary-600 font-semibold transition-colors duration-200"
            >
              Register Now
            </Link>
          </div>
        </div>

        {/* Footer */}
        <p className="text-center text-xs text-dark-400 mt-6">
          © 2026 GOALSIGHT. Premium Football Analytics Platform.
        </p>
      </div>
    </div>
  )
}

export default LoginPage
