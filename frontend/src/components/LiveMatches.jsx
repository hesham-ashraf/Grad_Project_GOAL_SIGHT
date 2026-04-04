import { useState, useEffect } from 'react'
import matchService from '../services/matchService'
import MatchCard from './match/MatchCard'
import { IoFootballOutline, IoRefreshOutline } from 'react-icons/io5'

function LiveMatches() {
  const [matches, setMatches] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [lastUpdate, setLastUpdate] = useState(null)

  // Fetch live matches from the real API
  const fetchLiveMatches = async () => {
    try {
      setError(null)
      const data = await matchService.getLiveMatches()
      setMatches(data)
      setLastUpdate(new Date())
    } catch (err) {
      console.error('Error fetching live matches:', err)
      setError('Failed to load live matches. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  // Initial fetch
  useEffect(() => {
    fetchLiveMatches()
  }, [])

  // Auto-refresh every 10 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      fetchLiveMatches()
    }, 10000) // 10 seconds

    return () => clearInterval(interval)
  }, [])

  // Manual refresh
  const handleRefresh = () => {
    setLoading(true)
    fetchLiveMatches()
  }

  // Loading state
  if (loading && matches.length === 0) {
    return (
      <section className="mb-8">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold text-dark-900 flex items-center gap-2">
            <IoFootballOutline className="text-red-500" />
            Live Matches
          </h2>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {[1, 2, 3].map((i) => (
            <div
              key={i}
              className="bg-white rounded-xl border border-dark-200 overflow-hidden animate-pulse"
            >
              <div className="bg-dark-200 h-12"></div>
              <div className="p-5 space-y-4">
                <div className="h-4 bg-dark-200 rounded w-3/4"></div>
                <div className="h-8 bg-dark-200 rounded"></div>
                <div className="h-8 bg-dark-200 rounded"></div>
              </div>
            </div>
          ))}
        </div>
      </section>
    )
  }

  // Error state
  if (error) {
    return (
      <section className="mb-8">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold text-dark-900 flex items-center gap-2">
            <IoFootballOutline className="text-red-500" />
            Live Matches
          </h2>
          <button
            onClick={handleRefresh}
            className="flex items-center gap-2 px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors text-sm"
          >
            <IoRefreshOutline />
            Retry
          </button>
        </div>
        <div className="bg-red-50 border border-red-200 rounded-xl p-6 text-center">
          <p className="text-red-600 mb-2">{error}</p>
          <button
            onClick={handleRefresh}
            className="text-sm text-red-500 hover:text-red-600 underline"
          >
            Try again
          </button>
        </div>
      </section>
    )
  }

  // No matches state
  if (matches.length === 0) {
    return (
      <section className="mb-8">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold text-dark-900 flex items-center gap-2">
            <IoFootballOutline className="text-red-500" />
            Live Matches
          </h2>
          <button
            onClick={handleRefresh}
            className="flex items-center gap-2 px-4 py-2 bg-dark-100 text-dark-600 rounded-lg hover:bg-dark-200 transition-colors text-sm"
            disabled={loading}
          >
            <IoRefreshOutline className={loading ? 'animate-spin' : ''} />
            Refresh
          </button>
        </div>
        <div className="bg-gradient-to-br from-primary-50 to-secondary-50 rounded-xl p-12 text-center border border-dark-200">
          <IoFootballOutline className="text-6xl text-dark-300 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-dark-900 mb-2">
            No live matches at the moment
          </h3>
          <p className="text-dark-600">
            Check back soon for live football action!
          </p>
          {lastUpdate && (
            <p className="text-xs text-dark-500 mt-4">
              Last updated: {lastUpdate.toLocaleTimeString()}
            </p>
          )}
        </div>
      </section>
    )
  }

  // Matches display
  return (
    <section className="mb-8">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-xl font-bold text-dark-900 flex items-center gap-2">
            <IoFootballOutline className="text-red-500" />
            Live Matches
            <span className="px-2 py-1 bg-red-500 text-white text-xs rounded-full">
              {matches.length}
            </span>
          </h2>
          {lastUpdate && (
            <p className="text-xs text-dark-500 mt-1">
              Last updated: {lastUpdate.toLocaleTimeString()}
            </p>
          )}
        </div>
        <button
          onClick={handleRefresh}
          disabled={loading}
          className="flex items-center gap-2 px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors text-sm disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <IoRefreshOutline className={loading ? 'animate-spin' : ''} />
          Refresh
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {matches.map((match) => (
          <MatchCard key={match.id} match={match} />
        ))}
      </div>

      {/* Auto-refresh indicator */}
      <div className="mt-4 text-center">
        <p className="text-xs text-dark-500">
          Auto-refreshing every 10 seconds
        </p>
      </div>
    </section>
  )
}

export default LiveMatches
