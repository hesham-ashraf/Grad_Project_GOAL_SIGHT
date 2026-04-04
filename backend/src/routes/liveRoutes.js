import express from 'express'
import liveController from '../controllers/liveController.js'

const router = express.Router()

/**
 * @route   GET /api/live-matches
 * @desc    Get all live/in-play matches
 * @access  Public
 */
router.get('/live-matches', liveController.getLiveMatches)

/**
 * @route   GET /api/today-fixtures
 * @desc    Get all fixtures for today
 * @access  Public
 */
router.get('/today-fixtures', liveController.getTodayFixtures)

/**
 * @route   POST /api/live-matches/clear-cache
 * @desc    Clear the in-memory cache
 * @access  Public (should be protected in production)
 */
router.post('/live-matches/clear-cache', liveController.clearCache)

/**
 * @route   GET /api/today-leagues
 * @desc    Get all leagues with today's matches grouped by league
 * @access  Public
 */
router.get('/today-leagues', liveController.getTodayLeagues)

export default router