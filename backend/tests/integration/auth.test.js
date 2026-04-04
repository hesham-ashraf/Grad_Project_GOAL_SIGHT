/**
 * Integration Tests for Authentication API
 * Tests registration, login, and protected routes
 */

import request from 'supertest';
import mongoose from 'mongoose';
import express from 'express';
import authRoutes from '../../src/routes/auth.routes.js';
import User from '../../src/models/User.model.js';

let app;

// Setup Express app and MongoDB
beforeAll(async () => {
  // Connect to test database
  if (mongoose.connection.readyState === 0) {
    try {
      await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/goalsight_test', {
        useNewUrlParser: true,
        useUnifiedTopology: true,
      });
    } catch (error) {
      console.log('⚠️  Skipping integration tests - MongoDB not available');
    }
  }
  
  // Create minimal Express app for testing
  app = express();
  app.use(express.json());
  app.use('/api/v1/auth', authRoutes);
});

afterAll(async () => {
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }
});

beforeEach(async () => {
  if (mongoose.connection.readyState !== 0) {
    await User.deleteMany({});
  }
});

describe('Authentication API', () => {
  const validUser = {
    username: 'testuser',
    email: 'test@example.com',
    password: 'password123',
  };

  describe('POST /api/v1/auth/register', () => {
    test('should register a new user successfully', async () => {
      const response = await request(app)
        .post('/api/v1/auth/register')
        .send(validUser)
        .expect(201);
      
      expect(response.body.status).toBe('success');
      expect(response.body.data.user).toBeDefined();
      expect(response.body.data.user.email).toBe(validUser.email);
      expect(response.body.data.user.password).toBeUndefined();
      expect(response.body.data.token).toBeDefined();
    });

    test('should fail with missing username', async () => {
      const invalidUser = {
        email: 'test@example.com',
        password: 'password123',
      };
      
      const response = await request(app)
        .post('/api/v1/auth/register')
        .send(invalidUser)
        .expect(400);
      
      expect(response.body.status).toBe('error');
    });

    test('should fail with missing email', async () => {
      const invalidUser = {
        username: 'testuser',
        password: 'password123',
      };
      
      const response = await request(app)
        .post('/api/v1/auth/register')
        .send(invalidUser)
        .expect(400);
      
      expect(response.body.status).toBe('error');
    });

    test('should fail with missing password', async () => {
      const invalidUser = {
        username: 'testuser',
        email: 'test@example.com',
      };
      
      const response = await request(app)
        .post('/api/v1/auth/register')
        .send(invalidUser)
        .expect(400);
      
      expect(response.body.status).toBe('error');
    });

    test('should fail with duplicate email', async () => {
      // Register first user
      await request(app)
        .post('/api/v1/auth/register')
        .send(validUser)
        .expect(201);
      
      // Try to register with same email
      const response = await request(app)
        .post('/api/v1/auth/register')
        .send(validUser)
        .expect(400);
      
      expect(response.body.status).toBe('error');
      expect(response.body.message).toContain('already registered');
    });

    test('should default role to fan', async () => {
      const response = await request(app)
        .post('/api/v1/auth/register')
        .send(validUser)
        .expect(201);
      
      expect(response.body.data.user.role).toBe('fan');
    });
  });

  describe('POST /api/v1/auth/login', () => {
    beforeEach(async () => {
      // Register a user before each login test
      await request(app)
        .post('/api/v1/auth/register')
        .send(validUser);
    });

    test('should login with valid credentials', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: validUser.email,
          password: validUser.password,
        })
        .expect(200);
      
      expect(response.body.status).toBe('success');
      expect(response.body.data.user).toBeDefined();
      expect(response.body.data.user.email).toBe(validUser.email);
      expect(response.body.data.token).toBeDefined();
      expect(response.body.data.user.password).toBeUndefined();
    });

    test('should fail with missing email', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({ password: validUser.password })
        .expect(400);
      
      expect(response.body.status).toBe('error');
    });

    test('should fail with missing password', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({ email: validUser.email })
        .expect(400);
      
      expect(response.body.status).toBe('error');
    });

    test('should fail with non-existent email', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'password123',
        })
        .expect(401);
      
      expect(response.body.status).toBe('error');
    });

    test('should fail with incorrect password', async () => {
      const response = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: validUser.email,
          password: 'wrongpassword',
        })
        .expect(401);
      
      expect(response.body.status).toBe('error');
      expect(response.body.message).toContain('Invalid');
    });
  });

  describe('GET /api/v1/auth/me', () => {
    let authToken;

    beforeEach(async () => {
      // Register and login to get token
      const response = await request(app)
        .post('/api/v1/auth/register')
        .send(validUser);
      
      authToken = response.body.data.token;
    });

    test('should get current user with valid token', async () => {
      const response = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);
      
      expect(response.body.status).toBe('success');
      expect(response.body.data.user).toBeDefined();
      expect(response.body.data.user.email).toBe(validUser.email);
      expect(response.body.data.user.password).toBeUndefined();
    });

    test('should fail without token', async () => {
      const response = await request(app)
        .get('/api/v1/auth/me')
        .expect(401);
      
      expect(response.body.status).toBe('error');
    });

    test('should fail with invalid token', async () => {
      const response = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', 'Bearer invalid.token.here')
        .expect(401);
      
      expect(response.body.status).toBe('error');
    });
  });
});
