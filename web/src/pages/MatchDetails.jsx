import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import SidebarLayout from '../layouts/SidebarLayout';
import '../styles/MatchDetails.css';

/**
 * MatchDetails Component
 * Displays comprehensive post-match analytics including:
 * - Match overview and scores
 * - Heatmap visualization (placeholder)
 * - Player performance list
 * - Team statistics comparison
 * - Match timeline with events (Goals, Fouls, Cards, Substitutions)
 */
const MatchDetails = ({ user, theme, toggleTheme }) => {
  // Get match ID from URL params
  const { id } = useParams();
  const matchId = parseInt(id);
  
  // Navigation hook for back button
  const navigate = useNavigate();
  
  // Sidebar menu items
  const menuItems = [
    {
      path: '/dashboard',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <rect x="3" y="3" width="7" height="7"/>
          <rect x="14" y="3" width="7" height="7"/>
          <rect x="14" y="14" width="7" height="7"/>
          <rect x="3" y="14" width="7" height="7"/>
        </svg>
      ),
      label: 'Analytics Dashboard'
    }
  ];
  
  // State for active tab selection
  const [activeTab, setActiveTab] = useState('overview');

  // ===== FAKE DATA - TO BE REPLACED WITH API CALLS =====

  /**
   * Mock match data
   * Complete match information with scores and metadata
   */
  const matchData = {
    id: matchId,
    homeTeam: {
      name: 'Manchester United',
      logo: '⚽',
      score: 2,
      formation: '4-3-3'
    },
    awayTeam: {
      name: 'Liverpool',
      logo: '⚽',
      score: 1,
      formation: '4-2-3-1'
    },
    date: '2026-02-04',
    venue: 'Old Trafford',
    attendance: '74,879',
    referee: 'Michael Oliver',
    status: 'Full Time'
  };

  /**
   * Mock team statistics data
   * Comparison of key performance metrics between both teams
   */
  const teamStats = [
    { label: 'Possession', home: 58, away: 42, unit: '%' },
    { label: 'Shots', home: 15, away: 12, unit: '' },
    { label: 'Shots on Target', home: 8, away: 5, unit: '' },
    { label: 'Pass Accuracy', home: 87, away: 82, unit: '%' },
    { label: 'Corners', home: 7, away: 4, unit: '' },
    { label: 'Fouls', home: 9, away: 13, unit: '' },
    { label: 'Offsides', home: 2, away: 3, unit: '' },
    { label: 'Yellow Cards', home: 2, away: 3, unit: '' },
    { label: 'Red Cards', home: 0, away: 0, unit: '' }
  ];

  /**
   * Mock home team player data
   * Player performance metrics and positions
   */
  const homeTeamPlayers = [
    { id: 1, number: 1, name: 'David De Gea', position: 'GK', rating: 7.8, goals: 0, assists: 0, passes: 32, tackles: 0 },
    { id: 2, number: 5, name: 'Harry Maguire', position: 'CB', rating: 7.5, goals: 0, assists: 0, passes: 58, tackles: 4 },
    { id: 3, number: 6, name: 'Lisandro Martinez', position: 'CB', rating: 8.0, goals: 0, assists: 0, passes: 52, tackles: 5 },
    { id: 4, number: 20, name: 'Diogo Dalot', position: 'RB', rating: 7.2, goals: 0, assists: 1, passes: 45, tackles: 3 },
    { id: 5, number: 23, name: 'Luke Shaw', position: 'LB', rating: 7.4, goals: 0, assists: 0, passes: 48, tackles: 2 },
    { id: 6, number: 8, name: 'Bruno Fernandes', position: 'CM', rating: 8.5, goals: 1, assists: 1, passes: 67, tackles: 2 },
    { id: 7, number: 18, name: 'Casemiro', position: 'DM', rating: 7.9, goals: 0, assists: 0, passes: 54, tackles: 6 },
    { id: 8, number: 14, name: 'Christian Eriksen', position: 'CM', rating: 7.6, goals: 0, assists: 0, passes: 62, tackles: 1 },
    { id: 9, number: 10, name: 'Marcus Rashford', position: 'LW', rating: 8.8, goals: 1, assists: 0, passes: 28, tackles: 0 },
    { id: 10, number: 9, name: 'Anthony Martial', position: 'ST', rating: 7.3, goals: 0, assists: 0, passes: 22, tackles: 0 },
    { id: 11, number: 21, name: 'Antony', position: 'RW', rating: 7.1, goals: 0, assists: 0, passes: 31, tackles: 1 }
  ];

  /**
   * Mock away team player data
   */
  const awayTeamPlayers = [
    { id: 12, number: 1, name: 'Alisson Becker', position: 'GK', rating: 6.8, goals: 0, assists: 0, passes: 28, tackles: 0 },
    { id: 13, number: 4, name: 'Virgil van Dijk', position: 'CB', rating: 6.9, goals: 0, assists: 0, passes: 52, tackles: 3 },
    { id: 14, number: 5, name: 'Ibrahima Konate', position: 'CB', rating: 6.7, goals: 0, assists: 0, passes: 46, tackles: 4 },
    { id: 15, number: 66, name: 'Trent Alexander-Arnold', position: 'RB', rating: 7.0, goals: 0, assists: 0, passes: 58, tackles: 1 },
    { id: 16, number: 26, name: 'Andy Robertson', position: 'LB', rating: 6.8, goals: 0, assists: 0, passes: 43, tackles: 2 },
    { id: 17, number: 3, name: 'Fabinho', position: 'DM', rating: 6.5, goals: 0, assists: 0, passes: 48, tackles: 4 },
    { id: 18, number: 8, name: 'Thiago Alcantara', position: 'CM', rating: 7.2, goals: 0, assists: 0, passes: 68, tackles: 2 },
    { id: 19, number: 14, name: 'Jordan Henderson', position: 'CM', rating: 6.6, goals: 0, assists: 0, passes: 51, tackles: 3 },
    { id: 20, number: 11, name: 'Mohamed Salah', position: 'RW', rating: 7.8, goals: 1, assists: 0, passes: 32, tackles: 0 },
    { id: 21, number: 9, name: 'Roberto Firmino', position: 'ST', rating: 6.4, goals: 0, assists: 0, passes: 24, tackles: 1 },
    { id: 22, number: 23, name: 'Luis Diaz', position: 'LW', rating: 7.0, goals: 0, assists: 0, passes: 29, tackles: 0 }
  ];

  /**
   * Mock match timeline events
   * Chronological list of significant match events
   */
  const timelineEvents = [
    { id: 1, minute: 12, type: 'goal', team: 'home', player: 'Marcus Rashford', description: 'Goal! Assisted by Bruno Fernandes' },
    { id: 2, minute: 23, type: 'yellow', team: 'away', player: 'Fabinho', description: 'Yellow card for tactical foul' },
    { id: 3, minute: 31, type: 'goal', team: 'away', player: 'Mohamed Salah', description: 'Goal! Long range strike' },
    { id: 4, minute: 38, type: 'yellow', team: 'home', player: 'Casemiro', description: 'Yellow card for rough tackle' },
    { id: 5, minute: 45, type: 'substitution', team: 'away', playerOut: 'Roberto Firmino', playerIn: 'Darwin Nunez', description: 'Substitution' },
    { id: 6, minute: 52, type: 'yellow', team: 'away', player: 'Jordan Henderson', description: 'Yellow card for dissent' },
    { id: 7, minute: 67, type: 'goal', team: 'home', player: 'Bruno Fernandes', description: 'Goal! Penalty kick' },
    { id: 8, minute: 72, type: 'substitution', team: 'home', playerOut: 'Anthony Martial', playerIn: 'Wout Weghorst', description: 'Substitution' },
    { id: 9, minute: 78, type: 'yellow', team: 'home', player: 'Luke Shaw', description: 'Yellow card for time wasting' },
    { id: 10, minute: 82, type: 'yellow', team: 'away', player: 'Andy Robertson', description: 'Yellow card for foul' },
    { id: 11, minute: 85, type: 'substitution', team: 'home', playerOut: 'Marcus Rashford', playerIn: 'Jadon Sancho', description: 'Substitution' },
    { id: 12, minute: 88, type: 'substitution', team: 'away', playerOut: 'Luis Diaz', playerIn: 'Harvey Elliott', description: 'Substitution' }
  ];

  // ===== HELPER FUNCTIONS =====

  /**
   * Get icon for timeline event type
   * @param {string} type - Event type (goal, yellow, red, substitution)
   * @returns {string} Emoji icon
   */
  const getEventIcon = (type) => {
    switch (type) {
      case 'goal': return '⚽';
      case 'yellow': return '🟨';
      case 'red': return '🟥';
      case 'substitution': return '🔄';
      default: return '⚪';
    }
  };

  /**
   * Get color class for timeline event
   * @param {string} type - Event type
   * @returns {string} CSS class name
   */
  const getEventClass = (type) => {
    return `event-${type}`;
  };

  /**
   * Calculate stat bar width percentage
   * @param {number} homeValue - Home team stat value
   * @param {number} awayValue - Away team stat value
   * @param {boolean} isHome - Whether calculating for home team
   * @returns {number} Percentage width
   */
  const getStatBarWidth = (homeValue, awayValue, isHome) => {
    const total = homeValue + awayValue;
    if (total === 0) return 50;
    const percentage = isHome ? (homeValue / total) * 100 : (awayValue / total) * 100;
    return Math.max(5, Math.min(95, percentage)); // Clamp between 5% and 95%
  };

  // ===== RENDER =====

  return (
    <SidebarLayout menuItems={menuItems} user={user} theme={theme} toggleTheme={toggleTheme}>
      <div className="match-details-container">
        {/* Top Action Bar */}
        <div className="match-details-top-bar">
          <button className="back-button" onClick={() => navigate('/')}>
            ← Back to Dashboard
          </button>
        </div>

      {/* Match Header */}
      <div className="match-header-section">
        <div className="match-info-card">
          <div className="match-status-badge">{matchData.status}</div>
          
          <div className="teams-score-container">
            {/* Home Team */}
            <div className="team-section home">
              <div className="team-logo-large">{matchData.homeTeam.logo}</div>
              <h2 className="team-name-large">{matchData.homeTeam.name}</h2>
              <div className="team-formation">{matchData.homeTeam.formation}</div>
            </div>

            {/* Score */}
            <div className="score-section">
              <div className="final-score">
                <span className="score-large">{matchData.homeTeam.score}</span>
                <span className="score-separator">-</span>
                <span className="score-large">{matchData.awayTeam.score}</span>
              </div>
            </div>

            {/* Away Team */}
            <div className="team-section away">
              <div className="team-logo-large">{matchData.awayTeam.logo}</div>
              <h2 className="team-name-large">{matchData.awayTeam.name}</h2>
              <div className="team-formation">{matchData.awayTeam.formation}</div>
            </div>
          </div>

          {/* Match Metadata */}
          <div className="match-metadata">
            <div className="metadata-item">
              <span className="metadata-label">📅 Date:</span>
              <span className="metadata-value">{matchData.date}</span>
            </div>
            <div className="metadata-item">
              <span className="metadata-label">🏟️ Venue:</span>
              <span className="metadata-value">{matchData.venue}</span>
            </div>
            <div className="metadata-item">
              <span className="metadata-label">👥 Attendance:</span>
              <span className="metadata-value">{matchData.attendance}</span>
            </div>
            <div className="metadata-item">
              <span className="metadata-label">👨‍⚖️ Referee:</span>
              <span className="metadata-value">{matchData.referee}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="tabs-navigation">
        <button 
          className={`tab-button ${activeTab === 'overview' ? 'active' : ''}`}
          onClick={() => setActiveTab('overview')}
        >
          📊 Overview
        </button>
        <button 
          className={`tab-button ${activeTab === 'heatmap' ? 'active' : ''}`}
          onClick={() => setActiveTab('heatmap')}
        >
          🔥 Heatmap
        </button>
        <button 
          className={`tab-button ${activeTab === 'players' ? 'active' : ''}`}
          onClick={() => setActiveTab('players')}
        >
          👥 Players
        </button>
        <button 
          className={`tab-button ${activeTab === 'timeline' ? 'active' : ''}`}
          onClick={() => setActiveTab('timeline')}
        >
          ⏱️ Timeline
        </button>
      </div>

      {/* Tab Content */}
      <div className="tab-content">
        
        {/* OVERVIEW TAB - Team Statistics */}
        {activeTab === 'overview' && (
          <div className="overview-section">
            <h2 className="section-title-large">Team Statistics Comparison</h2>
            <div className="stats-comparison-container">
              {teamStats.map((stat, index) => (
                <div key={index} className="stat-row">
                  <div className="stat-home-value">{stat.home}{stat.unit}</div>
                  <div className="stat-bar-container">
                    <div className="stat-label-center">{stat.label}</div>
                    <div className="stat-bars">
                      <div 
                        className="stat-bar stat-bar-home"
                        style={{ width: `${getStatBarWidth(stat.home, stat.away, true)}%` }}
                      />
                      <div 
                        className="stat-bar stat-bar-away"
                        style={{ width: `${getStatBarWidth(stat.home, stat.away, false)}%` }}
                      />
                    </div>
                  </div>
                  <div className="stat-away-value">{stat.away}{stat.unit}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* HEATMAP TAB - Placeholder */}
        {activeTab === 'heatmap' && (
          <div className="heatmap-section">
            <h2 className="section-title-large">Match Heatmap</h2>
            <div className="heatmap-placeholder">
              <div className="soccer-field">
                <div className="field-lines">
                  <div className="center-circle"></div>
                  <div className="center-line"></div>
                  <div className="penalty-box penalty-box-left"></div>
                  <div className="penalty-box penalty-box-right"></div>
                  <div className="goal-area goal-area-left"></div>
                  <div className="goal-area goal-area-right"></div>
                </div>
                <div className="heatmap-overlay">
                  {/* Placeholder heat spots */}
                  <div className="heat-spot" style={{ top: '30%', left: '40%', opacity: 0.8 }}></div>
                  <div className="heat-spot" style={{ top: '50%', left: '50%', opacity: 0.6 }}></div>
                  <div className="heat-spot" style={{ top: '40%', left: '70%', opacity: 0.7 }}></div>
                  <div className="heat-spot" style={{ top: '60%', left: '35%', opacity: 0.5 }}></div>
                  <div className="heat-spot" style={{ top: '70%', left: '60%', opacity: 0.9 }}></div>
                </div>
              </div>
              <p className="placeholder-text">📍 Heatmap visualization will be integrated with match analytics data</p>
            </div>
          </div>
        )}

        {/* PLAYERS TAB - Player Lists */}
        {activeTab === 'players' && (
          <div className="players-section">
            <h2 className="section-title-large">Player Performance</h2>
            
            <div className="teams-players-container">
              {/* Home Team Players */}
              <div className="team-players-card">
                <h3 className="team-players-title">
                  {matchData.homeTeam.logo} {matchData.homeTeam.name}
                </h3>
                <div className="players-table">
                  <div className="table-header">
                    <span className="col-number">#</span>
                    <span className="col-name">Player</span>
                    <span className="col-position">Pos</span>
                    <span className="col-rating">Rating</span>
                    <span className="col-stat">⚽</span>
                    <span className="col-stat">🅰️</span>
                    <span className="col-stat">📊</span>
                  </div>
                  {homeTeamPlayers.map((player) => (
                    <div key={player.id} className="table-row">
                      <span className="col-number">{player.number}</span>
                      <span className="col-name">{player.name}</span>
                      <span className="col-position">{player.position}</span>
                      <span className="col-rating">
                        <span className="rating-badge">{player.rating}</span>
                      </span>
                      <span className="col-stat">{player.goals}</span>
                      <span className="col-stat">{player.assists}</span>
                      <span className="col-stat">{player.passes}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Away Team Players */}
              <div className="team-players-card">
                <h3 className="team-players-title">
                  {matchData.awayTeam.logo} {matchData.awayTeam.name}
                </h3>
                <div className="players-table">
                  <div className="table-header">
                    <span className="col-number">#</span>
                    <span className="col-name">Player</span>
                    <span className="col-position">Pos</span>
                    <span className="col-rating">Rating</span>
                    <span className="col-stat">⚽</span>
                    <span className="col-stat">🅰️</span>
                    <span className="col-stat">📊</span>
                  </div>
                  {awayTeamPlayers.map((player) => (
                    <div key={player.id} className="table-row">
                      <span className="col-number">{player.number}</span>
                      <span className="col-name">{player.name}</span>
                      <span className="col-position">{player.position}</span>
                      <span className="col-rating">
                        <span className="rating-badge">{player.rating}</span>
                      </span>
                      <span className="col-stat">{player.goals}</span>
                      <span className="col-stat">{player.assists}</span>
                      <span className="col-stat">{player.passes}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* TIMELINE TAB - Match Events */}
        {activeTab === 'timeline' && (
          <div className="timeline-section">
            <h2 className="section-title-large">Match Timeline</h2>
            <div className="timeline-container">
              {timelineEvents.map((event) => (
                <div 
                  key={event.id} 
                  className={`timeline-event ${getEventClass(event.type)} ${event.team === 'home' ? 'home-event' : 'away-event'}`}
                >
                  <div className="event-time">
                    <span className="minute-badge">{event.minute}'</span>
                  </div>
                  <div className="event-icon">
                    {getEventIcon(event.type)}
                  </div>
                  <div className="event-content">
                    <div className="event-player">
                      {event.player || `${event.playerOut} → ${event.playerIn}`}
                    </div>
                    <div className="event-description">{event.description}</div>
                    <div className="event-team-badge">
                      {event.team === 'home' ? matchData.homeTeam.name : matchData.awayTeam.name}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
      </div>
    </SidebarLayout>
  );
};

export default MatchDetails;
