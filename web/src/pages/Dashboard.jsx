import React from 'react';  
import { useNavigate } from 'react-router-dom';
import SidebarLayout from '../layouts/SidebarLayout';
import '../styles/Dashboard.css';

/**
 * Dashboard Component
 * Main dashboard page that displays match list and basic statistics
 * Will receive post-match analytics data in future steps
 */
const Dashboard = ({ user, onLogout, theme, toggleTheme }) => {
  // React Router navigation hook
  const navigate = useNavigate();
  
  // ===== FAKE DATA - TO BE REPLACED WITH API CALLS =====
  
  /**
   * Mock matches data
   * Each match contains: id, home team, away team, score, date, status
   */
  const matches = [
    {
      id: 1,
      homeTeam: 'Manchester United',
      homeLogo: '⚽',
      awayTeam: 'Liverpool',
      awayLogo: '⚽',
      homeScore: 2,
      awayScore: 1,
      date: '2026-02-04',
      status: 'Completed'
    },
    {
      id: 2,
      homeTeam: 'Real Madrid',
      homeLogo: '⚽',
      awayTeam: 'Barcelona',
      awayLogo: '⚽',
      homeScore: 3,
      awayScore: 3,
      date: '2026-02-03',
      status: 'Completed'
    },
    {
      id: 3,
      homeTeam: 'Bayern Munich',
      homeLogo: '⚽',
      awayTeam: 'Borussia Dortmund',
      awayLogo: '⚽',
      homeScore: 1,
      awayScore: 0,
      date: '2026-02-02',
      status: 'Completed'
    },
    {
      id: 4,
      homeTeam: 'PSG',
      homeLogo: '⚽',
      awayTeam: 'Lyon',
      awayLogo: '⚽',
      homeScore: null,
      awayScore: null,
      date: '2026-02-06',
      status: 'Upcoming'
    }
  ];

  /**
   * Mock statistics cards data
   * Basic stats to be displayed on dashboard
   */
  const statsCards = [
    {
      id: 1,
      title: 'Total Matches',
      value: '156',
      change: '+12%',
      isPositive: true,
      icon: '⚽'
    },
    {
      id: 2,
      title: 'Goals Scored',
      value: '423',
      change: '+8%',
      isPositive: true,
      icon: '🥅'
    },
    {
      id: 3,
      title: 'Win Rate',
      value: '67%',
      change: '+5%',
      isPositive: true,
      icon: '🏆'
    },
    {
      id: 4,
      title: 'Avg Possession',
      value: '58%',
      change: '-2%',
      isPositive: false,
      icon: '⚡'
    }
  ];

  // ===== EVENT HANDLERS =====

  /**
   * Handle view match details
   * Navigates to the match details page
   * @param {number} matchId - The ID of the match to view
   */
  const handleViewMatch = (matchId) => {
    navigate(`/match/${matchId}`);
  };

  // ===== RENDER =====

  const menuItems = [
    {
      path: '/',
      label: 'Dashboard',
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
    },
    {
      path: '/statistics',
      label: 'Statistics',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <line x1="12" y1="20" x2="12" y2="10"/>
          <line x1="18" y1="20" x2="18" y2="4"/>
          <line x1="6" y1="20" x2="6" y2="16"/>
        </svg>
      )
    }
  ];

  return (
    <SidebarLayout menuItems={menuItems} user={user}>
      <div className="dashboard-content">
        
        {/* Statistics Cards Section */}
        <section className="stats-section">
          <h2 className="section-title">Overview Statistics</h2>
          <div className="stats-grid">
            {statsCards.map((stat) => (
              <div key={stat.id} className="stat-card">
                <div className="stat-icon">{stat.icon}</div>
                <div className="stat-content">
                  <h3 className="stat-title">{stat.title}</h3>
                  <p className="stat-value">{stat.value}</p>
                  <span className={`stat-change ${stat.isPositive ? 'positive' : 'negative'}`}>
                    {stat.change} from last month
                  </span>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Matches List Section */}
        <section className="matches-section">
          <h2 className="section-title">Recent Matches</h2>
          <div className="matches-list">
            {matches.map((match) => (
              <div key={match.id} className="match-card">
                <div className="match-header">
                  <span className={`match-status ${match.status.toLowerCase()}`}>
                    {match.status}
                  </span>
                  <span className="match-date">{match.date}</span>
                </div>
                
                <div className="match-content">
                  {/* Home Team */}
                  <div className="team home-team">
                    <span className="team-logo">{match.homeLogo}</span>
                    <span className="team-name">{match.homeTeam}</span>
                  </div>

                  {/* Score or VS */}
                  <div className="match-score">
                    {match.status === 'Completed' ? (
                      <>
                        <span className="score">{match.homeScore}</span>
                        <span className="separator">-</span>
                        <span className="score">{match.awayScore}</span>
                      </>
                    ) : (
                      <span className="vs-text">VS</span>
                    )}
                  </div>

                  {/* Away Team */}
                  <div className="team away-team">
                    <span className="team-name">{match.awayTeam}</span>
                    <span className="team-logo">{match.awayLogo}</span>
                  </div>
                </div>

                {/* View Match Button */}
                <div className="match-footer">
                  <button 
                    className="view-match-btn"
                    onClick={() => handleViewMatch(match.id)}
                  >
                    View Match
                  </button>
                </div>
              </div>
            ))}
          </div>
        </section>

      </div>
    </SidebarLayout>
  );
};

export default Dashboard;
