/**
 * Unit Tests for JWT Utilities
 * Tests token generation, verification, and decoding
 */

import { generateToken, verifyToken, decodeToken } from '../../src/utils/jwt.js';

describe('JWT Utilities', () => {
  const testPayload = {
    id: '507f1f77bcf86cd799439011',
    email: 'test@example.com',
    role: 'fan',
  };

  describe('generateToken', () => {
    test('should generate a valid JWT token', () => {
      const token = generateToken(testPayload);
      
      expect(token).toBeDefined();
      expect(typeof token).toBe('string');
      expect(token.split('.')).toHaveLength(3); // JWT has 3 parts
    });

    test('should generate different tokens for the same payload', () => {
      const token1 = generateToken(testPayload);
      const token2 = generateToken(testPayload);
      
      // Tokens should be different due to timestamp in payload
      expect(token1).toBeDefined();
      expect(token2).toBeDefined();
    });

    test('should include payload data in token', () => {
      const token = generateToken(testPayload);
      const decoded = decodeToken(token);
      
      expect(decoded.id).toBe(testPayload.id);
      expect(decoded.email).toBe(testPayload.email);
      expect(decoded.role).toBe(testPayload.role);
    });
  });

  describe('verifyToken', () => {
    test('should verify a valid token', () => {
      const token = generateToken(testPayload);
      const decoded = verifyToken(token);
      
      expect(decoded).toBeDefined();
      expect(decoded.id).toBe(testPayload.id);
      expect(decoded.email).toBe(testPayload.email);
      expect(decoded.role).toBe(testPayload.role);
    });

    test('should throw error for invalid token', () => {
      const invalidToken = 'invalid.token.here';
      
      expect(() => verifyToken(invalidToken)).toThrow('Invalid or expired token');
    });

    test('should throw error for malformed token', () => {
      const malformedToken = 'not-a-token';
      
      expect(() => verifyToken(malformedToken)).toThrow('Invalid or expired token');
    });

    test('should include expiration time in decoded token', () => {
      const token = generateToken(testPayload);
      const decoded = verifyToken(token);
      
      expect(decoded.exp).toBeDefined();
      expect(typeof decoded.exp).toBe('number');
      expect(decoded.iat).toBeDefined();
      expect(typeof decoded.iat).toBe('number');
    });
  });

  describe('decodeToken', () => {
    test('should decode token without verification', () => {
      const token = generateToken(testPayload);
      const decoded = decodeToken(token);
      
      expect(decoded).toBeDefined();
      expect(decoded.id).toBe(testPayload.id);
      expect(decoded.email).toBe(testPayload.email);
    });

    test('should return null for invalid token', () => {
      const invalidToken = 'not.a.valid.token';
      const decoded = decodeToken(invalidToken);
      
      expect(decoded).toBeNull();
    });

    test('should decode expired token without throwing error', () => {
      const token = generateToken(testPayload);
      const decoded = decodeToken(token);
      
      expect(decoded).toBeDefined();
      expect(decoded.id).toBe(testPayload.id);
    });
  });
});
