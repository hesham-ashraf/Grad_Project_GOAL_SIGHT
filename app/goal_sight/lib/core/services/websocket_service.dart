import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_constants.dart';

class WebSocketService {
  io.Socket? _socket;

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<Map<String, dynamic>> _liveUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get liveUpdatesStream =>
      _liveUpdatesController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    if (isConnected) return;

    _socket = io.io(
      ApiConstants.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );

    _socket?.onConnect((_) => _connectionController.add(true));
    _socket?.onDisconnect((_) => _connectionController.add(false));
    _socket?.onReconnect((_) => _connectionController.add(true));

    _socket?.on('match:update', (data) {
      if (data is Map<String, dynamic>) {
        _liveUpdatesController.add(data);
      } else if (data is Map) {
        _liveUpdatesController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.connect();
  }

  void subscribeToMatch(String matchId) {
    _socket?.emit('match:join', {'matchId': matchId});
  }

  void unsubscribeFromMatch(String matchId) {
    _socket?.emit('match:leave', {'matchId': matchId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _connectionController.close();
    _liveUpdatesController.close();
  }
}
