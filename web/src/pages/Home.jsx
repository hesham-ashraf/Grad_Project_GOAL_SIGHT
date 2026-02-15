import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import SidebarLayout from '../layouts/SidebarLayout';
import '../styles/Home.css';

/**
 * Home Page Component
 * Main landing page after login with:
 * - Featured match
 * - Today's matches
 * - Latest news
 * - Recent results
 * - Video highlights
 */
const Home = ({ user, theme, toggleTheme }) => {
  const navigate = useNavigate();
  
  // Sidebar menu items
  const menuItems = [
    {
      path: '/dashboard',
      label: 'Analytics Dashboard',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <rect x="3" y="3" width="7" height="7"/>
          <rect x="14" y="3" width="7" height="7"/>
          <rect x="14" y="14" width="7" height="7"/>
          <rect x="3" y="14" width="7" height="7"/>
        </svg>
      )
    },
    {
      path: '/matches',
      label: 'Matches',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="12" cy="12" r="10"/>
          <path d="M12 2a10 10 0 0 0 0 20"/>
          <path d="M2 12h20"/>
        </svg>
      )
    },
    {
      path: '/favorites',
      label: 'Favorites',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
        </svg>
      )
    }
  ];
  
  // State management
  const [loading, setLoading] = useState(true);
  const [featuredMatch, setFeaturedMatch] = useState(null);
  const [todayMatches, setTodayMatches] = useState([]);
  const [news, setNews] = useState([]);
  const [recentResults, setRecentResults] = useState([]);
  const [videoHighlights, setVideoHighlights] = useState([]);
  const [error, setError] = useState(null);

  /**
   * Fetch sports data from SerpAPI
   */
  useEffect(() => {
    fetchHomeData();
  }, []);

  const fetchHomeData = async () => {
    setLoading(true);
    setError(null);

    try {
      // In production, replace with actual API calls
      // For now, using mock data structure
      
      // Simulate API call delay
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Mock data - Replace with actual SerpAPI calls
      setFeaturedMatch(getMockFeaturedMatch());
      setTodayMatches(getMockTodayMatches());
      setNews(getMockNews());
      setRecentResults(getMockRecentResults());
      setVideoHighlights(getMockVideoHighlights());
      
      setLoading(false);
    } catch (err) {
      console.error('Error fetching home data:', err);
      setError('Failed to load content. Please try again.');
      setLoading(false);
    }
  };

  /**
   * Navigate to analytics dashboard
   */
  const goToDashboard = () => {
    navigate('/dashboard');
  };

  /**
   * Navigate to match details
   */
  const viewMatchDetails = (matchId) => {
    navigate(`/match/${matchId}`);
  };

  return (
    <SidebarLayout menuItems={menuItems} user={user} theme={theme} toggleTheme={toggleTheme}>
      <div className="home-page">
        {/* Main Content */}
        <main className="home-content">
        {loading ? (
          <LoadingSkeleton />
        ) : error ? (
          <ErrorState error={error} onRetry={fetchHomeData} />
        ) : (
          <>
            {/* Featured Match */}
            {featuredMatch && (
              <FeaturedMatchCard match={featuredMatch} onView={viewMatchDetails} />
            )}

            {/* Today's Matches */}
            <section className="home-section">
              <h2 className="section-title">Today's Matches</h2>
              {todayMatches.length > 0 ? (
                <div className="matches-scroll">
                  {todayMatches.map((match) => (
                    <TodayMatchCard key={match.id} match={match} onView={viewMatchDetails} />
                  ))}
                </div>
              ) : (
                <EmptyState message="No matches scheduled for today" />
              )}
            </section>

            {/* Recent Results */}
            <section className="home-section">
              <h2 className="section-title">Recent Results</h2>
              {recentResults.length > 0 ? (
                <div className="results-grid">
                  {recentResults.map((result) => (
                    <ResultCard key={result.id} result={result} onView={viewMatchDetails} />
                  ))}
                </div>
              ) : (
                <EmptyState message="No recent results available" />
              )}
            </section>

            {/* Latest News */}
            <section className="home-section">
              <h2 className="section-title">Latest Football News</h2>
              {news.length > 0 ? (
                <div className="news-grid">
                  {news.map((article) => (
                    <NewsCard key={article.id} article={article} />
                  ))}
                </div>
              ) : (
                <EmptyState message="No news available" />
              )}
            </section>

            {/* Video Highlights */}
            <section className="home-section">
              <h2 className="section-title">Video Highlights</h2>
              {videoHighlights.length > 0 ? (
                <div className="video-grid">
                  {videoHighlights.map((video) => (
                    <VideoCard key={video.id} video={video} />
                  ))}
                </div>
              ) : (
                <EmptyState message="No highlights available" />
              )}
            </section>
          </>
        )}
      </main>
      </div>
    </SidebarLayout>
  );
};

/**
 * Featured Match Card Component
 */
const FeaturedMatchCard = ({ match, onView }) => (
  <section className="featured-match">
    <div className="featured-badge">
      <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>
      </svg>
      <span>Featured Match</span>
    </div>
    
    <div className="featured-content">
      <div className="match-time">
        <span className="status">{match.status}</span>
        <span className="time">{match.time}</span>
      </div>

      <div className="teams-container">
        <div className="team">
          <div className="team-logo">{match.homeTeam.logo}</div>
          <h3 className="team-name">{match.homeTeam.name}</h3>
          {match.status === 'Completed' && (
            <div className="team-score">{match.homeTeam.score}</div>
          )}
        </div>

        <div className="vs-separator">
          {match.status === 'Completed' ? '-' : 'VS'}
        </div>

        <div className="team">
          <div className="team-logo">{match.awayTeam.logo}</div>
          <h3 className="team-name">{match.awayTeam.name}</h3>
          {match.status === 'Completed' && (
            <div className="team-score">{match.awayTeam.score}</div>
          )}
        </div>
      </div>

      <div className="match-details">
        <span className="venue">{match.venue}</span>
        <span className="competition">{match.competition}</span>
      </div>

      <button className="view-match-btn" onClick={() => onView(match.id)}>
        View Analytics
      </button>
    </div>
  </section>
);

/**
 * Today's Match Card Component
 */
const TodayMatchCard = ({ match, onView }) => (
  <div className="today-match-card" onClick={() => onView(match.id)}>
    <div className="match-time-badge">{match.time}</div>
    <div className="match-teams">
      <div className="team-row">
        <span className="team-logo-sm">{match.homeTeam.logo}</span>
        <span className="team-name-sm">{match.homeTeam.name}</span>
      </div>
      <div className="team-row">
        <span className="team-logo-sm">{match.awayTeam.logo}</span>
        <span className="team-name-sm">{match.awayTeam.name}</span>
      </div>
    </div>
    <div className="match-competition-sm">{match.competition}</div>
  </div>
);

/**
 * Result Card Component
 */
const ResultCard = ({ result, onView }) => (
  <div className="result-card" onClick={() => onView(result.id)}>
    <div className="result-date">{result.date}</div>
    <div className="result-teams">
      <div className="result-team">
        <span className="team-logo-sm">{result.homeTeam.logo}</span>
        <span className="team-name-sm">{result.homeTeam.name}</span>
        <span className="team-score-sm">{result.homeTeam.score}</span>
      </div>
      <div className="result-team">
        <span className="team-logo-sm">{result.awayTeam.logo}</span>
        <span className="team-name-sm">{result.awayTeam.name}</span>
        <span className="team-score-sm">{result.awayTeam.score}</span>
      </div>
    </div>
    <div className="result-competition">{result.competition}</div>
  </div>
);

/**
 * News Card Component
 */
const NewsCard = ({ article }) => (
  <a 
    href={article.url} 
    target="_blank" 
    rel="noopener noreferrer" 
    className="news-card"
  >
    <div className="news-image" style={{ backgroundImage: `url(${article.image})` }}>
      {!article.image && <div className="news-placeholder">📰</div>}
    </div>
    <div className="news-content">
      <h3 className="news-title">{article.title}</h3>
      <p className="news-description">{article.description}</p>
      <div className="news-meta">
        <span className="news-source">{article.source}</span>
        <span className="news-time">{article.time}</span>
      </div>
    </div>
  </a>
);

/**
 * Video Card Component
 */
const VideoCard = ({ video }) => (
  <a 
    href={video.url} 
    target="_blank" 
    rel="noopener noreferrer" 
    className="video-card"
  >
    <div className="video-thumbnail">
      <img src={video.thumbnail} alt={video.title} onError={(e) => e.target.style.display = 'none'} />
      <div className="play-button">
        <svg width="40" height="40" viewBox="0 0 24 24" fill="white">
          <path d="M8 5v14l11-7z"/>
        </svg>
      </div>
      <div className="video-duration">{video.duration}</div>
    </div>
    <div className="video-info">
      <h4 className="video-title">{video.title}</h4>
      <p className="video-source">{video.source}</p>
    </div>
  </a>
);

/**
 * Loading Skeleton Component
 */
const LoadingSkeleton = () => (
  <div className="loading-skeleton">
    <div className="skeleton-featured"></div>
    <div className="skeleton-section">
      <div className="skeleton-title"></div>
      <div className="skeleton-cards">
        {[1, 2, 3].map(i => <div key={i} className="skeleton-card"></div>)}
      </div>
    </div>
  </div>
);

/**
 * Error State Component
 */
const ErrorState = ({ error, onRetry }) => (
  <div className="error-state">
    <div className="error-icon">⚠️</div>
    <h3>Oops! Something went wrong</h3>
    <p>{error}</p>
    <button className="retry-button" onClick={onRetry}>
      Try Again
    </button>
  </div>
);

/**
 * Empty State Component
 */
const EmptyState = ({ message }) => (
  <div className="empty-state">
    <div className="empty-icon">📭</div>
    <p>{message}</p>
  </div>
);

// ===== MOCK DATA FUNCTIONS =====
// Replace these with actual SerpAPI calls in production

const getMockFeaturedMatch = () => ({
  id: 1,
  homeTeam: {
    name: 'Manchester United',
    logo: '⚽',
    score: 2
  },
  awayTeam: {
    name: 'Liverpool',
    logo: '⚽',
    score: 1
  },
  status: 'Completed',
  time: 'Full Time',
  venue: 'Old Trafford',
  competition: 'Premier League',
  date: '2026-02-15'
});

const getMockTodayMatches = () => [
  {
    id: 2,
    homeTeam: { name: 'Arsenal', logo: '⚽' },
    awayTeam: { name: 'Chelsea', logo: '⚽' },
    time: '15:00',
    competition: 'Premier League'
  },
  {
    id: 3,
    homeTeam: { name: 'Real Madrid', logo: '⚽' },
    awayTeam: { name: 'Barcelona', logo: '⚽' },
    time: '20:00',
    competition: 'La Liga'
  },
  {
    id: 4,
    homeTeam: { name: 'Bayern Munich', logo: '⚽' },
    awayTeam: { name: 'Dortmund', logo: '⚽' },
    time: '18:30',
    competition: 'Bundesliga'
  }
];

const getMockRecentResults = () => [
  {
    id: 5,
    homeTeam: { name: 'Man City', logo: '⚽', score: 3 },
    awayTeam: { name: 'Tottenham', logo: '⚽', score: 2 },
    date: 'Feb 14',
    competition: 'Premier League'
  },
  {
    id: 6,
    homeTeam: { name: 'PSG', logo: '⚽', score: 1 },
    awayTeam: { name: 'Lyon', logo: '⚽', score: 1 },
    date: 'Feb 13',
    competition: 'Ligue 1'
  },
  {
    id: 7,
    homeTeam: { name: 'Juventus', logo: '⚽', score: 2 },
    awayTeam: { name: 'AC Milan', logo: '⚽', score: 0 },
    date: 'Feb 12',
    competition: 'Serie A'
  },
  {
    id: 8,
    homeTeam: { name: 'Atletico', logo: '⚽', score: 1 },
    awayTeam: { name: 'Sevilla', logo: '⚽', score: 1 },
    date: 'Feb 11',
    competition: 'La Liga'
  }
];

const getMockNews = () => [
  {
    id: 1,
    title: 'Manchester United secure crucial victory in title race',
    description: 'Red Devils defeat Liverpool 2-1 in thrilling encounter at Old Trafford',
    image: null,
    source: 'ESPN',
    time: '2h ago',
    url: '#'
  },
  {
    id: 2,
    title: 'Transfer News: Record-breaking deal confirmed',
    description: 'European giants finalize signing of young superstar for club record fee',
    image: null,
    source: 'Sky Sports',
    time: '5h ago',
    url: '#'
  },
  {
    id: 3,
    title: 'Champions League: Quarter-final draw announced',
    description: 'UEFA reveals matchups for the next stage of Europe\'s premier competition',
    image: null,
    source: 'UEFA.com',
    time: '1d ago',
    url: '#'
  }
];

const getMockVideoHighlights = () => [
  {
    id: 1,
    title: 'Manchester United 2-1 Liverpool | Extended Highlights',
    thumbnail: 'https://via.placeholder.com/300x200/667eea/ffffff?text=Match+Highlights',
    duration: '8:45',
    source: 'Premier League',
    url: '#'
  },
  {
    id: 2,
    title: 'Best Goals of the Week | Top 10',
    thumbnail: 'https://via.placeholder.com/300x200/764ba2/ffffff?text=Top+Goals',
    duration: '5:32',
    source: 'Goal',
    url: '#'
  },
  {
    id: 3,
    title: 'Tactical Analysis: Manchester Derby',
    thumbnail: 'https://via.placeholder.com/300x200/f093fb/ffffff?text=Analysis',
    duration: '12:15',
    source: 'Tifo Football',
    url: '#'
  }
];

export default Home;
