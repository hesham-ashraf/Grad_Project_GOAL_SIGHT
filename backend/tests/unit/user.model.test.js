/**
 * Unit Tests for User Model
 * Tests password hashing, validation, and model methods
 */

import mongoose from 'mongoose';
import User from '../../src/models/User.model.js';
import bcrypt from 'bcryptjs';

// Mock MongoDB connection for unit tests
beforeAll(async () => {
  // Skip if already connected or connecting
  if (mongoose.connection.readyState === 0) {
    try {
      await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/goalsight_test', {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });
    } catch (error) {
      console.log('⚠️  Skipping database-dependent tests - MongoDB not available');
    }
  }
});

// Cleanup after all tests
afterAll(async () => {
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }
});

// Clear database before each test
beforeEach(async () => {
  if (mongoose.connection.readyState !== 0) {
    await User.deleteMany({});
  }
});

describe('User Model', () => {
  const validUserData = {
    username: 'testuser',
    email: 'test@example.com',
    password: 'password123',
    role: 'fan',
  };

  describe('User Creation', () => {
    test('should create a user with valid data', async () => {
      const user = await User.create(validUserData);
      
      expect(user._id).toBeDefined();
      expect(user.username).toBe(validUserData.username);
      expect(user.email).toBe(validUserData.email);
      expect(user.role).toBe(validUserData.role);
      expect(user.isActive).toBe(true);
      expect(user.createdAt).toBeDefined();
      expect(user.updatedAt).toBeDefined();
    });

    test('should hash password before saving', async () => {
      const user = await User.create(validUserData);
      
      expect(user.password).toBeDefined();
      expect(user.password).not.toBe(validUserData.password);
      expect(user.password.length).toBeGreaterThan(20); // Hashed password is longer
    });

    test('should set default role to fan', async () => {
      const userWithoutRole = {
        username: 'testuser2',
        email: 'test2@example.com',
        password: 'password123',
      };
      
      const user = await User.create(userWithoutRole);
      expect(user.role).toBe('fan');
    });

    test('should fail without required username', async () => {
      const invalidUser = {
        email: 'test@example.com',
        password: 'password123',
      };
      
      await expect(User.create(invalidUser)).rejects.toThrow();
    });

    test('should fail without required email', async () => {
      const invalidUser = {
        username: 'testuser',
        password: 'password123',
      };
      
      await expect(User.create(invalidUser)).rejects.toThrow();
    });

    test('should fail without required password', async () => {
      const invalidUser = {
        username: 'testuser',
        email: 'test@example.com',
      };
      
      await expect(User.create(invalidUser)).rejects.toThrow();
    });

    test('should fail with invalid email format', async () => {
      const invalidUser = {
        ...validUserData,
        email: 'invalid-email',
      };
      
      await expect(User.create(invalidUser)).rejects.toThrow();
    });

    test('should fail with duplicate email', async () => {
      await User.create(validUserData);
      
      const duplicateUser = {
        username: 'testuser2',
        email: validUserData.email,
        password: 'password123',
      };
      
      await expect(User.create(duplicateUser)).rejects.toThrow();
    });

    test('should fail with username less than 3 characters', async () => {
      const invalidUser = {
        ...validUserData,
        username: 'ab',
      };
      
      await expect(User.create(invalidUser)).rejects.toThrow();
    });

    test('should fail with password less than 6 characters', async () => {
      const invalidUser = {
        ...validUserData,
        password: '12345',
      };
      
      await expect(User.create(invalidUser)).rejects.toThrow();
    });

    test('should accept valid roles', async () => {
      const roles = ['fan', 'manager', 'admin'];
      
      for (const role of roles) {
        const user = await User.create({
          username: `testuser_${role}`,
          email: `test_${role}@example.com`,
          password: 'password123',
          role,
        });
        
        expect(user.role).toBe(role);
      }
    });
  });

  describe('Password Comparison', () => {
    test('should correctly compare valid password', async () => {
      const user = await User.create(validUserData);
      
      // Fetch user with password (it's excluded by default with select: false)
      const userWithPassword = await User.findById(user._id).select('+password');
      const isMatch = await userWithPassword.comparePassword(validUserData.password);
      
      expect(isMatch).toBe(true);
    });

    test('should reject invalid password', async () => {
      const user = await User.create(validUserData);
      
      const userWithPassword = await User.findById(user._id).select('+password');
      const isMatch = await userWithPassword.comparePassword('wrongpassword');
      
      expect(isMatch).toBe(false);
    });
  });

  describe('toSafeObject Method', () => {
    test('should return user object without password', async () => {
      const user = await User.create(validUserData);
      const safeUser = user.toSafeObject();
      
      expect(safeUser.password).toBeUndefined();
      expect(safeUser.username).toBe(validUserData.username);
      expect(safeUser.email).toBe(validUserData.email);
      expect(safeUser.role).toBe(validUserData.role);
    });
  });

  describe('findByEmail Static Method', () => {
    test('should find user by email', async () => {
      await User.create(validUserData);
      
      const foundUser = await User.findByEmail(validUserData.email);
      
      expect(foundUser).toBeDefined();
      expect(foundUser.email).toBe(validUserData.email);
      expect(foundUser.username).toBe(validUserData.username);
    });

    test('should return null for non-existent email', async () => {
      const foundUser = await User.findByEmail('nonexistent@example.com');
      
      expect(foundUser).toBeNull();
    });

    test('should be case-insensitive', async () => {
      await User.create(validUserData);
      
      const foundUser = await User.findByEmail(validUserData.email.toUpperCase());
      
      expect(foundUser).toBeDefined();
      expect(foundUser.email).toBe(validUserData.email);
    });
  });

  describe('getStatistics Static Method', () => {
    test('should return user count by role', async () => {
      await User.create({ ...validUserData, username: 'fan1', email: 'fan1@test.com', role: 'fan' });
      await User.create({ ...validUserData, username: 'fan2', email: 'fan2@test.com', role: 'fan' });
      await User.create({ ...validUserData, username: 'admin1', email: 'admin1@test.com', role: 'admin' });
      
      const stats = await User.getStatistics();
      
      expect(stats.total).toBe(3);
      expect(stats.byRole.fan).toBe(2);
      expect(stats.byRole.admin).toBe(1);
      // Manager count might be 0 or undefined if no managers exist
      expect(stats.byRole.manager || 0).toBe(0);
    });
  });
});
