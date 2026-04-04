import sportmonksService from '../services/sportmonksService.js'

// In-memory cache
let cache = {
    data: null,
    lastFetch: null,
}

const CACHE_DURATION = 30 * 1000 // 30 seconds in milliseconds

/**
 * Live Matches Controller
 * Handles requests for live football matches
 */
const liveController = {
    /**
     * Get all live matches
     * @route GET /api/live-matches
     */
    getLiveMatches: async(req, res) => {
        try {
            const now = Date.now()

            // Check if cache is valid
            if (cache.data && cache.lastFetch && now - cache.lastFetch < CACHE_DURATION) {
                return res.status(200).json({
                    success: true,
                    data: cache.data,
                    cached: true,
                    cacheAge: Math.floor((now - cache.lastFetch) / 1000), // seconds
                })
            }

            // Fetch fresh data from SportMonks
            const liveMatches = await sportmonksService.getLiveMatches()

            // Update cache
            cache = {
                data: liveMatches,
                lastFetch: now,
            }

            return res.status(200).json({
                success: true,
                data: liveMatches,
                cached: false,
                count: liveMatches.length,
            })
        } catch (error) {
            console.error('Live matches controller error:', error)

            return res.status(500).json({
                success: false,
                message: 'Failed to fetch live matches',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined,
            })
        }
    },

    /**
     * Get today's fixtures
     * @route GET /api/today-fixtures
     */
    getTodayFixtures: async(req, res) => {
        try {
            const fixtures = await sportmonksService.getTodayFixtures()

            return res.status(200).json({
                success: true,
                data: fixtures,
                count: fixtures.length,
            })
        } catch (error) {
            console.error('Today fixtures controller error:', error)

            return res.status(500).json({
                success: false,
                message: 'Failed to fetch today\'s fixtures',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined,
            })
        }
    },

    /**
     * Clear cache (useful for testing)
     * @route POST /api/live-matches/clear-cache
     */
    clearCache: (req, res) => {
        cache = {
            data: null,
            lastFetch: null,
        }

        return res.status(200).json({
            success: true,
            message: 'Cache cleared successfully',
        })
    },

    /**
     * Get leagues with today's matches grouped by league
     * @route GET /api/today-leagues
     */
    getTodayLeagues: async(req, res) => {
        try {
            const { date } = req.query // Optional date parameter

            const leagues = await sportmonksService.getLeaguesByDate(date)

            return res.status(200).json({
                success: true,
                data: leagues,
                count: leagues.length,
            })
        } catch (error) {
            console.error('Today leagues controller error:', error)

            return res.status(500).json({
                success: false,
                message: 'Failed to fetch today\'s leagues',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined,
            })
        }
    },
}

export default liveController