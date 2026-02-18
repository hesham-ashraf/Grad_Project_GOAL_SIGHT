import { Outlet } from 'react-router-dom'
import Sidebar from '../components/Sidebar'

function MainLayout() {
  return (
    <div className="flex h-screen bg-dark-50">
      <Sidebar />
      
      {/* Main Content */}
      <main className="flex-1 overflow-auto">
        <Outlet />
      </main>
    </div>
  )
}

export default MainLayout
