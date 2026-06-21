import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { IoPlayCircleOutline, IoTimeOutline, IoTrophyOutline, IoCalendarOutline, IoArrowForward } from 'react-icons/io5'
import { mockFeaturedMatch, mockRecentResults, mockNews, mockHighlights, delay } from '../data/mockData'
import useAuthStore from '../context/authStore'
import LiveMatches from '../components/LiveMatches'
import matchService from '../services/matchService'
import { getTodayDate, formatMatchTime, getStatusDisplay } from '../utils/dateUtils'

function HomePage() {
  const user = useAuthStore((state) => state.user)
  const navigate = useNavigate()
  const [loading, setLoading] = useState(true)
  const [data, setData] = useState({
    featuredMatch: null,
    recentResults: [],
    todayMatches: [],
    news: [],
    highlights: [],
  })

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    setLoading(true)
    try {
      // Fetch real data from API
      const todayDate = getTodayDate()
      const leagues = await matchService.getTodayLeagues(todayDate)
      
      // Extract all matches from all leagues
      const allMatches = []
      leagues.forEach(league => {
        league.matches.forEach(match => {
          allMatches.push({
            ...match,
            leagueName: league.name,
            leagueLogo: league.logo
          })
        })
      })

      // Sort matches by start time
      allMatches.sort((a, b) => new Date(a.startTime) - new Date(b.startTime))

      // Get first 6 matches for the homepage
      const todayMatches = allMatches.slice(0, 6)

      // Simulate API delay for other mock data
      await delay(300)

      setData({
        featuredMatch: mockFeaturedMatch,
        recentResults: mockRecentResults,
        todayMatches: todayMatches,
        news: mockNews,
        highlights: mockHighlights,
      })
    } catch (error) {
      console.error('Error fetching data:', error)
      // Fall back to mock data on error
      setData({
        featuredMatch: mockFeaturedMatch,
        recentResults: mockRecentResults,
        todayMatches: [],
        news: mockNews,
        highlights: mockHighlights,
      })
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-dark-50 p-6">
        <div className="max-w-7xl mx-auto space-y-6">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="bg-white rounded-2xl p-6 animate-pulse">
              <div className="h-6 bg-dark-200 rounded w-1/4 mb-4"></div>
              <div className="h-32 bg-dark-200 rounded"></div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-dark-50">
      {/* Header */}
      <header className="bg-white border-b border-dark-200 px-6 py-4">
        <div className="max-w-7xl mx-auto">
          <h1 className="text-2xl font-bold text-dark-900">
            Welcome back, {user?.name || 'Fan'}! 👋
          </h1>
          <p className="text-dark-500 text-sm mt-1">
            Stay updated with the latest football action
          </p>
        </div>
      </header>

      <div className="max-w-7xl mx-auto p-6 space-y-6">
        {/* Live Matches Section */}
        <LiveMatches />

        {/* Featured Match */}
        <section>
          <h2 className="text-xl font-bold text-dark-900 mb-4 flex items-center gap-2">
            <IoTrophyOutline className="text-primary-500" />
            Featured Match
          </h2>
          <div className="bg-gradient-primary rounded-2xl p-6 text-white shadow-xl">
            <div className="flex items-center justify-between mb-4">
              <span className="text-sm opacity-90">{data.featuredMatch?.league}</span>
              <span className="px-3 py-1 bg-white/20 rounded-lg text-xs font-semibold">
                {data.featuredMatch?.status || 'LIVE'}
              </span>
            </div>
            <div className="flex items-center justify-between">
              <div className="text-center flex-1">
                <div className="text-4xl mb-2">⚽</div>
                <p className="font-bold">{data.featuredMatch?.homeTeam || 'Team A'}</p>
              </div>
              <div className="text-center px-8">
                <p className="text-4xl font-bold">{data.featuredMatch?.homeScore} - {data.featuredMatch?.awayScore}</p>
                <p className="text-sm opacity-90 mt-2">{data.featuredMatch?.minute ? `${data.featuredMatch.minute}'` : 'Today'}</p>
              </div>
              <div className="text-center flex-1">
                <div className="text-4xl mb-2">⚽</div>
                <p className="font-bold">{data.featuredMatch?.awayTeam || 'Team B'}</p>
              </div>
            </div>
            {data.featuredMatch?.stadium && (
              <div className="mt-4 pt-4 border-t border-white/20 text-center text-sm opacity-90">
                {data.featuredMatch.stadium} • {data.featuredMatch.attendance}
              </div>
            )}
          </div>
        </section>

        {/* Today's Matches */}
        <section>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-bold text-dark-900 flex items-center gap-2">
              <IoCalendarOutline className="text-secondary-500" />
              Today's Matches
            </h2>
            <button
              onClick={() => navigate('/today-matches')}
              className="flex items-center gap-2 px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors duration-200"
            >
              See All
              <IoArrowForward />
            </button>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {data.todayMatches.length > 0 ? (
              data.todayMatches.map((match) => (
                <div 
                  key={match.id} 
                  className="bg-white rounded-xl p-4 border border-dark-200 hover:shadow-lg transition-shadow duration-200 cursor-pointer"
                  onClick={() => navigate(`/match/${match.id}`)}
                >
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2">
                      {match.leagueLogo && (
                        <img src={match.leagueLogo} alt="" className="w-4 h-4 object-contain" />
                      )}
                      <span className="text-xs text-dark-500 truncate">{match.leagueName}</span>
                    </div>
                    <span className={`flex items-center gap-1 text-xs ${
                      match.status === 'LIVE' ? 'text-red-500 font-bold' : 'text-primary-500'
                    }`}>
                      <IoTimeOutline />
                      {getStatusDisplay(match.status, match.startTime)}
                    </span>
                  </div>
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2 flex-1">
                        {match.homeTeam.logo && (
                          <img src={match.homeTeam.logo} alt="" className="w-6 h-6 object-contain" />
                        )}
                        <span className="font-semibold text-dark-900 text-sm truncate">
                          {match.homeTeam.name}
                        </span>
                      </div>
                      {match.status !== 'NS' && (
                        <span className="font-bold text-dark-900 ml-2">{match.homeTeam.score}</span>
                      )}
                    </div>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2 flex-1">
                        {match.awayTeam.logo && (
                          <img src={match.awayTeam.logo} alt="" className="w-6 h-6 object-contain" />
                        )}
                        <span className="font-semibold text-dark-900 text-sm truncate">
                          {match.awayTeam.name}
                        </span>
                      </div>
                      {match.status !== 'NS' && (
                        <span className="font-bold text-dark-900 ml-2">{match.awayTeam.score}</span>
                      )}
                    </div>
                  </div>
                  {match.round && (
                    <p className="text-xs text-dark-400 mt-2">{match.round}</p>
                  )}
                </div>
              ))
            ) : (
              <p className="text-dark-500 col-span-3">No matches scheduled for today</p>
            )}
          </div>
        </section>

        {/* Recent Results */}
        {data.recentResults.length > 0 && (
          <section>
            <h2 className="text-xl font-bold text-dark-900 mb-4">Recent Results</h2>
            <div className="bg-white rounded-2xl border border-dark-200 overflow-hidden">
              {data.recentResults.map((match) => (
                <div
                  key={match.id}
                  className="flex items-center justify-between p-4 border-b border-dark-100 last:border-b-0 hover:bg-dark-50 transition-colors duration-200"
                >
                  <div className="flex-1">
                    <p className="font-semibold text-dark-900">
                      {match.homeTeam} vs {match.awayTeam}
                    </p>
                    <p className="text-xs text-dark-500">{match.league} • {match.date}</p>
                  </div>
                  <div className="text-center px-4">
                    <p className="font-bold text-dark-900">{match.homeScore} - {match.awayScore}</p>
                    <p className="text-xs text-dark-500">{match.status}</p>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Video Highlights */}
        {data.highlights.length > 0 && (
          <section>
            <h2 className="text-xl font-bold text-dark-900 mb-4 flex items-center gap-2">
              <IoPlayCircleOutline className="text-red-500" />
              Video Highlights
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {data.highlights.map((video) => (
                <div
                  key={video.id}
                  className="cursor-pointer"
                >
                  <div className="bg-white rounded-xl overflow-hidden border border-dark-200 hover:shadow-xl transition-all duration-200 group">
                    <div className="aspect-video bg-dark-200 relative overflow-hidden">
                      <img
                        src={video.thumbnail}
                        alt={video.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                      <div className="absolute inset-0 bg-black/20 group-hover:bg-black/40 transition-colors duration-200 flex items-center justify-center">
                        <IoPlayCircleOutline className="text-white text-6xl opacity-0 group-hover:opacity-100 transition-opacity duration-200" />
                      </div>
                      <div className="absolute bottom-2 right-2 bg-black/80 text-white text-xs px-2 py-1 rounded">
                        {video.duration}
                      </div>
                    </div>
                    <div className="p-4">
                      <h3 className="font-semibold text-dark-900 line-clamp-2 group-hover:text-primary-500 transition-colors duration-200">
                        {video.title}
                      </h3>
                      <div className="flex items-center justify-between mt-2">
                        <p className="text-xs text-dark-500">{video.league}</p>
                        <p className="text-xs text-dark-400">{video.views} views</p>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Latest News */}
        {data.news.length > 0 && (
          <section>
            <h2 className="text-xl font-bold text-dark-900 mb-4">Latest Football News</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {data.news.map((article) => (
                <div
                  key={article.id}
                  className="cursor-pointer"
                >
                  <div className="bg-white rounded-xl overflow-hidden border border-dark-200 hover:shadow-xl transition-all duration-200 group">
                    <div className="aspect-video bg-dark-200 overflow-hidden">
                      <img
                        src={article.thumbnail}
                        alt={article.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                    </div>
                    <div className="p-4">
                      <div className="flex items-center gap-2 mb-2">
                        <span className="text-xs bg-primary-100 text-primary-700 px-2 py-1 rounded">
                          {article.category}
                        </span>
                        <span className="text-xs text-dark-400">{article.date}</span>
                      </div>
                      <h3 className="font-semibold text-dark-900 line-clamp-2 mb-2 group-hover:text-primary-500 transition-colors duration-200">
                        {article.title}
                      </h3>
                      <p className="text-xs text-dark-500">{article.source}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  )
}

export default HomePage
