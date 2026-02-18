import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { IoFootballOutline, IoHomeOutline, IoStatsChartOutline, IoAnalyticsOutline, IoPersonOutline, IoLogOutOutline } from 'react-icons/io5'
import useAuthStore from '../context/authStore'

function MainLayout() {
  const navigate = useNavigate()
  const { user, logout } = useAuthStore()

  const handleLogout = () => {
    logout()
    navigate('/')
  }

  const navItems = [
    { path: '/home', icon: IoHomeOutline, label: 'Home' },
    { path: '/dashboard', icon: IoStatsChartOutline, label: 'Dashboard' },
    { path: '/analysis', icon: IoAnalyticsOutline, label: 'Analysis' },
  ]

  return (
    <div className="flex h-screen bg-dark-50">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-dark-200 flex flex-col">
        {/* Logo */}
        <div className="p-6 border-b border-dark-200">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-primary rounded-xl flex items-center justify-center">
              <IoFootballOutline className="text-white text-xl" />
            </div>
            <div>
              <h1 className="text-lg font-bold bg-gradient-primary bg-clip-text text-transparent">
                GOALSIGHT
              </h1>
              <p className="text-xs text-dark-500">Analytics Platform</p>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 p-4 space-y-2">
          {navItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 ${
                  isActive
                    ? 'bg-gradient-primary text-white shadow-lg shadow-primary-500/30'
                    : 'text-dark-600 hover:bg-dark-100 hover:text-dark-900'
                }`
              }
            >
              {({ isActive }) => (
                <>
                  <item.icon className={`text-xl ${isActive ? 'text-white' : ''}`} />
                  <span className="font-medium">{item.label}</span>
                </>
              )}
            </NavLink>
          ))}
        </nav>

        {/* Profile Section */}
        <div className="p-4 border-t border-dark-200 space-y-2">
          <NavLink
            to="/profile"
            className={({ isActive }) =>
              `flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 ${
                isActive
                  ? 'bg-gradient-primary text-white'
                  : 'text-dark-600 hover:bg-dark-100'
              }`
            }
          >
            <IoPersonOutline className="text-xl" />
            <div className="flex-1">
              <p className="font-medium text-sm">{user?.name || 'Profile'}</p>
              <p className="text-xs opacity-75">{user?.email || 'View profile'}</p>
            </div>
          </NavLink>

          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-4 py-2 rounded-xl text-red-600 hover:bg-red-50 transition-all duration-200"
          >
            <IoLogOutOutline className="text-xl" />
            <span className="font-medium text-sm">Logout</span>
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-auto">
        <Outlet />
      </main>
    </div>
  )
}

export default MainLayout
