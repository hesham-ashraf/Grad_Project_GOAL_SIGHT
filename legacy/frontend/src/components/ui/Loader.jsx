import { IoFootballOutline } from 'react-icons/io5'

function Loader() {
  return (
    <div className="flex flex-col items-center justify-center p-8">
      <div className="relative">
        <div className="w-16 h-16 border-4 border-primary-200 border-t-primary-500 rounded-full animate-spin"></div>
        <IoFootballOutline className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 text-primary-500 text-xl" />
      </div>
      <p className="mt-4 text-dark-500 text-sm">Loading...</p>
    </div>
  )
}

export default Loader