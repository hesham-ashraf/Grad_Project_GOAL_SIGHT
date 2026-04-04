/**
 * Match Service
 * Handles all match-related API calls to the backend
 */

const API_BASE_URL = '/api'

const matchService = {
    /**
     * Get all live matches currently in play
     * @returns {Promise<Array>} Array of live match objects
     */
    getLiveMatches: async() => {
        try {
            const response = await fetch(`${API_BASE_URL}/live-matches`)

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`)
            }

            const data = await response.json()

            if (data.success) {
                return data.data || []
            } else {
                throw new Error(data.message || 'Failed to fetch live matches')
            }
        } catch (error) {
            console.error('Error fetching live matches:', error)
            throw error
        }
    },

    /**
     * Get today's fixtures
     * @returns {Promise<Array>} Array of today's match objects
     */
    getTodayFixtures: async() => {
        try {
            const response = await fetch(`${API_BASE_URL}/today-fixtures`)

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`)
            }

            const data = await response.json()

            if (data.success) {
                return data.data || []
            } else {
                throw new Error(data.message || 'Failed to fetch today\'s fixtures')
            }
        } catch (error) {
            console.error('Error fetching today\'s fixtures:', error)
            throw error
        }
    },

    /**
     * Get match by ID
     * @param {number} matchId - The match ID
     * @returns {Promise<Object>} Match object
     */
    getMatchById: async(matchId) => {
        try {
            const response = await fetch(`${API_BASE_URL}/matches/${matchId}`)

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`)
            }

            const data = await response.json()

            if (data.success) {
                return data.data
            } else {
                throw new Error(data.message || 'Failed to fetch match')
            }
        } catch (error) {
            console.error('Error fetching match:', error)
            throw error
        }
    },

    /**
     * Get leagues with today's matches grouped by league
     * @param {string} date - Optional date in YYYY-MM-DD format (defaults to today)
     * @returns {Promise<Array>} Array of league objects with matches
     */
    getTodayLeagues: async(date) => {
        try {
            const url = new URL(`${API_BASE_URL}/today-leagues`, window.location.origin)
            if (date) {
                url.searchParams.append('date', date)
            }

            const response = await fetch(url)

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`)
            }

            const data = await response.json()

            if (data.success) {
                return data.data || []
            } else {
                throw new Error(data.message || 'Failed to fetch today\'s leagues')
            }
        } catch (error) {
            console.error('Error fetching today\'s leagues:', error)
            throw error
        }
    },
}

export default matchService