import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { IoArrowBack, IoCalendarOutline, IoTimeOutline, IoFootballOutline } from 'react-icons/io5'
import matchService from '../services/matchService'
import { getTodayDate, formatMatchDate, formatMatchTime, getStatusDisplay, isLive } from '../utils/dateUtils'
import Loader from '../components/ui/Loader'

function TodayMatchesPage() {
  const navigate = useNavigate()
  const [loading, setLoading] = useState(true)
  const [leagues, setLeagues] = useState([])
  const [error, setError] = useState(null)
  const [selectedCategory, setSelectedCategory] = useState('all')

  useEffect(() => {
    fetchTodayMatches()
  }, [])

  const fetchTodayMatches = async () => {
    setLoading(true)
    setError(null)
    try {
      const todayDate = getTodayDate()
      const data = await matchService.getTodayLeagues(todayDate)
      
      // Filter out leagues with no matches
      const leaguesWithMatches = data.filter(league => league.matches && league.matches.length > 0)
      setLeagues(leaguesWithMatches)
    } catch (err) {
      console.error('Error fetching today\'s matches:', err)
      setError('Failed to load matches. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const categories = [
    { value: 'all', label: 'All Leagues' },
    { value: '1', label: 'Top Tier' },
    { value: '2', label: 'Second Tier' },
    { value: '3', label: 'Cups' },
  ]

  const filteredLeagues = selectedCategory === 'all' 
    ? leagues 
    : leagues.filter(league => league.category === parseInt(selectedCategory))

  const totalMatches = filteredLeagues.reduce((sum, league) => sum + league.matches.length, 0)

  if (loading) {
    return (
      <div className="min-h-screen bg-dark-50 flex items-center justify-center">
        <Loader />
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen bg-dark-50 p-6">
        <div className="max-w-7xl mx-auto">
          <button
            onClick={() => navigate('/home')}
            className="flex items-center gap-2 text-dark-700 hover:text-primary-500 mb-6"
          >
            <IoArrowBack />
            Back to Home
          </button>
          <div className="bg-white rounded-2xl p-8 text-center">
            <p className="text-red-500 text-lg">{error}</p>
            <button
              onClick={fetchTodayMatches}
              className="mt-4 px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600"
            >
              Try Again
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-dark-50 pb-8">
      {/* Header */}
      <div className="bg-white border-b border-dark-200 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-6 py-4">
          <button
            onClick={() => navigate('/home')}
            className="flex items-center gap-2 text-dark-700 hover:text-primary-500 mb-4"
          >
            <IoArrowBack />
            Back to Home
          </button>
          
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-dark-900 flex items-center gap-2">
                <IoCalendarOutline className="text-primary-500" />
                Today's Matches
              </h1>
              <p className="text-dark-500 text-sm mt-1">
                {formatMatchDate(getTodayDate())} • {totalMatches} matches
              </p>
            </div>
          </div>

          {/* Category Filter */}
          <div className="flex gap-2 mt-4 overflow-x-auto pb-2">
            {categories.map((category) => (
              <button
                key={category.value}
                onClick={() => setSelectedCategory(category.value)}
                className={`px-4 py-2 rounded-lg text-sm font-medium whitespace-nowrap transition-colors duration-200 ${
                  selectedCategory === category.value
                    ? 'bg-primary-500 text-white'
                    : 'bg-dark-100 text-dark-700 hover:bg-dark-200'
                }`}
              >
                {category.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Matches by League */}
      <div className="max-w-7xl mx-auto px-6 py-6 space-y-6">
        {filteredLeagues.length > 0 ? (
          filteredLeagues.map((league) => (
            <div key={league.id} className="bg-white rounded-2xl overflow-hidden border border-dark-200">
              {/* League Header */}
              <div className="bg-gradient-to-r from-primary-50 to-secondary-50 px-6 py-4 border-b border-dark-200">
                <div className="flex items-center gap-3">
                  {league.logo && (
                    <img 
                      src={league.logo} 
                      alt={league.name} 
                      className="w-8 h-8 object-contain"
                    />
                  )}
                  <div>
                    <h2 className="text-lg font-bold text-dark-900">{league.name}</h2>
                    <p className="text-xs text-dark-500">
                      {league.shortCode} • {league.matches.length} match{league.matches.length !== 1 ? 'es' : ''}
                    </p>
                  </div>
                </div>
              </div>

              {/* Matches List */}
              <div className="divide-y divide-dark-100">
                {league.matches.map((match) => (
                  <div
                    key={match.id}
                    onClick={() => navigate(`/match/${match.id}`)}
                    className="px-6 py-4 hover:bg-dark-50 transition-colors duration-200 cursor-pointer"
                  >
                    <div className="flex items-center justify-between mb-3">
                      <div className="flex items-center gap-2">
                        {match.round && (
                          <span className="text-xs text-dark-500">{match.round}</span>
                        )}
                        {match.stage && match.round && (
                          <span className="text-xs text-dark-400">•</span>
                        )}
                        {match.stage && (
                          <span className="text-xs text-dark-500">{match.stage}</span>
                        )}
                      </div>
                      <span className={`flex items-center gap-1 text-sm font-medium ${
                        isLive(match.status) 
                          ? 'text-red-500 animate-pulse' 
                          : match.status === 'FT'
                          ? 'text-green-600'
                          : 'text-primary-500'
                      }`}>
                        {isLive(match.status) && <IoFootballOutline className="animate-bounce" />}
                        <IoTimeOutline />
                        {getStatusDisplay(match.status, match.startTime)}
                      </span>
                    </div>

                    {/* Teams */}
                    <div className="space-y-3">
                      {/* Home Team */}
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3 flex-1">
                          {match.homeTeam.logo ? (
                            <img 
                              src={match.homeTeam.logo} 
                              alt={match.homeTeam.name}
                              className="w-8 h-8 object-contain"
                            />
                          ) : (
                            <div className="w-8 h-8 bg-dark-200 rounded flex items-center justify-center">
                              <IoFootballOutline className="text-dark-400" />
                            </div>
                          )}
                          <span className="font-semibold text-dark-900">
                            {match.homeTeam.name}
                          </span>
                        </div>
                        {match.status !== 'NS' && (
                          <span className="text-2xl font-bold text-dark-900 ml-4">
                            {match.homeTeam.score}
                          </span>
                        )}
                      </div>

                      {/* Away Team */}
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3 flex-1">
                          {match.awayTeam.logo ? (
                            <img 
                              src={match.awayTeam.logo} 
                              alt={match.awayTeam.name}
                              className="w-8 h-8 object-contain"
                            />
                          ) : (
                            <div className="w-8 h-8 bg-dark-200 rounded flex items-center justify-center">
                              <IoFootballOutline className="text-dark-400" />
                            </div>
                          )}
                          <span className="font-semibold text-dark-900">
                            {match.awayTeam.name}
                          </span>
                        </div>
                        {match.status !== 'NS' && (
                          <span className="text-2xl font-bold text-dark-900 ml-4">
                            {match.awayTeam.score}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))
        ) : (
          <div className="bg-white rounded-2xl p-12 text-center">
            <IoCalendarOutline className="text-6xl text-dark-300 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-dark-900 mb-2">
              No matches found
            </h3>
            <p className="text-dark-500">
              There are no matches scheduled for this category today.
            </p>
          </div>
        )}
      </div>
    </div>
  )
}

export default TodayMatchesPage
