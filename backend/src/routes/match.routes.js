/**
 * Match Routes
 * Defines all match-related endpoints
 */

import express from 'express';
import {
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
} from '../controllers/match.controller.js';
import { protect, restrictTo, optionalAuth } from '../middlewares/auth.middleware.js';

const router = express.Router();

// ===== PUBLIC ROUTES (No Authentication Required) =====

/**
 * GET /api/v1/matches
 * Get all matches with filtering and pagination
 */
router.get('/', optionalAuth, getAllMatches);

/**
 * GET /api/v1/matches/upcoming
 * Get upcoming scheduled matches
 */
router.get('/upcoming', getUpcomingMatches);

/**
 * GET /api/v1/matches/live
 * Get currently live matches
 */
router.get('/live', getLiveMatches);

/**
 * GET /api/v1/matches/completed
 * Get recently completed matches
 */
router.get('/completed', getCompletedMatches);

/**
 * GET /api/v1/matches/statistics/:league
 * Get statistics for a specific league
 */
router.get('/statistics/:league', getLeagueStatistics);

/**
 * GET /api/v1/matches/team/:teamName
 * Get all matches for a specific team
 */
router.get('/team/:teamName', getMatchesByTeam);

/**
 * GET /api/v1/matches/:id
 * Get single match by ID
 */
router.get('/:id', getMatchById);

// ===== PROTECTED ROUTES (Manager or Admin only) =====

/**
 * POST /api/v1/matches
 * Create new match
 * Manager or Admin only
 */
router.post('/', protect, restrictTo('manager', 'admin'), createMatch);

/**
 * PUT /api/v1/matches/:id
 * Update match by ID
 * Manager or Admin only
 */
router.put('/:id', protect, restrictTo('manager', 'admin'), updateMatch);

/**
 * POST /api/v1/matches/:id/events
 * Add event to match (goal, card, substitution)
 * Manager or Admin only
 */
router.post('/:id/events', protect, restrictTo('manager', 'admin'), addMatchEvent);

/**
 * DELETE /api/v1/matches/:id
 * Delete match by ID
 * Admin only
 */
router.delete('/:id', protect, restrictTo('admin'), deleteMatch);

// ===== WEBSOCKET TESTING ROUTES (Admin only) =====

/**
 * GET /api/v1/matches/websocket/stats
 * Get WebSocket connection statistics
 * Admin only
 */
router.get('/websocket/stats', protect, restrictTo('admin'), getWebSocketStats);

/**
 * POST /api/v1/matches/:id/simulate-match-data
 * Simulate and broadcast match data via WebSocket
 * Admin only - for testing purposes
 */
router.post('/:id/simulate-match-data', protect, restrictTo('admin'), simulateMatchData);

/**
 * POST /api/v1/matches/:id/simulate-player-update
 * Simulate and broadcast player update via WebSocket
 * Admin only - for testing purposes
 */
router.post('/:id/simulate-player-update', protect, restrictTo('admin'), simulatePlayerUpdate);

/**
 * POST /api/v1/matches/:id/simulate-event
 * Simulate and broadcast event detection via WebSocket
 * Admin only - for testing purposes
 */
router.post('/:id/simulate-event', protect, restrictTo('admin'), simulateEvent);

/**
 * POST /api/v1/matches/:id/start-simulation
 * Start continuous mock data simulation for a match
 * Admin only - for testing purposes
 */
router.post('/:id/start-simulation', protect, restrictTo('admin'), startMatchSimulation);

export default router;
