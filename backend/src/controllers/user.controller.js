/**
 * User Controller
 * Handles user management operations (Admin only)
 */

import User from '../models/User.model.js';

/**
 * @route   GET /api/v1/users
 * @desc    Get all users with pagination
 * @access  Private (Admin only)
 */
export const getAllUsers = async (req, res) => {
  try {
    const { page = 1, limit = 10, role, isActive } = req.query;

    // Build filter
    const filter = {};
    if (role) filter.role = role;
    if (isActive !== undefined) filter.isActive = isActive === 'true';

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Execute query
    const users = await User.find(filter)
      .select('-password')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    // Get total count
    const total = await User.countDocuments(filter);

    res.status(200).json({
      status: 'success',
      results: users.length,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / parseInt(limit)),
        totalUsers: total,
        limit: parseInt(limit),
      },
      data: {
        users,
      },
    });
  } catch (error) {
    console.error('Get all users error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to retrieve users',
    });
  }
};

/**
 * @route   GET /api/v1/users/stats/overview
 * @desc    Get user statistics
 * @access  Private (Admin only)
 */
export const getUserStatistics = async (req, res) => {
  try {
    const stats = await User.getStatistics();

    res.status(200).json({
      status: 'success',
      data: {
        stats,
      },
    });
  } catch (error) {
    console.error('Get user statistics error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to retrieve user statistics',
    });
  }
};

/**
 * @route   GET /api/v1/users/role/:role
 * @desc    Get users by role
 * @access  Private (Admin only)
 */
export const getUsersByRole = async (req, res) => {
  try {
    const { role } = req.params;

    const users = await User.findByRole(role);

    res.status(200).json({
      status: 'success',
      results: users.length,
      data: {
        users,
      },
    });
  } catch (error) {
    console.error('Get users by role error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to retrieve users',
    });
  }
};

/**
 * @route   GET /api/v1/users/:id
 * @desc    Get user by ID
 * @access  Private (Admin only)
 */
export const getUserById = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findById(id).select('-password');

    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found',
      });
    }

    res.status(200).json({
      status: 'success',
      data: {
        user,
      },
    });
  } catch (error) {
    console.error('Get user by ID error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to retrieve user',
    });
  }
};

/**
 * @route   PUT /api/v1/users/:id
 * @desc    Update user (Admin)
 * @access  Private (Admin only)
 */
export const updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { role, isActive } = req.body;

    const updates = {};
    if (role) updates.role = role;
    if (isActive !== undefined) updates.isActive = isActive;

    const user = await User.findByIdAndUpdate(id, updates, {
      new: true,
      runValidators: true,
    }).select('-password');

    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found',
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'User updated successfully',
      data: {
        user,
      },
    });
  } catch (error) {
    console.error('Update user error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to update user',
    });
  }
};

/**
 * @route   DELETE /api/v1/users/:id
 * @desc    Deactivate user (soft delete)
 * @access  Private (Admin only)
 */
export const deactivateUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findByIdAndUpdate(
      id,
      { isActive: false },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found',
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'User deactivated successfully',
      data: {
        user,
      },
    });
  } catch (error) {
    console.error('Deactivate user error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to deactivate user',
    });
  }
};

/**
 * @route   POST /api/v1/users/:id/activate
 * @desc    Activate user
 * @access  Private (Admin only)
 */
export const activateUser = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findByIdAndUpdate(
      id,
      { isActive: true },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found',
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'User activated successfully',
      data: {
        user,
      },
    });
  } catch (error) {
    console.error('Activate user error:', error);

    res.status(500).json({
      status: 'error',
      message: 'Failed to activate user',
    });
  }
};

export default {
  getAllUsers,
  getUserStatistics,
  getUsersByRole,
  getUserById,
  updateUser,
  deactivateUser,
  activateUser,
};
