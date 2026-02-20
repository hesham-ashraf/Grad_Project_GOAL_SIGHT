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

    /**
     * Fetch leagues with today's matches grouped by league
     * @param {string} date - Date in YYYY-MM-DD format (optional, defaults to today)
     * @returns {Promise<Array>} Array of leagues with their matches
     */
    getLeaguesByDate: async(date) => {
        try {
            const SPORTMONKS_API_KEY = getApiKey()

            if (!SPORTMONKS_API_KEY) {
                throw new Error('SPORTMONKS_API_KEY is not configured')
            }

            const targetDate = date || new Date().toISOString().split('T')[0]
            const url = `${SPORTMONKS_BASE_URL}/leagues/date/${targetDate}`
            const params = {
                api_token: SPORTMONKS_API_KEY,
                include: 'today.scores;today.participants;today.stage;today.group;today.round',
            }

            console.log(`Fetching leagues for date: ${targetDate}`)
            console.log(`Full URL: ${url}`)
            console.log(`Query params:`, params)

            const response = await axios.get(url, { params })

            console.log('SportMonks API Response:', {
                status: response.status,
                leaguesCount: response.data ? .data ? .length || 0,
                hasData: !!response.data ? .data,
                dataType: typeof response.data ? .data,
                fullResponse: JSON.stringify(response.data).substring(0, 500),
            })

            const leagues = response.data.data || []

            // Normalize the leagues and their matches
            const normalizedLeagues = leagues.map((league) => ({
                id: league.id,
                name: league.name,
                country: league.country_id,
                logo: league.image_path,
                shortCode: league.short_code,
                type: league.type,
                subType: league.sub_type,
                category: league.category,
                matches: (league.today || []).map((match) => normalizeLeagueMatch(match)),
            }))

            console.log(`Returning ${normalizedLeagues.length} leagues with matches`)

            return normalizedLeagues
        } catch (error) {
            console.error('SportMonks API Error (getLeaguesByDate):', error.message)
            if (error.response) {
                console.error('API Response Status:', error.response.status)
                console.error('API Response Data:', JSON.stringify(error.response.data).substring(0, 500))
            }
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

    // Map state_id to status string
    const statusMap = {
        1: 'NS', // Not Started
        2: 'LIVE', // Live/In Play
        3: 'HT', // Half Time
        4: 'ET', // Extra Time
        5: 'FT', // Full Time
        6: 'POSTP', // Postponed
        7: 'CANC', // Cancelled
        8: 'ABD', // Abandoned
        12: 'LIVE', // Second Half
        14: 'PEN_LIVE', // Penalty Shootout
    }

    const status = statusMap[match.state_id] || 'NS'

    // Extract current minute from periods
    let currentMinute = 0
    if (match.periods && match.periods.length > 0) {
        const latestPeriod = match.periods[match.periods.length - 1]
        currentMinute = latestPeriod.minutes || 0
    }

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
        status: status,
        minute: currentMinute,
        startTime: match.starting_at || null,
        events: events,
    }
}

/**
 * Normalize match data from leagues endpoint
 * @param {Object} match - Raw match data from SportMonks API (from leagues endpoint)
 * @returns {Object} Normalized match object
 */
function normalizeLeagueMatch(match) {
    // Extract participants
    const participants = match.participants || []
    const homeTeam = participants.find((p) => p.meta ? .location === 'home') || {}
    const awayTeam = participants.find((p) => p.meta ? .location === 'away') || {}

    // Extract scores
    const scores = match.scores || []
    const homeScore = scores.find((s) => s.description === 'CURRENT' && s.participant_id === homeTeam.id)
    const awayScore = scores.find((s) => s.description === 'CURRENT' && s.participant_id === awayTeam.id)

    // Map state_id to status string
    const statusMap = {
        1: 'NS', // Not Started
        2: 'LIVE', // Live/In Play
        3: 'HT', // Half Time
        4: 'ET', // Extra Time
        5: 'FT', // Full Time
        6: 'POSTP', // Postponed
        7: 'CANC', // Cancelled
        8: 'ABD', // Abandoned
        10: 'FT_PEN', // After Penalties
        12: 'LIVE', // Second Half
        14: 'PEN_LIVE', // Penalty Shootout
        19: 'NS', // To Be Defined
    }

    const status = statusMap[match.state_id] || 'NS'

    return {
        id: match.id,
        name: match.name,
        homeTeam: {
            id: homeTeam.id,
            name: homeTeam.name || 'Home Team',
            logo: homeTeam.image_path || null,
            score: homeScore ? .score ? .goals || 0,
        },
        awayTeam: {
            id: awayTeam.id,
            name: awayTeam.name || 'Away Team',
            logo: awayTeam.image_path || null,
            score: awayScore ? .score ? .goals || 0,
        },
        status: status,
        startTime: match.starting_at || null,
        startTimestamp: match.starting_at_timestamp || null,
        stage: match.stage ? .name || null,
        round: match.round ? .name || null,
        group: match.group ? .name || null,
        leg: match.leg || null,
    }
}

export default sportmonksService