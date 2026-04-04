import PropTypes from 'prop-types'
import { IoFootballOutline, IoTimeOutline } from 'react-icons/io5'
import { FaFutbol } from 'react-icons/fa'
import { MdSportsSoccer } from 'react-icons/md'

function MatchCard({ match }) {
  // Determine status display
  const getStatusDisplay = () => {
    if (match.status === 'LIVE' || match.status === 'IN_PLAY') {
      return (
        <span className="flex items-center gap-1 px-3 py-1 bg-red-500 text-white text-xs font-bold rounded-full animate-pulse">
          <span className="w-2 h-2 bg-white rounded-full"></span>
          LIVE {match.minute}'
        </span>
      )
    }
    if (match.status === 'HT') {
      return (
        <span className="px-3 py-1 bg-yellow-500 text-white text-xs font-bold rounded-full">
          HALF TIME
        </span>
      )
    }
    if (match.status === 'FT') {
      return (
        <span className="px-3 py-1 bg-dark-400 text-white text-xs font-bold rounded-full">
          FULL TIME
        </span>
      )
    }
    return (
      <span className="px-3 py-1 bg-dark-200 text-dark-600 text-xs font-bold rounded-full">
        {match.status}
      </span>
    )
  }

  // Get recent events (goals, cards)
  const getRecentEvents = () => {
    const goalEvents = match.events?.filter(
      (e) => e.type?.toLowerCase().includes('goal')
    ) || []
    
    return goalEvents.slice(-3) // Last 3 goals
  }

  const recentEvents = getRecentEvents()

  return (
    <div className="bg-white rounded-xl border border-dark-200 overflow-hidden hover:shadow-xl transition-all duration-300 group">
      {/* Header - League Info */}
      <div className="bg-gradient-primary px-4 py-2 flex items-center justify-between">
        <div className="flex items-center gap-2">
          {match.league.logo ? (
            <img
              src={match.league.logo}
              alt={match.league.name}
              className="w-5 h-5 object-contain"
            />
          ) : (
            <IoFootballOutline className="text-white text-lg" />
          )}
          <div className="text-white">
            <p className="text-xs font-semibold">{match.league.name}</p>
            <p className="text-xs opacity-80">{match.league.country}</p>
          </div>
        </div>
        {getStatusDisplay()}
      </div>

      {/* Main Content - Teams and Score */}
      <div className="p-5">
        {/* Round Info */}
        <div className="text-center mb-4">
          <p className="text-xs text-dark-500">{match.round}</p>
        </div>

        {/* Teams and Score */}
        <div className="space-y-4">
          {/* Home Team */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3 flex-1">
              {match.home.logo ? (
                <img
                  src={match.home.logo}
                  alt={match.home.name}
                  className="w-8 h-8 object-contain"
                />
              ) : (
                <div className="w-8 h-8 bg-gradient-primary rounded-full flex items-center justify-center">
                  <MdSportsSoccer className="text-white text-lg" />
                </div>
              )}
              <span className="font-semibold text-dark-900 group-hover:text-primary-500 transition-colors">
                {match.home.name}
              </span>
            </div>
            <span className="text-2xl font-bold text-dark-900 ml-4">
              {match.home.score}
            </span>
          </div>

          {/* Away Team */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3 flex-1">
              {match.away.logo ? (
                <img
                  src={match.away.logo}
                  alt={match.away.name}
                  className="w-8 h-8 object-contain"
                />
              ) : (
                <div className="w-8 h-8 bg-gradient-primary rounded-full flex items-center justify-center">
                  <MdSportsSoccer className="text-white text-lg" />
                </div>
              )}
              <span className="font-semibold text-dark-900 group-hover:text-primary-500 transition-colors">
                {match.away.name}
              </span>
            </div>
            <span className="text-2xl font-bold text-dark-900 ml-4">
              {match.away.score}
            </span>
          </div>
        </div>

        {/* Recent Events */}
        {recentEvents.length > 0 && (
          <div className="mt-4 pt-4 border-t border-dark-100">
            <p className="text-xs text-dark-500 mb-2 flex items-center gap-1">
              <FaFutbol className="text-primary-500" />
              Recent Goals
            </p>
            <div className="space-y-1">
              {recentEvents.map((event, idx) => (
                <div
                  key={idx}
                  className="flex items-center justify-between text-xs"
                >
                  <span className="text-dark-700">
                    {event.player}
                  </span>
                  <span className="text-dark-500 flex items-center gap-1">
                    <IoTimeOutline />
                    {event.minute}'
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="bg-dark-50 px-4 py-2 flex items-center justify-center">
        <button className="text-xs text-primary-500 hover:text-primary-600 font-medium transition-colors">
          View Details →
        </button>
      </div>
    </div>
  )
}

MatchCard.propTypes = {
  match: PropTypes.shape({
    id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
    league: PropTypes.shape({
      name: PropTypes.string.isRequired,
      country: PropTypes.string,
      logo: PropTypes.string,
    }).isRequired,
    round: PropTypes.string,
    home: PropTypes.shape({
      name: PropTypes.string.isRequired,
      logo: PropTypes.string,
      score: PropTypes.number.isRequired,
    }).isRequired,
    away: PropTypes.shape({
      name: PropTypes.string.isRequired,
      logo: PropTypes.string,
      score: PropTypes.number.isRequired,
    }).isRequired,
    status: PropTypes.string.isRequired,
    minute: PropTypes.number,
    events: PropTypes.arrayOf(
      PropTypes.shape({
        minute: PropTypes.number,
        type: PropTypes.string,
        player: PropTypes.string,
        team: PropTypes.string,
      })
    ),
  }).isRequired,
}

export default MatchCard
