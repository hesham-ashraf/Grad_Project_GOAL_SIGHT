import React, { useState } from 'react';
import SidebarLayout from '../layouts/SidebarLayout';
import '../styles/Manager.css';

const ManagerDashboard = () => {
  const user = {
    email: localStorage.getItem('userEmail'),
    role: localStorage.getItem('userRole')
  };

  const menuItems = [
    {
      path: '/manager',
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
      path: '/manager/team',
      label: 'Team',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
          <circle cx="9" cy="7" r="4"/>
          <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
          <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
        </svg>
      )
    },
    {
      path: '/manager/messenger',
      label: 'Messenger',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
        </svg>
      ),
      badge: 3
    },
    {
      path: '/manager/transfer',
      label: 'Transfer',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <polyline points="16 3 21 3 21 8"/>
          <line x1="4" y1="20" x2="21" y2="3"/>
          <polyline points="21 16 21 21 16 21"/>
          <line x1="15" y1="15" x2="21" y2="21"/>
          <line x1="4" y1="4" x2="9" y2="9"/>
        </svg>
      )
    },
    {
      path: '/manager/statistic',
      label: 'Statistic',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <line x1="12" y1="20" x2="12" y2="10"/>
          <line x1="18" y1="20" x2="18" y2="4"/>
          <line x1="6" y1="20" x2="6" y2="16"/>
        </svg>
      )
    },
    {
      path: '/manager/finance',
      label: 'Finance',
      icon: (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <line x1="12" y1="1" x2="12" y2="23"/>
          <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>
        </svg>
      )
    }
  ];

  const [activeTab, setActiveTab] = useState('overview');

  const lastGameStats = [
    { label: 'Shots', value: '37%' },
    { label: 'Pass', value: '59%' },
    { label: 'Discipline', value: '81%' },
    { label: 'Possession', value: '74%' }
  ];

  const standings = [
    { position: 10, team: 'FC Minsk', mp: 7, w: 1, d: 4, l: 2, g: 7, p: 8 },
    { position: 11, team: 'FC Gomel', mp: 6, w: 1, d: 4, l: 1, g: 7, p: 7 },
    { position: 12, team: 'Naftan (Novopolotsk)', mp: 6, w: 1, d: 4, l: 1, g: 1, p: 7 },
    { position: 13, team: 'Dynamo Brest (Brest)', mp: 5, w: 1, d: 0, l: 6, g: 0, p: 6 }
  ];

  return (
    <SidebarLayout menuItems={menuItems} user={user}>
      <div className="manager-content">
        {/* Top Section */}
        <div className="manager-grid">
          {/* Season Info */}
          <div className="season-card">
            <h2>2022/2023 Season</h2>
            <p className="league-name">Tour Belarusian Premier League</p>
            <div className="season-progress">
              <span className="progress-text">8 / 30</span>
            </div>
          </div>

          {/* Last Game Statistics */}
          <div className="stats-widget">
            <div className="widget-header">
              <h3>Last game statistics</h3>
              <button className="view-all-btn">View all</button>
            </div>
            <div className="circular-stats">
              {lastGameStats.map((stat, index) => (
                <div key={index} className="circular-stat">
                  <div className="circular-progress">
                    <svg viewBox="0 0 100 100">
                      <circle cx="50" cy="50" r="40" fill="none" stroke="var(--border-secondary)" strokeWidth="8"/>
                      <circle 
                        cx="50" 
                        cy="50" 
                        r="40" 
                        fill="none" 
                        stroke="var(--primary)" 
                        strokeWidth="8"
                        strokeDasharray={`${parseInt(stat.value)} ${100 - parseInt(stat.value)}`}
                        strokeLinecap="round"
                        transform="rotate(-90 50 50)"
                      />
                    </svg>
                    <span className="percentage">{stat.value}</span>
                  </div>
                  <span className="stat-name">{stat.label}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Standings */}
        <div className="standings-widget">
          <div className="widget-header">
            <h3>Standings</h3>
            <button className="view-all-btn">View all</button>
          </div>
          <div className="standings-table-container">
            <table className="standings-table">
              <thead>
                <tr>
                  <th>N°</th>
                  <th>Team</th>
                  <th>MP</th>
                  <th>W</th>
                  <th>D</th>
                  <th>L</th>
                  <th>G</th>
                  <th>P</th>
                </tr>
              </thead>
              <tbody>
                {standings.map((row, index) => (
                  <tr key={index}>
                    <td>{row.position}</td>
                    <td className="team-name-cell">
                      <span className="team-badge">🛡️</span>
                      {row.team}
                    </td>
                    <td>{row.mp}</td>
                    <td>{row.w}</td>
                    <td>{row.d}</td>
                    <td>{row.l}</td>
                    <td>{row.g}</td>
                    <td className="points">{row.p}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Bottom Section */}
        <div className="manager-grid-bottom">
          {/* Personal Characteristics */}
          <div className="characteristics-card">
            <div className="widget-header">
              <h3>Personal characteristics</h3>
              <button className="view-all-btn">View all</button>
            </div>
            <div className="player-profile">
              <img src="https://via.placeholder.com/80" alt="Player" className="player-avatar"/>
              <div className="player-info">
                <h4>Jonathan J.I.</h4>
                <p className="position">LW</p>
                <p className="contract">3 year 1 month</p>
              </div>
            </div>
            <div className="characteristics-bars">
              <div className="char-bar">
                <span className="char-label">Speed</span>
                <div className="bar-container">
                  <div className="bar" style={{width: '88%'}}></div>
                </div>
                <span className="char-value">88 / 100</span>
              </div>
              <div className="char-bar">
                <span className="char-label">Kicking</span>
                <div className="bar-container">
                  <div className="bar" style={{width: '61%'}}></div>
                </div>
                <span className="char-value">61 / 100</span>
              </div>
              <div className="char-bar">
                <span className="char-label">Reflexes</span>
                <div className="bar-container">
                  <div className="bar" style={{width: '91%'}}></div>
                </div>
                <span className="char-value">91 / 100</span>
              </div>
            </div>
          </div>

          {/* Top Transfers */}
          <div className="transfers-card">
            <div className="widget-header">
              <h3>Top transfers</h3>
              <button className="view-all-btn">View last month</button>
            </div>
            <div className="transfers-list">
              {[
                { name: 'Ploton K.S.', position: 'FWD', club: 'DNM', price: '13 000 $', flag: '🇧🇾' },
                { name: 'Jurasik L.N.', position: 'CM', club: 'GML', price: '9 650 $', flag: '🇧🇾' },
                { name: 'Kurlovich V.D.', position: 'CF', club: 'SMR', price: '8 130 $', flag: '🇧🇾' }
              ].map((transfer, index) => (
                <div key={index} className="transfer-item">
                  <div className="transfer-rank">{index + 1}</div>
                  <div className="transfer-flag">{transfer.flag}</div>
                  <div className="transfer-details">
                    <div className="transfer-name">{transfer.name}</div>
                    <div className="transfer-meta">
                      <span className="transfer-position">{transfer.position}</span>
                      <span className="transfer-club">{transfer.club}</span>
                    </div>
                  </div>
                  <div className="transfer-price">{transfer.price}</div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Next Game Sidebar */}
        <div className="next-game-sidebar">
          <div className="next-game-card">
            <div className="card-header">
              <h3>Next game</h3>
              <select className="calendar-select">
                <option>calendar</option>
              </select>
            </div>
            <div className="next-game-date">18:00, 11 September, 2023</div>
            <div className="league-badge">Belarusian Premier League 2023</div>
            
            <div className="match-teams">
              <div className="next-team">
                <div className="team-logo-large">⚽</div>
                <div className="team-name">FC GOMEL</div>
                <div className="team-status">Home</div>
                <button className="view-team-btn">View team</button>
              </div>
              <div className="vs-divider">VS</div>
              <div className="next-team">
                <div className="team-logo-large">⚽</div>
                <div className="team-name">Naftan (Novopolotsk)</div>
                <div className="team-status">Visitors</div>
                <button className="view-team-btn">View team</button>
              </div>
            </div>
          </div>

          {/* Your Team */}
          <div className="your-team-card">
            <div className="widget-header">
              <h3>Your team</h3>
              <button className="view-all-btn">View all</button>
            </div>
            <div className="team-section">
              <h4>Goalkeeper</h4>
              <div className="team-player">
                <span className="player-number">1</span>
                <img src="https://via.placeholder.com/32" alt="Player" className="mini-avatar"/>
                <span className="player-name">Kovalev D.L.</span>
                <span className="player-age">36 age</span>
              </div>
            </div>
            <div className="team-section">
              <h4>Defender</h4>
              {[
                { num: 51, name: 'Matveychi S.K.', age: 21 },
                { num: 45, name: 'Sikunduk F.D.', age: 24 }
              ].map((player, idx) => (
                <div key={idx} className="team-player">
                  <span className="player-number">{player.num}</span>
                  <img src="https://via.placeholder.com/32" alt="Player" className="mini-avatar"/>
                  <span className="player-name">{player.name}</span>
                  <span className="player-age">{player.age} age</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </SidebarLayout>
  );
};

export default ManagerDashboard;
