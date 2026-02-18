import axios from 'axios'

const SPORTMONKS_BASE_URL = 'https://api.sportmonks.com/v3/football'

/**
 * Get API key from environment (lazy loading)
 */
const getApiKey = () => process.env.SPORTMONKS_API_KEY

/**
 * SportMonks API Service
 * Handles all interactions with SportMonks football API
 */
const sportmonksService = {
    /**
     * Fetch live/in-play matches
     * @returns {Promise<Array>} Normalized match objects
     */
    getLiveMatches: async() => {
        try {
            const SPORTMONKS_API_KEY = getApiKey()

            if (!SPORTMONKS_API_KEY) {
                throw new Error('SPORTMONKS_API_KEY is not configured')
            }

            const response = await axios.get(
                `${SPORTMONKS_BASE_URL}/livescores/inplay`, {
                    params: {
                        api_token: SPORTMONKS_API_KEY,
                        include: 'participants;scores;periods;events;league.country;round',
                    },
                }
            )

            // Debug logging
            console.log('SportMonks API Response:', {
                status: response.status,
                dataCount: response.data ? .data ? .length || 0,
                rateLimit: response.data ? .rate_limit,
                subscription: response.data ? .subscription
            })

            // Normalize the API response
            const matches = response.data.data || []
            return matches.map((match) => normalizeMatch(match))
        } catch (error) {
            console.error('SportMonks API Error:', error.message)

            // Return empty array on error to prevent app crash
            if (error.response) {
                console.error('API Response Error:', error.response.data)
            }

            return []
        }
    },

    /**
     * Fetch today's fixtures
     * @returns {Promise<Array>} Normalized match objects
     */
    getTodayFixtures: async() => {
        try {
            const SPORTMONKS_API_KEY = getApiKey()

            if (!SPORTMONKS_API_KEY) {
                throw new Error('SPORTMONKS_API_KEY is not configured')
            }

            const today = new Date().toISOString().split('T')[0]

            const response = await axios.get(
                `${SPORTMONKS_BASE_URL}/fixtures/date/${today}`, {
                    params: {
                        api_token: SPORTMONKS_API_KEY,
                        include: 'participants;scores;league.country;round',
                    },
                }
            )

            const matches = response.data.data || []
            return matches.map((match) => normalizeMatch(match))
        } catch (error) {
            console.error('SportMonks API Error:', error.message)
            return []
        }
    },
}

/**
 * Normalize SportMonks match data to our application format
 * @param {Object} match - Raw match data from SportMonks API
 * @returns {Object} Normalized match object
 */
function normalizeMatch(match) {
    // Extract participants
    const participants = match.participants || []
    const homeTeam = participants.find((p) => p.meta ? .location === 'home') || {}
    const awayTeam = participants.find((p) => p.meta ? .location === 'away') || {}

    // Extract scores
    const scores = match.scores || []
    const homeScore = scores.find((s) => s.description === 'CURRENT' && s.participant_id === homeTeam.id)
    const awayScore = scores.find((s) => s.description === 'CURRENT' && s.participant_id === awayTeam.id)

    // Extract events (goals, cards, substitutions)
    const events = (match.events || []).map((event) => ({
        minute: event.minute || 0,
        type: event.type ? .name || event.type,
        player: event.player ? .display_name || 'Unknown',
        team: event.participant_id === homeTeam.id ? 'home' : 'away',
        injuryTime: event.injury_time || null,
    }))

    // Sort events by minute
    events.sort((a, b) => a.minute - b.minute)

    return {
        id: match.id,
        league: {
            name: match.league ? .name || 'Unknown League',
            country: match.league ? .country ? .name || 'Unknown',
            logo: match.league ? .image_path || null,
        },
        round: match.round ? .name || match.round || 'Round 1',
        home: {
            id: homeTeam.id,
            name: homeTeam.name || 'Home Team',
            logo: homeTeam.image_path || null,
            score: homeScore ? .score ? .goals || 0,
        },
        away: {
            id: awayTeam.id,
            name: awayTeam.name || 'Away Team',
            logo: awayTeam.image_path || null,
            score: awayScore ? .score ? .goals || 0,
        },
        status: match.state ? .short || match.state ? .state || 'NS',
        minute: match.time ? .minute || 0,
        startTime: match.starting_at || null,
        events: events,
    }
}

export default sportmonksService