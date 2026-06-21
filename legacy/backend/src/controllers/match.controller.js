/**
 * Match Controller
 * Handles match-related operations
 */

import Match from '../models/Match.model.js';

// Will be set when server.js is loaded
let io = null;

export const setIO = (ioInstance) => {
  io = ioInstance;
};

/**
 * @route   GET /api/v1/matches
 * @desc    Get all matches (with filtering and pagination)
 * @access  Public
 */
export const getAllMatches = async (req, res) => {
  try {
    // Extract query parameters
    const {
      status,
      league,
      season,
      team,
      page = 1,
      limit = 10,
      sortBy = 'date',
      order = 'desc'
    } = req.query;

    // Build filter object
    const filter = {};
    if (status) filter.status = status;
    if (league) filter.league = league;
    if (season) filter.season = season;
    
    // Filter by team name (search in both home and away)
    if (team) {
      filter.$or = [
        { 'homeTeam.name': new RegExp(team, 'i') },
        { 'awayTeam.name': new RegExp(team, 'i') }
      ];
    }

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sortOrder = order === 'asc' ? 1 : -1;

    // Execute query with filters, pagination, and sorting
    const matches = await Match.find(filter)
      .populate('createdBy', 'username email')
      .sort({ [sortBy]: sortOrder })
      .skip(skip)
      .limit(parseInt(limit));

    // Get total count for pagination metadata
    const total = await Match.countDocuments(filter);

    res.status(200).json({
      status: 'success',
      results: matches.length,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / parseInt(limit)),
        totalMatches: total,
        limit: parseInt(limit)
      },
      data: {
        matches
      }
    });
  } catch (error) {
    console.error('Get all matches error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to retrieve matches'
    });
  }
};

/**
 * @route   GET /api/v1/matches/upcoming
 * @desc    Get upcoming matches
 * @access  Public
 */
export const getUpcomingMatches = async (req, res) => {
  try {
    const matches = await Match.findUpcoming()
      .populate('createdBy', 'username email')
      .limit(10);

    res.status(200).json({
      status: 'success',
      results: matches.length,
      data: {
        matches
      }
    });
  } catch (error) {
    console.error('Get upcoming matches error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to retrieve upcoming matches'
    });
  }
};

/**
 * @route   GET /api/v1/matches/live
 * @desc    Get live matches
 * @access  Public
 */
export const getLiveMatches = async (req, res) => {
  try {
    const matches = await Match.findLive()
      .populate('createdBy', 'username email');

    res.status(200).json({
      status: 'success',
      results: matches.length,
      data: {
        matches
      }
    });
  } catch (error) {
    console.error('Get live matches error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to retrieve live matches'
    });
  }
};

/**
 * @route   GET /api/v1/matches/completed
 * @desc    Get completed matches
 * @access  Public
 */
export const getCompletedMatches = async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    const matches = await Match.findCompleted(parseInt(limit))
      .populate('createdBy', 'username email');

    res.status(200).json({
      status: 'success',
      results: matches.length,
      data: {
        matches
      }
    });
  } catch (error) {
    console.error('Get completed matches error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to retrieve completed matches'
    });
  }
};

/**
 * @route   GET /api/v1/matches/:id
 * @desc    Get single match by ID
 * @access  Public
 */
export const getMatchById = async (req, res) => {
  try {
    const { id } = req.params;

    const match = await Match.findById(id)
      .populate('createdBy', 'username email role');

    if (!match) {
      return res.status(404).json({
        status: 'error',
        message: 'Match not found'
      });
    }

    res.status(200).json({
      status: 'success',
      data: {
        match
      }
    });
  } catch (error) {
    console.error('Get match by ID error:', error);

    // Handle invalid ObjectId error
    if (error.name === 'CastError') {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid match ID'
      });
    }

    res.status(500).json({
      status: 'error',
      message: 'Failed to retrieve match'
    });
  }
};

/**
 * @route   POST /api/v1/matches
 * @desc    Create new match
 * @access  Private (Manager or Admin)
 */
export const createMatch = async (req, res) => {
  try {
    const matchData = {
      ...req.body,
      createdBy: req.user.id
    };

    const match = await Match.create(matchData);

    res.status(201).json({
      status: 'success',
      message: 'Match created successfully',
      data: {
        match
      }
    });
  } catch (error) {
    console.error('Create match error:', error);

    // Handle validation errors
    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        status: 'error',
        message: messages.join(', ')
      });
    }

    res.status(500).json({
      status: 'error',
      message: 'Failed to create match'
    });
  }
};

/**
 * @route   PUT /api/v1/matches/:id
 * @desc    Update match by ID
 * @access  Private (Manager or Admin)
 */
export const updateMatch = async (req, res) => {
  try {
    const { id } = req.params;

    const match = await Match.findByIdAndUpdate(
      id,
      req.body,
      {
        new: true, // Return updated document
        runValidators: true // Run schema validators
      }
    );

    if (!match) {
      return res.status(404).json({
        status: 'error',
        message: 'Match not found'
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'Match updated successfully',
      data: {
        match
      }
    });
  } catch (error) {
    console.error('Update match error:', error);

    // Handle validation errors
    if (error.name === 'ValidationError') {
      const messages = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        status: 'error',
        message: messages.join(', ')
      });
    }

    res.status(500).json({
      status: 'error',
      message: 'Failed to update match'
    });
  }
};

/**
 * @route   DELETE /api/v1/matches/:id
 * @desc    Delete match by ID
 * @access  Private (Admin only)
 */
export const deleteMatch = async (req, res) => {
  try {
    const { id } = req.params;

    const match = await Match.findByIdAndDelete(id);

    if (!match) {
      return res.status(404).json({
        status: 'error',
        message: 'Match not found'
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'Match deleted successfully'
    });
  } catch (error) {
    console.error('Delete match error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to delete match'
    });
  }
};

/**
 * @route   GET /api/v1/matches/team/:teamName
 * @desc    Get matches for a specific team
 * @access  Public
 */
export const getMatchesByTeam = async (req, res) => {
  try {
    const { teamName } = req.params;

    const matches = await Match.findByTeam(teamName)
      .populate('createdBy', 'username email');

    res.status(200).json({
      status: 'success',
      results: matches.length,
      data: {
        matches
      }
    });
  } catch (error) {
    console.error('Get matches by team error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to retrieve team matches'
    });
  }
};

/**
 * @route   GET /api/v1/matches/statistics/:league
 * @desc    Get league statistics
 * @access  Public
 */
export const getLeagueStatistics = async (req, res) => {
  try {
    const { league } = req.params;
    const { season = '2025/2026' } = req.query;

    const statistics = await Match.getLeagueStatistics(league, season);

    res.status(200).json({
      status: 'success',
      data: {
        league,
        season,
        statistics
      }
    });
  } catch (error) {
    console.error('Get league statistics error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to retrieve league statistics'
    });
  }
};

/**
 * @route   POST /api/v1/matches/:id/events
 * @desc    Add event to match (goal, card, substitution)
 * @access  Private (Manager or Admin)
 */
export const addMatchEvent = async (req, res) => {
  try {
    const { id } = req.params;
    const event = req.body;

    const match = await Match.findById(id);

    if (!match) {
      return res.status(404).json({
        status: 'error',
        message: 'Match not found'
      });
    }

    await match.addEvent(event);

    // 🔥 Broadcast event to WebSocket subscribers
    if (io && io.broadcastEventDetected) {
      io.broadcastEventDetected(id, {
        matchId: id,
        eventType: event.type,
        team: event.team,
        playerId: event.playerId,
        minute: event.minute,
        description: event.description || `${event.type} detected`,
        confidence: 1.0,
        timestamp: new Date().toISOString()
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'Event added successfully',
      data: {
        match
      }
    });
  } catch (error) {
    console.error('Add match event error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to add event'
    });
  }
};

/**
 * @route   POST /api/v1/matches/:id/simulate-match-data
 * @desc    Simulate and broadcast match data (for testing)
 * @access  Private (Admin only)
 */
export const simulateMatchData = async (req, res) => {
  try {
    const { id } = req.params;

    const match = await Match.findById(id);

    if (!match) {
      return res.status(404).json({
        status: 'error',
        message: 'Match not found'
      });
    }

    // Broadcast match data via WebSocket
    if (io && io.broadcastMatchData) {
      io.broadcastMatchData(id);
    }

    res.status(200).json({
      status: 'success',
      message: 'Match data broadcasted successfully',
      data: {
        matchId: id
      }
    });
  } catch (error) {
    console.error('Simulate match data error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to simulate match data'
    });
  }
};

/**
 * @route   POST /api/v1/matches/:id/simulate-player-update
 * @desc    Simulate and broadcast player update (for testing)
 * @access  Private (Admin only)
 */
export const simulatePlayerUpdate = async (req, res) => {
  try {
    const { id } = req.params;
    const { playerId } = req.body;

    if (!playerId) {
      return res.status(400).json({
        status: 'error',
        message: 'Player ID is required'
      });
    }

    const match = await Match.findById(id);

    if (!match) {
      return res.status(404).json({
        status: 'error',
        message: 'Match not found'
      });
    }

    // Broadcast player update via WebSocket
    if (io && io.broadcastPlayerUpdate) {
      io.broadcastPlayerUpdate(id, playerId);
    }

    res.status(200).json({
      status: 'success',
      message: 'Player update broadcasted successfully',
      data: {
        matchId: id,
        playerId
      }
    });
  } catch (error) {
    console.error('Simulate player update error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to simulate player update'
    });
  }
};

/**
 * @route   POST /api/v1/matches/:id/simulate-event
 * @desc    Simulate and broadcast event detection (for testing)
 * @access  Private (Admin only)
 */
export const simulateEvent = async (req, res) => {
  try {
    const { id } = req.params;

    const match = await Match.findById(id);

    if (!match) {
      return res.status(404).json({
        status: 'error',
        message: 'Match not found'
      });
    }

    // Broadcast event via WebSocket
    if (io && io.broadcastEventDetected) {
      io.broadcastEventDetected(id);
    }

    res.status(200).json({
      status: 'success',
      message: 'Event broadcasted successfully',
      data: {
        matchId: id
      }
    });
  } catch (error) {
    console.error('Simulate event error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to simulate event'
    });
  }
};

/**
 * @route   POST /api/v1/matches/:id/start-simulation
 * @desc    Start continuous mock data simulation for a match (for testing)
 * @access  Private (Admin only)
 */
export const startMatchSimulation = async (req, res) => {
  try {
    const { id } = req.params;

    const match = await Match.findById(id);

    if (!match) {
      return res.status(404).json({
        status: 'error',
        message: 'Match not found'
      });
    }

    // Start simulation with WebSocket
    if (io && io.startMockDataSimulation) {
      io.startMockDataSimulation(id, 2000); // Update every 2 seconds
    }

    res.status(200).json({
      status: 'success',
      message: 'Match simulation started successfully',
      data: {
        matchId: id,
        interval: '2000ms'
      }
    });
  } catch (error) {
    console.error('Start match simulation error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to start match simulation'
    });
  }
};

/**
 * @route   GET /api/v1/matches/websocket/stats
 * @desc    Get WebSocket connection statistics
 * @access  Private (Admin only)
 */
export const getWebSocketStats = async (req, res) => {
  try {
    // Get stats from WebSocket server
    const stats = io && io.getStats ? io.getStats() : {
      connectedClients: 0,
      activeMatches: 0,
      subscriptions: []
    };

    res.status(200).json({
      status: 'success',
      data: {
        stats
      }
    });
  } catch (error) {
    console.error('Get WebSocket stats error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to retrieve WebSocket stats'
    });
  }
};

export default {
  setIO,
  getAllMatches,
  getUpcomingMatches,
  getLiveMatches,
  getCompletedMatches,
  getMatchById,
  createMatch,
  updateMatch,
  deleteMatch,
  getMatchesByTeam,
  getLeagueStatistics,
  addMatchEvent,
  simulateMatchData,
  simulatePlayerUpdate,
  simulateEvent,
  startMatchSimulation,
  getWebSocketStats,
};
