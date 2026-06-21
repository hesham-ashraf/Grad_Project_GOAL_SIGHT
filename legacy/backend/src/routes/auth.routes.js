/**
 * Authentication Routes
 * Defines authentication endpoints
 */

import express from 'express';
import {
  register,
  login,
  getMe,
  updateProfile,
  changePassword,
} from '../controllers/auth.controller.js';
import { protect } from '../middlewares/auth.middleware.js';

const router = express.Router();

// ===== PUBLIC ROUTES =====

/**
 * POST /api/v1/auth/register
 * Register a new user
 */
router.post('/register', register);

/**
 * POST /api/v1/auth/login
 * Login user
 */
router.post('/login', login);

// ===== PROTECTED ROUTES =====

/**
 * GET /api/v1/auth/me
 * Get current user profile
 * Requires authentication
 */
router.get('/me', protect, getMe);

/**
 * PUT /api/v1/auth/update-profile
 * Update user profile
 * Requires authentication
 */
router.put('/update-profile', protect, updateProfile);

/**
 * PUT /api/v1/auth/change-password
 * Change user password
 * Requires authentication
 */
router.put('/change-password', protect, changePassword);

export default router;
