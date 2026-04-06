import {
  IoAnalyticsOutline,
  IoArrowForward,
  IoFlashOutline,
  IoFootballOutline,
  IoGitCompareOutline,
  IoPulseOutline,
  IoSparklesOutline,
  IoStatsChartOutline,
  IoTrendingUpOutline,
} from 'react-icons/io5'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  PolarAngleAxis,
  PolarGrid,
  PolarRadiusAxis,
  Radar,
  RadarChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import useAuthStore from '../context/authStore'
import StatCard from '../components/ui/StatCard'
import { mockLiveMatches, mockRecentResults, mockTodayMatches } from '../data/mockData'

const momentumData = [
  { phase: '00-15', pressure: 58, possession: 52 },
  { phase: '16-30', pressure: 63, possession: 54 },
  { phase: '31-45', pressure: 71, possession: 57 },
  { phase: '46-60', pressure: 66, possession: 55 },
  { phase: '61-75', pressure: 74, possession: 59 },
  { phase: '76-90', pressure: 79, possession: 61 },
]

const squadPerformanceData = [
  { metric: 'Pass Accuracy', home: 84, away: 78 },
  { metric: 'Shot Conversion', home: 42, away: 35 },
  { metric: 'Final Third Entries', home: 33, away: 27 },
  { metric: 'Duels Won', home: 58, away: 51 },
]

const tacticalRadarData = [
  { subject: 'Pressing', current: 81, target: 88 },
  { subject: 'Build-up', current: 75, target: 82 },
  { subject: 'Transitions', current: 79, target: 85 },
  { subject: 'Set Pieces', current: 68, target: 80 },
  { subject: 'Compactness', current: 83, target: 89 },
]

const insightCards = [
  {
    id: 'i1',
    title: 'Pressing Intensity Spike',
    body: 'Team press intensity rose by 14% after the 60th minute, forcing 4 recoveries in advanced zones.',
    tag: 'Tactical',
  },
  {
    id: 'i2',
    title: 'Wide Channel Overload',
    body: 'Right side combinations generated 38% of dangerous actions. Consider mirrored rotations on the left.',
    tag: 'Pattern',
  },
  {
    id: 'i3',
    title: 'Finishing Efficiency Alert',
    body: 'Expected goals trend is healthy, but conversion dipped in the final 20 minutes under high tempo.',
    tag: 'Alert',
  },
]

const topPerformers = [
  { player: 'Marcus Rashford', impact: 8.7, keyActions: 11, contribution: '2 goals' },
  { player: 'Bruno Fernandes', impact: 8.3, keyActions: 14, contribution: '1 assist' },
  { player: 'Federico Chiesa', impact: 7.9, keyActions: 9, contribution: '5 progressive carries' },
  { player: 'Lautaro Martinez', impact: 7.8, keyActions: 10, contribution: '4 shots on target' },
]

function AnalysisPage() {
  const user = useAuthStore((state) => state.user)

  const totalGoals = mockLiveMatches.reduce((sum, match) => sum + match.home.score + match.away.score, 0)
  const averageRecentGoals = (
    mockRecentResults.reduce((sum, match) => sum + match.homeScore + match.awayScore, 0) /
    Math.max(mockRecentResults.length, 1)
  ).toFixed(1)

  const metrics = [
    {
      id: 'analysis-1',
      title: 'Live Tactical Streams',
      value: mockLiveMatches.length,
      subtitle: 'Matches feeding the model',
      trend: '+9%',
      trendLabel: 'collection pace',
      trendDirection: 'up',
      icon: IoPulseOutline,
      tone: 'secondary',
    },
    {
      id: 'analysis-2',
      title: 'Event Density',
      value: totalGoals,
      subtitle: 'Goals in current samples',
      trend: '+6%',
      trendLabel: 'vs baseline',
      trendDirection: 'up',
      icon: IoFootballOutline,
      tone: 'primary',
    },
    {
      id: 'analysis-3',
      title: 'Avg Goals (Recent)',
      value: averageRecentGoals,
      subtitle: 'Recent-results aggregate',
      trend: '+0.3',
      trendLabel: 'upward trend',
      trendDirection: 'up',
      icon: IoTrendingUpOutline,
      tone: 'dark',
    },
    {
      id: 'analysis-4',
      title: 'Fixtures Analyzed',
      value: mockTodayMatches.length,
      subtitle: 'Scheduled in current cycle',
      trend: '-2%',
      trendLabel: 'vs prior day',
      trendDirection: 'down',
      icon: IoFlashOutline,
      tone: 'secondary',
    },
  ]

  return (
    <div className="min-h-full bg-dark-50 p-4 sm:p-6 lg:p-8">
      <div className="mx-auto max-w-7xl space-y-6 lg:space-y-8">
        <section className="relative overflow-hidden rounded-3xl bg-gradient-primary p-6 text-white shadow-xl sm:p-8">
          <div className="absolute -left-20 top-4 h-56 w-56 rounded-full bg-white/10" />
          <div className="absolute -right-20 bottom-[-60px] h-64 w-64 rounded-full bg-white/10" />

          <div className="relative flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <p className="text-sm font-medium uppercase tracking-[0.2em] text-white/70">Advanced Analysis Board</p>
              <h1 className="mt-2 text-2xl font-extrabold sm:text-3xl">
                Deep Match Analytics for {user?.name || 'Analyst'}
              </h1>
              <p className="mt-3 max-w-2xl text-sm text-white/85 sm:text-base">
                Explore momentum phases, tactical efficiency, and player-impact indicators powered by mock tracking data.
              </p>
            </div>

            <div className="inline-flex items-center gap-2 self-start rounded-full bg-white/15 px-4 py-2 text-sm font-semibold backdrop-blur">
              <IoSparklesOutline />
              AI confidence 96.2%
            </div>
          </div>
        </section>

        <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {metrics.map((item) => (
            <StatCard key={item.id} {...item} />
          ))}
        </section>

        <section className="grid gap-6 xl:grid-cols-2">
          <article className="rounded-2xl border border-dark-200 bg-white p-5 shadow-sm">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="flex items-center gap-2 text-lg font-bold text-dark-900">
                <IoStatsChartOutline className="text-primary-500" />
                Match Momentum Curve
              </h2>
              <span className="text-xs font-medium text-dark-500">Last 90 minutes</span>
            </div>
            <div className="h-72">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={momentumData} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                  <XAxis dataKey="phase" tick={{ fill: '#475569', fontSize: 12 }} />
                  <YAxis tick={{ fill: '#475569', fontSize: 12 }} />
                  <Tooltip
                    contentStyle={{
                      borderRadius: 12,
                      border: '1px solid #e2e8f0',
                      backgroundColor: '#ffffff',
                    }}
                  />
                  <Legend />
                  <Line type="monotone" dataKey="pressure" stroke="#8b5cf6" strokeWidth={3} dot={{ r: 3 }} />
                  <Line type="monotone" dataKey="possession" stroke="#3b82f6" strokeWidth={3} dot={{ r: 3 }} />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </article>

          <article className="rounded-2xl border border-dark-200 bg-white p-5 shadow-sm">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="flex items-center gap-2 text-lg font-bold text-dark-900">
                <IoGitCompareOutline className="text-secondary-500" />
                Team Comparison Snapshot
              </h2>
              <span className="text-xs font-medium text-dark-500">Home vs Away</span>
            </div>
            <div className="h-72">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={squadPerformanceData} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                  <XAxis dataKey="metric" tick={{ fill: '#475569', fontSize: 12 }} />
                  <YAxis tick={{ fill: '#475569', fontSize: 12 }} />
                  <Tooltip
                    contentStyle={{
                      borderRadius: 12,
                      border: '1px solid #e2e8f0',
                      backgroundColor: '#ffffff',
                    }}
                  />
                  <Legend />
                  <Bar dataKey="home" fill="#8b5cf6" radius={[6, 6, 0, 0]} />
                  <Bar dataKey="away" fill="#3b82f6" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </article>
        </section>

        <section className="grid gap-6 xl:grid-cols-[1.1fr,1fr]">
          <article className="rounded-2xl border border-dark-200 bg-white p-5 shadow-sm">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="flex items-center gap-2 text-lg font-bold text-dark-900">
                <IoAnalyticsOutline className="text-primary-500" />
                Tactical Quality Radar
              </h2>
              <span className="text-xs font-medium text-dark-500">Current vs Target</span>
            </div>
            <div className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <RadarChart data={tacticalRadarData} outerRadius="70%">
                  <PolarGrid stroke="#cbd5e1" />
                  <PolarAngleAxis dataKey="subject" tick={{ fill: '#475569', fontSize: 12 }} />
                  <PolarRadiusAxis tick={{ fill: '#94a3b8', fontSize: 10 }} />
                  <Tooltip />
                  <Radar name="Current" dataKey="current" stroke="#8b5cf6" fill="#8b5cf6" fillOpacity={0.25} />
                  <Radar name="Target" dataKey="target" stroke="#3b82f6" fill="#3b82f6" fillOpacity={0.16} />
                  <Legend />
                </RadarChart>
              </ResponsiveContainer>
            </div>
          </article>

          <article className="space-y-4 rounded-2xl border border-dark-200 bg-white p-5 shadow-sm">
            <h2 className="flex items-center gap-2 text-lg font-bold text-dark-900">
              <IoSparklesOutline className="text-amber-500" />
              Automated Insights
            </h2>
            {insightCards.map((insight) => (
              <div key={insight.id} className="rounded-xl border border-dark-100 bg-dark-50 p-4">
                <div className="mb-2 flex items-center justify-between">
                  <h3 className="text-sm font-bold text-dark-900">{insight.title}</h3>
                  <span className="rounded-full bg-primary-100 px-2 py-1 text-xs font-semibold text-primary-700">
                    {insight.tag}
                  </span>
                </div>
                <p className="text-sm text-dark-600">{insight.body}</p>
                <button className="mt-3 inline-flex items-center gap-1 text-xs font-semibold text-primary-600 hover:text-primary-700">
                  Review detail
                  <IoArrowForward />
                </button>
              </div>
            ))}
          </article>
        </section>

        <section className="rounded-2xl border border-dark-200 bg-white p-5 shadow-sm">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="flex items-center gap-2 text-lg font-bold text-dark-900">
              <IoTrendingUpOutline className="text-secondary-500" />
              Top Performer Index
            </h2>
            <span className="text-xs text-dark-500">Mock ranking, refresh every cycle</span>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-sm">
              <thead>
                <tr className="border-b border-dark-200 text-xs uppercase tracking-wide text-dark-500">
                  <th className="px-2 py-3">Player</th>
                  <th className="px-2 py-3">Impact</th>
                  <th className="px-2 py-3">Key Actions</th>
                  <th className="px-2 py-3">Contribution</th>
                </tr>
              </thead>
              <tbody>
                {topPerformers.map((player) => (
                  <tr key={player.player} className="border-b border-dark-100 last:border-b-0">
                    <td className="px-2 py-3 font-semibold text-dark-900">{player.player}</td>
                    <td className="px-2 py-3 text-primary-700 font-bold">{player.impact}</td>
                    <td className="px-2 py-3 text-dark-600">{player.keyActions}</td>
                    <td className="px-2 py-3 text-dark-700">{player.contribution}</td>
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

export default AnalysisPage