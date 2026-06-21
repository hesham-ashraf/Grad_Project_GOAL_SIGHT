import { IoCalendarOutline, IoFlashOutline, IoFootballOutline, IoShieldCheckmarkOutline, IoTimeOutline, IoTrendingUpOutline, IoTrophyOutline } from 'react-icons/io5'
import useAuthStore from '../context/authStore'
import { mockLiveMatches, mockRecentResults, mockTodayMatches } from '../data/mockData'
import StatCard from '../components/ui/StatCard'

const standingsData = [
  { team: 'Manchester City', played: 26, gd: 35, points: 62, form: 'WWDWW' },
  { team: 'Liverpool', played: 26, gd: 29, points: 60, form: 'WDWWW' },
  { team: 'Arsenal', played: 26, gd: 24, points: 55, form: 'WLWDW' },
  { team: 'Aston Villa', played: 26, gd: 15, points: 50, form: 'WDLWW' },
]

const activityFeed = [
  { id: 1, text: 'Marcus Rashford scored in Manchester United vs Liverpool', time: '3m ago', tone: 'goal' },
  { id: 2, text: 'Bayern Munich vs Dortmund lineup released', time: '16m ago', tone: 'lineup' },
  { id: 3, text: 'Two late goals changed the Juventus vs Inter result', time: '42m ago', tone: 'highlight' },
  { id: 4, text: 'GoalSight model confidence reached 96% for last predictions', time: '1h ago', tone: 'model' },
]

const toneStyles = {
  goal: 'bg-green-100 text-green-700',
  lineup: 'bg-blue-100 text-blue-700',
  highlight: 'bg-amber-100 text-amber-700',
  model: 'bg-purple-100 text-purple-700',
}

function formatMatchStatus(match) {
  if (match.status === 'LIVE') {
    return `${match.minute}'`
  }

  if (match.status === 'HT') {
    return 'Half-Time'
  }

  return match.status
}

function DashboardPage() {
  const user = useAuthStore((state) => state.user)

  const liveMatchesCount = mockLiveMatches.filter((match) => match.status === 'LIVE' || match.status === 'HT').length
  const totalLiveGoals = mockLiveMatches.reduce((sum, match) => sum + match.home.score + match.away.score, 0)
  const totalScheduled = mockTodayMatches.length
  const averageGoalsRecent = (
    mockRecentResults.reduce((sum, match) => sum + match.homeScore + match.awayScore, 0) /
    Math.max(mockRecentResults.length, 1)
  ).toFixed(1)

  const stats = [
    {
      id: 'live',
      title: 'Live Matches',
      value: liveMatchesCount,
      subtitle: 'Currently being tracked',
      trend: '+12%',
      trendLabel: 'vs last matchday',
      trendDirection: 'up',
      icon: IoFlashOutline,
      tone: 'primary',
    },
    {
      id: 'goals',
      title: 'Goals In Play',
      value: totalLiveGoals,
      subtitle: 'Across active fixtures',
      trend: '+7%',
      trendLabel: 'real-time pace',
      trendDirection: 'up',
      icon: IoFootballOutline,
      tone: 'secondary',
    },
    {
      id: 'scheduled',
      title: 'Scheduled Today',
      value: totalScheduled,
      subtitle: 'Upcoming fixtures',
      trend: '-3%',
      trendLabel: 'vs yesterday',
      trendDirection: 'down',
      icon: IoCalendarOutline,
      tone: 'dark',
    },
    {
      id: 'avg',
      title: 'Avg Goals / Match',
      value: averageGoalsRecent,
      subtitle: 'From recent results',
      trend: '+0.4',
      trendLabel: 'trend improving',
      trendDirection: 'up',
      icon: IoTrendingUpOutline,
      tone: 'primary',
    },
  ]

  return (
    <div className="min-h-full bg-dark-50 p-4 sm:p-6 lg:p-8">
      <div className="mx-auto max-w-7xl space-y-6 lg:space-y-8">
        <section className="relative overflow-hidden rounded-3xl bg-gradient-primary p-6 text-white shadow-xl sm:p-8">
          <div className="absolute -right-14 -top-14 h-48 w-48 rounded-full bg-white/10" />
          <div className="absolute -bottom-20 right-24 h-56 w-56 rounded-full bg-white/5" />

          <div className="relative flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
            <div>
              <p className="text-sm font-medium uppercase tracking-[0.2em] text-white/70">GoalSight Command Center</p>
              <h1 className="mt-2 text-2xl font-extrabold sm:text-3xl">
                Welcome back, {user?.name || 'Coach'}
              </h1>
              <p className="mt-3 max-w-2xl text-sm text-white/80 sm:text-base">
                Monitor match momentum, follow live events, and review tactical insights from today&apos;s fixtures.
              </p>
            </div>

            <div className="grid grid-cols-2 gap-3 rounded-2xl bg-white/10 p-3 text-center backdrop-blur-sm sm:min-w-[240px]">
              <div>
                <p className="text-xs uppercase tracking-wide text-white/70">Prediction Confidence</p>
                <p className="mt-1 text-xl font-bold">96%</p>
              </div>
              <div>
                <p className="text-xs uppercase tracking-wide text-white/70">Active Leagues</p>
                <p className="mt-1 text-xl font-bold">{mockLiveMatches.length}</p>
              </div>
            </div>
          </div>
        </section>

        <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {stats.map((item) => (
            <StatCard key={item.id} {...item} />
          ))}
        </section>

        <section className="grid gap-6 xl:grid-cols-[1.35fr,1fr]">
          <div className="rounded-2xl border border-dark-200 bg-white shadow-sm">
            <div className="flex items-center justify-between border-b border-dark-100 p-5">
              <h2 className="flex items-center gap-2 text-lg font-bold text-dark-900">
                <IoFootballOutline className="text-primary-500" />
                Live Match Tracker
              </h2>
              <span className="rounded-full bg-red-100 px-3 py-1 text-xs font-semibold text-red-600">
                {liveMatchesCount} live
              </span>
            </div>

            <div className="space-y-4 p-5">
              {mockLiveMatches.map((match) => (
                <article key={match.id} className="rounded-xl border border-dark-200 p-4 transition-shadow hover:shadow-md">
                  <div className="flex flex-wrap items-center justify-between gap-2 text-xs text-dark-500">
                    <span className="font-semibold text-dark-700">{match.league.name}</span>
                    <span className="inline-flex items-center gap-1 rounded-full bg-dark-100 px-2 py-1 font-medium text-dark-600">
                      <IoTimeOutline />
                      {formatMatchStatus(match)}
                    </span>
                  </div>

                  <div className="mt-3 grid grid-cols-[1fr,auto,1fr] items-center gap-3">
                    <p className="truncate text-sm font-semibold text-dark-900">{match.home.name}</p>
                    <p className="rounded-lg bg-dark-900 px-3 py-1 text-base font-bold text-white sm:text-lg">
                      {match.home.score} - {match.away.score}
                    </p>
                    <p className="truncate text-right text-sm font-semibold text-dark-900">{match.away.name}</p>
                  </div>

                  {match.events.length > 0 && (
                    <p className="mt-3 truncate text-xs text-dark-500">
                      Last event: {match.events[match.events.length - 1].minute}&apos; {match.events[match.events.length - 1].player}
                    </p>
                  )}
                </article>
              ))}
            </div>
          </div>

          <div className="space-y-6">
            <div className="rounded-2xl border border-dark-200 bg-white p-5 shadow-sm">
              <h2 className="flex items-center gap-2 text-lg font-bold text-dark-900">
                <IoShieldCheckmarkOutline className="text-secondary-500" />
                Activity Feed
              </h2>
              <ul className="mt-4 space-y-3">
                {activityFeed.map((entry) => (
                  <li key={entry.id} className="flex items-start justify-between gap-3 rounded-lg bg-dark-50 p-3">
                    <div>
                      <p className="text-sm font-medium text-dark-800">{entry.text}</p>
                      <p className="mt-1 text-xs text-dark-500">{entry.time}</p>
                    </div>
                    <span className={`rounded-full px-2 py-1 text-xs font-semibold ${toneStyles[entry.tone]}`}>
                      {entry.tone}
                    </span>
                  </li>
                ))}
              </ul>
            </div>

            <div className="rounded-2xl border border-dark-200 bg-white p-5 shadow-sm">
              <h2 className="flex items-center gap-2 text-lg font-bold text-dark-900">
                <IoCalendarOutline className="text-primary-500" />
                Upcoming Fixtures
              </h2>
              <div className="mt-4 space-y-3">
                {mockTodayMatches.map((fixture) => (
                  <div key={fixture.id} className="flex items-center justify-between rounded-lg border border-dark-100 p-3">
                    <div className="min-w-0">
                      <p className="truncate text-sm font-semibold text-dark-900">
                        {fixture.homeTeam} vs {fixture.awayTeam}
                      </p>
                      <p className="text-xs text-dark-500">{fixture.league}</p>
                    </div>
                    <p className="ml-3 text-sm font-bold text-primary-600">{fixture.time}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        <section className="rounded-2xl border border-dark-200 bg-white p-5 shadow-sm">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="flex items-center gap-2 text-lg font-bold text-dark-900">
              <IoTrophyOutline className="text-amber-500" />
              Quick Standings Snapshot
            </h2>
            <span className="text-xs text-dark-500">Updated 5 minutes ago</span>
          </div>

          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-sm">
              <thead>
                <tr className="border-b border-dark-200 text-xs uppercase tracking-wide text-dark-500">
                  <th className="px-2 py-3">Team</th>
                  <th className="px-2 py-3">P</th>
                  <th className="px-2 py-3">GD</th>
                  <th className="px-2 py-3">Pts</th>
                  <th className="px-2 py-3">Form</th>
                </tr>
              </thead>
              <tbody>
                {standingsData.map((row) => (
                  <tr key={row.team} className="border-b border-dark-100 last:border-b-0">
                    <td className="px-2 py-3 font-semibold text-dark-900">{row.team}</td>
                    <td className="px-2 py-3 text-dark-600">{row.played}</td>
                    <td className="px-2 py-3 text-dark-600">{row.gd > 0 ? `+${row.gd}` : row.gd}</td>
                    <td className="px-2 py-3 font-bold text-dark-900">{row.points}</td>
                    <td className="px-2 py-3">
                      <span className="rounded-full bg-primary-50 px-2 py-1 text-xs font-semibold text-primary-600">
                        {row.form}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </div>
  )
}

export default DashboardPage