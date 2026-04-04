/**
 * User Routes
 * Defines user management endpoints (Admin only)
 */

import express from 'express';
import {
  getAllUsers,
  getUserStatistics,
  getUsersByRole,
  getUserById,
  updateUser,
  deactivateUser,
  activateUser,
} from '../controllers/user.controller.js';
import { protect, restrictTo } from '../middlewares/auth.middleware.js';

const router = express.Router();

// ===== ALL ROUTES REQUIRE ADMIN ACCESS =====

/**
 * GET /api/v1/users
 * Get all users with pagination and filtering
 */
router.get('/', protect, restrictTo('admin'), getAllUsers);

/**
 * GET /api/v1/users/stats/overview
 * Get user statistics
 */
router.get('/stats/overview', protect, restrictTo('admin'), getUserStatistics);

/**
 * GET /api/v1/users/role/:role
 * Get users by role
 */
router.get('/role/:role', protect, restrictTo('admin'), getUsersByRole);

/**
 * GET /api/v1/users/:id
 * Get user by ID
 */
router.get('/:id', protect, restrictTo('admin'), getUserById);

/**
 * PUT /api/v1/users/:id
 * Update user (role, status)
 */
router.put('/:id', protect, restrictTo('admin'), updateUser);

/**
 * DELETE /api/v1/users/:id
 * Deactivate user (soft delete)
 */
router.delete('/:id', protect, restrictTo('admin'), deactivateUser);

/**
 * POST /api/v1/users/:id/activate
 * Activate user
 */
router.post('/:id/activate', protect, restrictTo('admin'), activateUser);

export default router;
