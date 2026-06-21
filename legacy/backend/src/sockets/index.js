/**
 * WebSocket Server
 * Handles real-time communication using Socket.IO
 * 
 * Events:
 * - connection: When a client connects
 * - disconnect: When a client disconnects
 * - match:subscribe: Subscribe to match updates
 * - match:unsubscribe: Unsubscribe from match updates
 * - match:update: Real-time match updates (score, events)
 * - match-data: Real-time match data broadcast
 * - player-update: Player statistics updates
 * - event-detected: Match events (goals, fouls, etc.)
 * - chat:message: Chat messages (future feature)
 */

// ===== MOCK DATA GENERATORS =====

/**
 * Generate mock player update data
 * @param {number} playerId - Player ID
 * @returns {Object} Player update data
 */
const generateMockPlayerUpdate = (playerId) => {
  return {
    playerId,
    speed: (Math.random() * 10).toFixed(2),
    distance: (Math.random() * 15000).toFixed(0),
    stamina: Math.floor(Math.random() * 100),
    position: {
      x: (Math.random() * 100).toFixed(2),
      y: (Math.random() * 100).toFixed(2)
    },
    heartRate: Math.floor(120 + Math.random() * 60),
    timestamp: new Date().toISOString()
  };
};

/**
 * Generate mock match data
 * @param {string} matchId - Match ID
 * @returns {Object} Match data
 */
const generateMockMatchData = (matchId) => {
  return {
    matchId,
    score: {
      home: Math.floor(Math.random() * 4),
      away: Math.floor(Math.random() * 4)
    },
    time: {
      minute: Math.floor(Math.random() * 90),
      second: Math.floor(Math.random() * 60)
    },
    possession: {
      home: Math.floor(40 + Math.random() * 20),
      away: Math.floor(40 + Math.random() * 20)
    },
    shots: {
      home: Math.floor(Math.random() * 15),
      away: Math.floor(Math.random() * 15)
    },
    timestamp: new Date().toISOString()
  };
};

/**
 * Generate mock event detected data
 * @param {string} matchId - Match ID
 * @returns {Object} Event data
 */
const generateMockEventDetected = (matchId) => {
  const eventTypes = ['goal', 'foul', 'corner', 'yellow_card', 'red_card', 'offside', 'substitution'];
  const teams = ['home', 'away'];
  
  return {
    matchId,
    eventType: eventTypes[Math.floor(Math.random() * eventTypes.length)],
    team: teams[Math.floor(Math.random() * teams.length)],
    playerId: Math.floor(Math.random() * 23) + 1,
    minute: Math.floor(Math.random() * 90),
    description: 'Event detected by AI system',
    confidence: (0.7 + Math.random() * 0.3).toFixed(2),
    timestamp: new Date().toISOString()
  };
};

/**
 * Initialize WebSocket server with Socket.IO
 * @param {Server} io - Socket.IO server instance
 */
export const initializeWebSocket = (io) => {
  // Store connected users and their subscriptions
  const connectedUsers = new Map();
  const matchSubscriptions = new Map();

  // ===== CONNECTION EVENT =====
  io.on('connection', (socket) => {
    console.log(`✅ Client connected: ${socket.id}`);

    // Store connection timestamp
    connectedUsers.set(socket.id, {
      socketId: socket.id,
      connectedAt: new Date(),
      subscriptions: []
    });

    // ===== AUTHENTICATION (Optional) =====
    /**
     * Event: authenticate
     * Client sends JWT token for authentication
     * 
     * @param {Object} data - { token: string }
     */
    socket.on('authenticate', (data) => {
      try {
        const { token } = data;
        
        // TODO: Verify JWT token and attach user info to socket
        // For now, we'll just acknowledge
        socket.emit('authenticated', {
          status: 'success',
          message: 'Authentication successful'
        });

        console.log(`🔐 Socket ${socket.id} authenticated`);
      } catch (error) {
        socket.emit('authentication_error', {
          status: 'error',
          message: 'Authentication failed'
        });
        console.error('Authentication error:', error);
      }
    });

    // ===== MATCH SUBSCRIPTION =====
    /**
     * Event: match:subscribe
     * Subscribe to real-time updates for a specific match
     * 
     * @param {Object} data - { matchId: string }
     */
    socket.on('match:subscribe', (data) => {
      try {
        const { matchId } = data;

        if (!matchId) {
          socket.emit('error', {
            message: 'Match ID is required'
          });
          return;
        }

        // Join the match room
        socket.join(`match:${matchId}`);

        // Track subscription
        const user = connectedUsers.get(socket.id);
        if (user) {
          user.subscriptions.push(matchId);
        }

        // Track match subscribers
        if (!matchSubscriptions.has(matchId)) {
          matchSubscriptions.set(matchId, new Set());
        }
        matchSubscriptions.get(matchId).add(socket.id);

        // Send confirmation
        socket.emit('match:subscribed', {
          status: 'success',
          matchId,
          message: `Subscribed to match ${matchId}`
        });

        console.log(`📡 Socket ${socket.id} subscribed to match ${matchId}`);
      } catch (error) {
        console.error('Match subscribe error:', error);
        socket.emit('error', {
          message: 'Failed to subscribe to match'
        });
      }
    });

    /**
     * Event: match:unsubscribe
     * Unsubscribe from match updates
     * 
     * @param {Object} data - { matchId: string }
     */
    socket.on('match:unsubscribe', (data) => {
      try {
        const { matchId } = data;

        if (!matchId) {
          socket.emit('error', {
            message: 'Match ID is required'
          });
          return;
        }

        // Leave the match room
        socket.leave(`match:${matchId}`);

        // Remove from tracking
        const user = connectedUsers.get(socket.id);
        if (user) {
          user.subscriptions = user.subscriptions.filter(id => id !== matchId);
        }

        if (matchSubscriptions.has(matchId)) {
          matchSubscriptions.get(matchId).delete(socket.id);
          
          // Clean up empty subscriptions
          if (matchSubscriptions.get(matchId).size === 0) {
            matchSubscriptions.delete(matchId);
          }
        }

        // Send confirmation
        socket.emit('match:unsubscribed', {
          status: 'success',
          matchId,
          message: `Unsubscribed from match ${matchId}`
        });

        console.log(`📡 Socket ${socket.id} unsubscribed from match ${matchId}`);
      } catch (error) {
        console.error('Match unsubscribe error:', error);
      }
    });

    // ===== REAL-TIME DATA EVENTS =====
    /**
     * Event: match-data
     * Request real-time match data
     * 
     * @param {Object} data - { matchId: string }
     */
    socket.on('match-data', (data) => {
      try {
        const { matchId } = data;
        
        if (!matchId) {
          socket.emit('error', { message: 'Match ID is required' });
          return;
        }

        // Send mock match data
        const matchData = generateMockMatchData(matchId);
        socket.emit('match-data', matchData);

        console.log(`📊 Sent match data for match ${matchId}`);
      } catch (error) {
        console.error('Match data error:', error);
        socket.emit('error', { message: 'Failed to fetch match data' });
      }
    });

    /**
     * Event: player-update
     * Request player statistics update
     * 
     * @param {Object} data - { playerId: number, matchId?: string }
     */
    socket.on('player-update', (data) => {
      try {
        const { playerId, matchId } = data;
        
        if (!playerId) {
          socket.emit('error', { message: 'Player ID is required' });
          return;
        }

        // Send mock player update
        const playerData = generateMockPlayerUpdate(playerId);
        socket.emit('player-update', {
          ...playerData,
          matchId: matchId || null
        });

        console.log(`👤 Sent player update for player ${playerId}`);
      } catch (error) {
        console.error('Player update error:', error);
        socket.emit('error', { message: 'Failed to fetch player update' });
      }
    });

    /**
     * Event: event-detected
     * Request or acknowledge event detection
     * 
     * @param {Object} data - { matchId: string }
     */
    socket.on('event-detected', (data) => {
      try {
        const { matchId } = data;
        
        if (!matchId) {
          socket.emit('error', { message: 'Match ID is required' });
          return;
        }

        // Send mock event detected
        const eventData = generateMockEventDetected(matchId);
        socket.emit('event-detected', eventData);

        console.log(`🎯 Sent event detected for match ${matchId}: ${eventData.eventType}`);
      } catch (error) {
        console.error('Event detected error:', error);
        socket.emit('error', { message: 'Failed to process event' });
      }
    });

    // ===== CHAT EVENTS (Placeholder for future) =====
    /**
     * Event: chat:join
     * Join a chat room
     * 
     * @param {Object} data - { roomId: string }
     */
    socket.on('chat:join', (data) => {
      const { roomId } = data;
      socket.join(`chat:${roomId}`);
      
      socket.emit('chat:joined', {
        status: 'success',
        roomId
      });

      console.log(`💬 Socket ${socket.id} joined chat room ${roomId}`);
    });

    /**
     * Event: chat:message
     * Send a message to a chat room
     * 
     * @param {Object} data - { roomId: string, message: string }
     */
    socket.on('chat:message', (data) => {
      const { roomId, message } = data;
      
      // Broadcast message to all users in the room
      io.to(`chat:${roomId}`).emit('chat:message', {
        socketId: socket.id,
        message,
        timestamp: new Date()
      });

      console.log(`💬 Message in room ${roomId}: ${message}`);
    });

    // ===== PING/PONG FOR CONNECTION HEALTH =====
    /**
     * Event: ping
     * Client sends ping, server responds with pong
     */
    socket.on('ping', () => {
      socket.emit('pong', {
        timestamp: new Date()
      });
    });

    // ===== DISCONNECT EVENT =====
    socket.on('disconnect', (reason) => {
      console.log(`❌ Client disconnected: ${socket.id} (${reason})`);

      // Clean up subscriptions
      const user = connectedUsers.get(socket.id);
      if (user && user.subscriptions) {
        user.subscriptions.forEach(matchId => {
          if (matchSubscriptions.has(matchId)) {
            matchSubscriptions.get(matchId).delete(socket.id);
            
            // Clean up empty subscriptions
            if (matchSubscriptions.get(matchId).size === 0) {
              matchSubscriptions.delete(matchId);
            }
          }
        });
      }

      // Remove from connected users
      connectedUsers.delete(socket.id);
    });

    // ===== ERROR HANDLING =====
    socket.on('error', (error) => {
      console.error(`❌ Socket error (${socket.id}):`, error);
    });
  });

  // ===== SERVER-SIDE BROADCAST FUNCTIONS =====

  /**
   * Broadcast match update to all subscribers
   * Can be called from controllers when match data changes
   * 
   * @param {string} matchId - Match ID
   * @param {Object} update - Update data
   */
  io.broadcastMatchUpdate = (matchId, update) => {
    io.to(`match:${matchId}`).emit('match:update', {
      matchId,
      update,
      timestamp: new Date()
    });

    console.log(`📢 Broadcasting update for match ${matchId}`);
  };

  /**
   * Broadcast score update
   * 
   * @param {string} matchId - Match ID
   * @param {Object} scores - { home: number, away: number }
   */
  io.broadcastScoreUpdate = (matchId, scores) => {
    io.to(`match:${matchId}`).emit('match:score_update', {
      matchId,
      scores,
      timestamp: new Date()
    });

    console.log(`⚽ Broadcasting score update for match ${matchId}:`, scores);
  };

  /**
   * Broadcast match event (goal, card, etc.)
   * 
   * @param {string} matchId - Match ID
   * @param {Object} event - Event data
   */
  io.broadcastMatchEvent = (matchId, event) => {
    io.to(`match:${matchId}`).emit('match:event', {
      matchId,
      event,
      timestamp: new Date()
    });

    console.log(`🎯 Broadcasting event for match ${matchId}:`, event);
  };

  /**
   * Broadcast match data (real-time match statistics)
   * 
   * @param {string} matchId - Match ID
   * @param {Object} data - Match data (optional, will generate mock if not provided)
   */
  io.broadcastMatchData = (matchId, data = null) => {
    const matchData = data || generateMockMatchData(matchId);
    
    io.to(`match:${matchId}`).emit('match-data', matchData);

    console.log(`📊 Broadcasting match data for match ${matchId}`);
  };

  /**
   * Broadcast player update (player statistics)
   * 
   * @param {string} matchId - Match ID
   * @param {number} playerId - Player ID
   * @param {Object} data - Player data (optional, will generate mock if not provided)
   */
  io.broadcastPlayerUpdate = (matchId, playerId, data = null) => {
    const playerData = data || generateMockPlayerUpdate(playerId);
    
    io.to(`match:${matchId}`).emit('player-update', {
      ...playerData,
      matchId
    });

    console.log(`👤 Broadcasting player update for player ${playerId} in match ${matchId}`);
  };

  /**
   * Broadcast event detected (AI-detected match events)
   * 
   * @param {string} matchId - Match ID
   * @param {Object} eventData - Event data (optional, will generate mock if not provided)
   */
  io.broadcastEventDetected = (matchId, eventData = null) => {
    const event = eventData || generateMockEventDetected(matchId);
    
    io.to(`match:${matchId}`).emit('event-detected', event);

    console.log(`🎯 Broadcasting event detected for match ${matchId}: ${event.eventType}`);
  };

  /**
   * Start mock data simulation for a match (for testing purposes)
   * Broadcasts random updates every few seconds
   * 
   * @param {string} matchId - Match ID
   * @param {number} intervalMs - Interval in milliseconds (default: 3000)
   * @returns {NodeJS.Timeout} - Interval ID (can be used to stop simulation)
   */
  io.startMockDataSimulation = (matchId, intervalMs = 3000) => {
    console.log(`🎮 Starting mock data simulation for match ${matchId}`);
    
    const interval = setInterval(() => {
      // Randomly send different types of updates
      const randomEvent = Math.random();
      
      if (randomEvent < 0.4) {
        // 40% chance: match data update
        io.broadcastMatchData(matchId);
      } else if (randomEvent < 0.7) {
        // 30% chance: player update
        const randomPlayerId = Math.floor(Math.random() * 22) + 1;
        io.broadcastPlayerUpdate(matchId, randomPlayerId);
      } else {
        // 30% chance: event detected
        io.broadcastEventDetected(matchId);
      }
    }, intervalMs);
    
    return interval;
  };

  /**
   * Get connection statistics
   * 
   * @returns {Object} - Connection stats
   */
  io.getStats = () => {
    return {
      connectedClients: connectedUsers.size,
      activeMatches: matchSubscriptions.size,
      subscriptions: Array.from(matchSubscriptions.entries()).map(([matchId, sockets]) => ({
        matchId,
        subscribers: sockets.size
      }))
    };
  };

  console.log('✅ WebSocket server initialized');
  console.log('📡 Listening for connections...\n');
};

export default initializeWebSocket;
