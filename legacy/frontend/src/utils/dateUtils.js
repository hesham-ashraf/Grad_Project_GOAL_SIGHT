/**
 * Date formatting utilities for GOALSIGHT application
 */

/**
 * Get today's date in YYYY-MM-DD format
 * @returns {string} Today's date
 */
export const getTodayDate = () => {
    const today = new Date()
    return today.toISOString().split('T')[0]
}

/**
 * Format date to readable string
 * @param {string|Date} date - Date to format
 * @returns {string} Formatted date (e.g., "Feb 18, 2026")
 */
export const formatMatchDate = (date) => {
    if (!date) return ''
    const dateObj = new Date(date)
    return dateObj.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
    })
}

/**
 * Format time from date string
 * @param {string|Date} date - Date/time to format
 * @returns {string} Formatted time (e.g., "20:00")
 */
export const formatMatchTime = (date) => {
    if (!date) return ''
    const dateObj = new Date(date)
    return dateObj.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        hour12: false
    })
}

/**
 * Check if a date is today
 * @param {string|Date} date - Date to check
 * @returns {boolean} True if date is today
 */
export const isToday = (date) => {
    if (!date) return false
    const dateObj = new Date(date)
    const today = new Date()
    return dateObj.toDateString() === today.toDateString()
}

/**
 * Check if a match is currently live
 * @param {string} status - Match status
 * @returns {boolean} True if match is live
 */
export const isLive = (status) => {
    const liveStatuses = ['LIVE', 'HT', 'ET', 'PEN_LIVE']
    return liveStatuses.includes(status)
}

/**
 * Get status display text
 * @param {string} status - Match status code
 * @param {string} startTime - Match start time
 * @returns {string} Display text for status
 */
export const getStatusDisplay = (status, startTime) => {
    const statusMap = {
        'NS': formatMatchTime(startTime),
        'LIVE': 'LIVE',
        'HT': 'Half Time',
        'ET': 'Extra Time',
        'FT': 'Full Time',
        'POSTP': 'Postponed',
        'CANC': 'Cancelled',
        'ABD': 'Abandoned',
        'PEN_LIVE': 'Penalties',
        'FT_PEN': 'FT (Pens)',
    }
    return statusMap[status] || status
}

/**
 * Format relative time (e.g., "in 2 hours", "30 minutes ago")
 * @param {string|Date} date - Date to format
 * @returns {string} Relative time string
 */
export const getRelativeTime = (date) => {
    if (!date) return ''

    const now = new Date()
    const targetDate = new Date(date)
    const diffMs = targetDate - now
    const diffMins = Math.floor(diffMs / 60000)
    const diffHours = Math.floor(diffMins / 60)
    const diffDays = Math.floor(diffHours / 24)

    if (diffMins < 0) {
        // Past
        const absMins = Math.abs(diffMins)
        if (absMins < 60) return `${absMins}m ago`
        if (absMins < 1440) return `${Math.floor(absMins / 60)}h ago`
        return `${Math.floor(absMins / 1440)}d ago`
    } else {
        // Future
        if (diffMins < 60) return `in ${diffMins}m`
        if (diffMins < 1440) return `in ${diffHours}h`
        return `in ${diffDays}d`
    }
}