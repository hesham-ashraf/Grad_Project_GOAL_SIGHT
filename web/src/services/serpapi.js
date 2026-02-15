/**
 * SerpAPI Service
 * Integration with SerpAPI for fetching sports data:
 * - Sports results
 * - Match schedules
 * - Video highlights
 * - News articles
 */

const SERPAPI_BASE_URL = 'https://serpapi.com/search';
const SERPAPI_KEY = import.meta.env.VITE_SERPAPI_KEY || 'YOUR_API_KEY_HERE';

/**
 * Base API request function
 * @param {Object} params - Search parameters
 * @returns {Promise<Object>} API response data
 */
const serpApiRequest = async (params) => {
  try {
    const queryParams = new URLSearchParams({
      ...params,
      api_key: SERPAPI_KEY,
      engine: 'google'
    });

    const response = await fetch(`${SERPAPI_BASE_URL}?${queryParams}`);
    
    if (!response.ok) {
      throw new Error(`API Error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error('SerpAPI request failed:', error);
    throw error;
  }
};

/**
 * Fetch sports results for a specific team
 * @param {string} teamName - Team name (e.g., "Manchester United F.C.")
 * @param {string} location - Location for search context
 * @returns {Promise<Object>} Sports results data
 */
export const fetchTeamResults = async (teamName, location = 'United States') => {
  try {
    const data = await serpApiRequest({
      q: teamName,
      location: location
    });

    return {
      success: true,
      data: normalizeSportsResults(data.sports_results)
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Fetch recent match results
 * @param {string} query - Search query (e.g., "Premier League results")
 * @returns {Promise<Object>} Recent results data
 */
export const fetchRecentResults = async (query = 'football results today') => {
  try {
    const data = await serpApiRequest({
      q: query,
      location: 'United Kingdom'
    });

    return {
      success: true,
      data: normalizeSportsResults(data.sports_results)
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Fetch today's matches schedule
 * @param {string} league - League/competition name
 * @returns {Promise<Object>} Today's matches data
 */
export const fetchTodayMatches = async (league = 'Premier League') => {
  try {
    const data = await serpApiRequest({
      q: `${league} matches today`,
      location: 'United Kingdom'
    });

    return {
      success: true,
      data: normalizeTodayMatches(data.sports_results)
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Fetch video highlights for a specific match or team
 * @param {string} query - Search query (e.g., "Manchester United last match highlights")
 * @returns {Promise<Object>} Video highlights data
 */
export const fetchVideoHighlights = async (query) => {
  try {
    const data = await serpApiRequest({
      q: query,
      tbm: 'vid', // Video search
      location: 'United States'
    });

    return {
      success: true,
      data: normalizeVideoResults(data.video_results)
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Fetch latest football news
 * @param {string} query - News search query
 * @returns {Promise<Object>} News articles data
 */
export const fetchFootballNews = async (query = 'football news') => {
  try {
    const data = await serpApiRequest({
      q: query,
      tbm: 'nws', // News search
      location: 'United Kingdom'
    });

    return {
      success: true,
      data: normalizeNewsResults(data.news_results)
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
};

/**
 * Fetch featured match (latest big game)
 * @returns {Promise<Object>} Featured match data
 */
export const fetchFeaturedMatch = async () => {
  try {
    // Search for latest big match
    const data = await serpApiRequest({
      q: 'Premier League latest match result',
      location: 'United Kingdom'
    });

    const featuredMatch = normalizeFeaturedMatch(data.sports_results);

    return {
      success: true,
      data: featuredMatch
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
};

// ===== DATA NORMALIZATION FUNCTIONS =====

/**
 * Normalize sports results data for UI
 * @param {Object} sportsResults - Raw API sports results
 * @returns {Array} Normalized results array
 */
const normalizeSportsResults = (sportsResults) => {
  if (!sportsResults || !sportsResults.games) return [];

  return sportsResults.games.map((game, index) => ({
    id: index + 1,
    homeTeam: {
      name: game.teams?.[0]?.name || 'Home Team',
      logo: game.teams?.[0]?.thumbnail || '⚽',
      score: game.teams?.[0]?.score || 0
    },
    awayTeam: {
      name: game.teams?.[1]?.name || 'Away Team',
      logo: game.teams?.[1]?.thumbnail || '⚽',
      score: game.teams?.[1]?.score || 0
    },
    date: game.date || new Date().toISOString().split('T')[0],
    status: game.status || 'Completed',
    venue: game.venue || 'Stadium',
    competition: sportsResults.title || 'Football'
  }));
};

/**
 * Normalize today's matches for UI
 * @param {Object} sportsResults - Raw API sports results
 * @returns {Array} Normalized matches array
 */
const normalizeTodayMatches = (sportsResults) => {
  if (!sportsResults || !sportsResults.games) return [];

  return sportsResults.games
    .filter(game => game.status === 'Scheduled' || game.status === 'Live')
    .map((game, index) => ({
      id: index + 10,
      homeTeam: {
        name: game.teams?.[0]?.name || 'Home Team',
        logo: game.teams?.[0]?.thumbnail || '⚽'
      },
      awayTeam: {
        name: game.teams?.[1]?.name || 'Away Team',
        logo: game.teams?.[1]?.thumbnail || '⚽'
      },
      time: game.time || '15:00',
      competition: sportsResults.title || 'Football',
      status: game.status || 'Scheduled'
    }));
};

/**
 * Normalize video results for UI
 * @param {Array} videoResults - Raw API video results
 * @returns {Array} Normalized video array
 */
const normalizeVideoResults = (videoResults) => {
  if (!videoResults || !Array.isArray(videoResults)) return [];

  return videoResults.slice(0, 6).map((video, index) => ({
    id: index + 1,
    title: video.title || 'Football Highlight',
    thumbnail: video.thumbnail || 'https://via.placeholder.com/300x200',
    duration: video.duration || '5:00',
    source: video.source || 'YouTube',
    url: video.link || '#'
  }));
};

/**
 * Normalize news results for UI
 * @param {Array} newsResults - Raw API news results
 * @returns {Array} Normalized news array
 */
const normalizeNewsResults = (newsResults) => {
  if (!newsResults || !Array.isArray(newsResults)) return [];

  return newsResults.slice(0, 6).map((article, index) => ({
    id: index + 1,
    title: article.title || 'Football News',
    description: article.snippet || 'Latest football news and updates',
    image: article.thumbnail || null,
    source: article.source || 'News',
    time: article.date || 'Recently',
    url: article.link || '#'
  }));
};

/**
 * Normalize featured match for hero section
 * @param {Object} sportsResults - Raw API sports results
 * @returns {Object} Normalized featured match
 */
const normalizeFeaturedMatch = (sportsResults) => {
  if (!sportsResults || !sportsResults.games || sportsResults.games.length === 0) {
    return null;
  }

  const latestGame = sportsResults.games[0];

  return {
    id: 1,
    homeTeam: {
      name: latestGame.teams?.[0]?.name || 'Home Team',
      logo: latestGame.teams?.[0]?.thumbnail || '⚽',
      score: latestGame.teams?.[0]?.score || 0
    },
    awayTeam: {
      name: latestGame.teams?.[1]?.name || 'Away Team',
      logo: latestGame.teams?.[1]?.thumbnail || '⚽',
      score: latestGame.teams?.[1]?.score || 0
    },
    status: latestGame.status || 'Completed',
    time: latestGame.time || 'Full Time',
    venue: latestGame.venue || 'Stadium',
    competition: sportsResults.title || 'Football',
    date: latestGame.date || new Date().toISOString().split('T')[0]
  };
};

// ===== BATCH FETCH FUNCTION =====

/**
 * Fetch all home page data in one call
 * @returns {Promise<Object>} All home page data
 */
export const fetchAllHomeData = async () => {
  try {
    // Fetch all data in parallel
    const [featured, todayMatches, recentResults, news, highlights] = await Promise.allSettled([
      fetchFeaturedMatch(),
      fetchTodayMatches('Premier League'),
      fetchRecentResults('Premier League results'),
      fetchFootballNews('Premier League news'),
      fetchVideoHighlights('Premier League highlights')
    ]);

    return {
      featuredMatch: featured.status === 'fulfilled' ? featured.value.data : null,
      todayMatches: todayMatches.status === 'fulfilled' ? todayMatches.value.data : [],
      recentResults: recentResults.status === 'fulfilled' ? recentResults.value.data : [],
      news: news.status === 'fulfilled' ? news.value.data : [],
      videoHighlights: highlights.status === 'fulfilled' ? highlights.value.data : []
    };
  } catch (error) {
    console.error('Failed to fetch home data:', error);
    throw error;
  }
};

// ===== CONFIGURATION =====

/**
 * Check if SerpAPI is properly configured
 * @returns {boolean} True if API key is set
 */
export const isSerpApiConfigured = () => {
  return SERPAPI_KEY && SERPAPI_KEY !== 'YOUR_API_KEY_HERE';
};

/**
 * Get popular teams for dynamic queries
 * @returns {Array<string>} List of popular team names
 */
export const getPopularTeams = () => [
  'Manchester United F.C.',
  'Liverpool F.C.',
  'Manchester City F.C.',
  'Chelsea F.C.',
  'Arsenal F.C.',
  'Tottenham Hotspur F.C.',
  'Real Madrid C.F.',
  'FC Barcelona',
  'Bayern Munich',
  'Paris Saint-Germain F.C.'
];

/**
 * Get popular leagues for dynamic queries
 * @returns {Array<string>} List of popular league names
 */
export const getPopularLeagues = () => [
  'Premier League',
  'La Liga',
  'Bundesliga',
  'Serie A',
  'Ligue 1',
  'UEFA Champions League',
  'UEFA Europa League',
  'FIFA World Cup'
];

export default {
  fetchTeamResults,
  fetchRecentResults,
  fetchTodayMatches,
  fetchVideoHighlights,
  fetchFootballNews,
  fetchFeaturedMatch,
  fetchAllHomeData,
  isSerpApiConfigured,
  getPopularTeams,
  getPopularLeagues
};
