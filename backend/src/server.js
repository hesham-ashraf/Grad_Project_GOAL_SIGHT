/**
 * Goal Sight Backend Server
 * Main entry point for the application
 * 
 * Architecture:
 * - Express.js for RESTful API
 * - Socket.IO for real-time WebSocket communication
 * - MongoDB with Mongoose for data persistence
 * - JWT for authentication
 */

import express from 'express';
import http from 'http';
import { Server } from 'socket.io';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Import configuration
import { connectDB } from './config/database.js';

// Import routes
import authRoutes from './routes/auth.routes.js';
import userRoutes from './routes/user.routes.js';
import matchRoutes from './routes/match.routes.js';
import liveRoutes from './routes/liveRoutes.js';

// Import WebSocket handler
import { initializeWebSocket } from './sockets/index.js';

// Import match controller to set IO instance
import { setIO } from './controllers/match.controller.js';

// Get current file's directory
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load environment variables
dotenv.config({ path: join(__dirname, '..', '.env') });

// ===== CREATE EXPRESS APP =====
const app = express();

// ===== CREATE HTTP SERVER =====
// We need HTTP server to attach Socket.IO
const server = http.createServer(app);

// ===== INITIALIZE SOCKET.IO =====
const io = new Server(server, {
  cors: {
    origin: process.env.CLIENT_URL || 'http://localhost:5174',
    methods: ['GET', 'POST'],
    credentials: true
  },
  pingInterval: parseInt(process.env.WS_PING_INTERVAL) || 25000,
  pingTimeout: parseInt(process.env.WS_PING_TIMEOUT) || 10000,
});

// ===== MIDDLEWARE =====

// Security headers with Helmet
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: process.env.CLIENT_URL || 'http://localhost:5174',
  credentials: true
}));

// Body parsing middleware
app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies

// HTTP request logger (only in development)
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// ===== API ROUTES =====

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Goal Sight API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV
  });
});

// API v1 routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/matches', matchRoutes);

// Live scores route (existing functionality)
app.use('/api', liveRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'GOALSIGHT API is running',
    version: '1.0.0',
  });
});

// 404 handler for undefined routes
app.use('*', (req, res) => {
  res.status(404).json({
    status: 'error',
    message: `Cannot find ${req.originalUrl} on this server`
  });
});

// ===== GLOBAL ERROR HANDLER =====
app.use((err, req, res, next) => {
  console.error('❌ Error:', err);
  
  res.status(err.status || 500).json({
    status: 'error',
    message: err.message || 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.stack : undefined,
  });
});

// ===== INITIALIZE WEBSOCKET =====
initializeWebSocket(io);

// Set IO instance in match controller
setIO(io);

// ===== START SERVER =====
const PORT = process.env.PORT || 5000;

/**
 * Start the server and connect to database
 */
const startServer = async () => {
  try {
    // Connect to MongoDB
    await connectDB();
    
    // Start listening on the specified port
    server.listen(PORT, () => {
      console.log('\n🚀 ===== GOAL SIGHT SERVER STARTED =====');
      console.log(`📡 Server running on port: ${PORT}`);
      console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🔗 API URL: http://localhost:${PORT}/api/v1`);
      console.log(`⚡ WebSocket URL: ws://localhost:${PORT}`);
      console.log(`🔑 SportMonks API: ${process.env.SPORTMONKS_API_KEY ? 'Configured ✓' : 'Not configured ✗'}`);
      console.log('=====================================\n');
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
};

// ===== GRACEFUL SHUTDOWN =====

/**
 * Handle graceful shutdown on SIGTERM signal
 */
process.on('SIGTERM', () => {
  console.log('\n⚠️  SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('🔴 HTTP server closed');
    process.exit(0);
  });
});

/**
 * Handle graceful shutdown on SIGINT signal (Ctrl+C)
 */
process.on('SIGINT', () => {
  console.log('\n⚠️  SIGINT signal received: closing HTTP server');
  server.close(() => {
    console.log('🔴 HTTP server closed');
    process.exit(0);
  });
});

/**
 * Handle uncaught exceptions
 */
process.on('uncaughtException', (err) => {
  console.error('❌ UNCAUGHT EXCEPTION! 💥 Shutting down...');
  console.error(err.name, err.message);
  process.exit(1);
});

/**
 * Handle unhandled promise rejections
 */
process.on('unhandledRejection', (err) => {
  console.error('❌ UNHANDLED REJECTION! 💥 Shutting down...');
  console.error(err.name, err.message);
  server.close(() => {
    process.exit(1);
  });
});

// Start the server
startServer();

// Export for testing purposes
export { app, server, io };
export default app;