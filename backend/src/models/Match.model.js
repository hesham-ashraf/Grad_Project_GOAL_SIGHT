/**
 * Match Model
 * Defines the schema for Match collection
 */

import mongoose from 'mongoose';

const matchSchema = new mongoose.Schema(
  {
    homeTeam: {
      name: {
        type: String,
        required: [true, 'Home team name is required'],
      },
      logo: {
        type: String,
        default: '⚽',
      },
      score: {
        type: Number,
        default: 0,
      },
    },
    awayTeam: {
      name: {
        type: String,
        required: [true, 'Away team name is required'],
      },
      logo: {
        type: String,
        default: '⚽',
      },
      score: {
        type: Number,
        default: 0,
      },
    },
    date: {
      type: Date,
      required: [true, 'Match date is required'],
    },
    venue: {
      type: String,
      required: [true, 'Venue is required'],
    },
    league: {
      type: String,
      required: [true, 'League is required'],
    },
    season: {
      type: String,
      default: '2025/2026',
    },
    status: {
      type: String,
      enum: ['scheduled', 'live', 'completed', 'postponed', 'cancelled'],
      default: 'scheduled',
    },
    statistics: {
      possession: {
        home: { type: Number, default: 0 },
        away: { type: Number, default: 0 },
      },
      shots: {
        home: { type: Number, default: 0 },
        away: { type: Number, default: 0 },
      },
      shotsOnTarget: {
        home: { type: Number, default: 0 },
        away: { type: Number, default: 0 },
      },
      corners: {
        home: { type: Number, default: 0 },
        away: { type: Number, default: 0 },
      },
      fouls: {
        home: { type: Number, default: 0 },
        away: { type: Number, default: 0 },
      },
      yellowCards: {
        home: { type: Number, default: 0 },
        away: { type: Number, default: 0 },
      },
      redCards: {
        home: { type: Number, default: 0 },
        away: { type: Number, default: 0 },
      },
    },
    events: [
      {
        type: {
          type: String,
          enum: ['goal', 'yellow_card', 'red_card', 'substitution', 'penalty', 'own_goal'],
        },
        team: {
          type: String,
          enum: ['home', 'away'],
        },
        player: String,
        minute: Number,
        description: String,
        timestamp: {
          type: Date,
          default: Date.now,
        },
      },
    ],
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// ===== INDEXES =====
matchSchema.index({ date: -1 });
matchSchema.index({ status: 1 });
matchSchema.index({ league: 1 });
matchSchema.index({ 'homeTeam.name': 1 });
matchSchema.index({ 'awayTeam.name': 1 });

// ===== INSTANCE METHODS =====

/**
 * Add event to match
 * @param {Object} event - Event data
 */
matchSchema.methods.addEvent = function (event) {
  this.events.push(event);
  
  // Update statistics based on event type
  if (event.type === 'goal' && event.team === 'home') {
    this.homeTeam.score += 1;
  } else if (event.type === 'goal' && event.team === 'away') {
    this.awayTeam.score += 1;
  } else if (event.type === 'yellow_card') {
    if (event.team === 'home') {
      this.statistics.yellowCards.home += 1;
    } else {
      this.statistics.yellowCards.away += 1;
    }
  } else if (event.type === 'red_card') {
    if (event.team === 'home') {
      this.statistics.redCards.home += 1;
    } else {
      this.statistics.redCards.away += 1;
    }
  }
  
  return this.save();
};

// ===== STATIC METHODS =====

/**
 * Find upcoming matches
 * @returns {Promise<Array>} - Array of matches
 */
matchSchema.statics.findUpcoming = function () {
  return this.find({
    date: { $gte: new Date() },
    status: 'scheduled',
  }).sort({ date: 1 });
};

/**
 * Find live matches
 * @returns {Promise<Array>} - Array of matches
 */
matchSchema.statics.findLive = function () {
  return this.find({ status: 'live' }).sort({ date: -1 });
};

/**
 * Find completed matches
 * @param {number} limit - Number of matches to return
 * @returns {Promise<Array>} - Array of matches
 */
matchSchema.statics.findCompleted = function (limit = 10) {
  return this.find({ status: 'completed' })
    .sort({ date: -1 })
    .limit(limit);
};

/**
 * Find matches by team
 * @param {string} teamName - Team name
 * @returns {Promise<Array>} - Array of matches
 */
matchSchema.statics.findByTeam = function (teamName) {
  return this.find({
    $or: [
      { 'homeTeam.name': new RegExp(teamName, 'i') },
      { 'awayTeam.name': new RegExp(teamName, 'i') },
    ],
  }).sort({ date: -1 });
};

/**
 * Get league statistics
 * @param {string} league - League name
 * @param {string} season - Season (e.g., '2025/2026')
 * @returns {Promise<Object>} - Statistics object
 */
matchSchema.statics.getLeagueStatistics = async function (league, season) {
  const matches = await this.find({ league, season, status: 'completed' });

  const totalMatches = matches.length;
  const totalGoals = matches.reduce(
    (sum, match) => sum + match.homeTeam.score + match.awayTeam.score,
    0
  );

  return {
    totalMatches,
    totalGoals,
    averageGoals: totalMatches > 0 ? (totalGoals / totalMatches).toFixed(2) : 0,
  };
};

const Match = mongoose.model('Match', matchSchema);

export default Match;
