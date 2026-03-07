/**
 * User Model
 * Defines the schema and methods for User collection
 */

import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema(
  {
    username: {
      type: String,
      required: [true, 'Username is required'],
      trim: true,
      minlength: [3, 'Username must be at least 3 characters'],
      maxlength: [50, 'Username cannot exceed 50 characters'],
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [
        /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
        'Please provide a valid email address',
      ],
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [6, 'Password must be at least 6 characters'],
      select: false, // Don't return password by default
    },
    role: {
      type: String,
      enum: ['fan', 'manager', 'admin'],
      default: 'fan',
    },
    favoriteTeam: {
      type: String,
      default: null,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastLogin: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true, // Adds createdAt and updatedAt
  }
);

// ===== INDEXES =====
userSchema.index({ email: 1 });
userSchema.index({ role: 1 });

// ===== MIDDLEWARE =====

/**
 * Hash password before saving
 */
userSchema.pre('save', async function (next) {
  // Only hash if password is modified
  if (!this.isModified('password')) {
    return next();
  }

  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// ===== INSTANCE METHODS =====

/**
 * Compare provided password with hashed password
 * @param {string} candidatePassword - Password to compare
 * @returns {Promise<boolean>} - True if passwords match
 */
userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

/**
 * Get user data without sensitive information
 * @returns {Object} - User object without password
 */
userSchema.methods.toSafeObject = function () {
  const user = this.toObject();
  delete user.password;
  return user;
};

// ===== STATIC METHODS =====

/**
 * Find user by email
 * @param {string} email - User email
 * @returns {Promise<Object|null>} - User object or null
 */
userSchema.statics.findByEmail = function (email) {
  return this.findOne({ email: email.toLowerCase() });
};

/**
 * Find active users by role
 * @param {string} role - User role (fan, manager, admin)
 * @returns {Promise<Array>} - Array of users
 */
userSchema.statics.findByRole = function (role) {
  return this.find({ role, isActive: true });
};

/**
 * Get user statistics
 * @returns {Promise<Object>} - User stats
 */
userSchema.statics.getStatistics = async function () {
  const stats = await this.aggregate([
    {
      $group: {
        _id: '$role',
        count: { $sum: 1 },
      },
    },
  ]);

  const total = await this.countDocuments();
  const active = await this.countDocuments({ isActive: true });
  const inactive = total - active;

  return {
    total,
    active,
    inactive,
    byRole: stats.reduce((acc, stat) => {
      acc[stat._id] = stat.count;
      return acc;
    }, {}),
  };
};

const User = mongoose.model('User', userSchema);

export default User;
