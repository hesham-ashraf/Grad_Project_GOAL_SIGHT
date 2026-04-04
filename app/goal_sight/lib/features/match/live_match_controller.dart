import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/websocket_service.dart';
import '../../data/models/live_match_update_model.dart';
import 'live_match_state.dart';

class LiveMatchController extends StateNotifier<LiveMatchState> {
  LiveMatchController({
    required WebSocketService webSocketService,
    required String matchId,
    required String? token,
  })  : _webSocketService = webSocketService,
        _matchId = matchId,
        super(const LiveMatchState()) {
    _start(token);
  }

  final WebSocketService _webSocketService;
  final String _matchId;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Map<String, dynamic>>? _updatesSubscription;

  void _start(String? token) {
    if (token == null || token.isEmpty) return;

    _webSocketService.connect(token);
    _webSocketService.subscribeToMatch(_matchId);

    _connectionSubscription =
        _webSocketService.connectionStream.listen((isConnected) {
      state = state.copyWith(connected: isConnected);
    });

    _updatesSubscription = _webSocketService.liveUpdatesStream.listen((json) {
      final update = LiveMatchUpdateModel.fromJson(json);
      if (update.matchId != _matchId && update.matchId.isNotEmpty) return;

      final next = List<LiveMatchUpdateModel>.from(state.updates)
        ..insert(0, update);
      state = state.copyWith(updates: next);
    });
  }

  @override
  void dispose() {
    _webSocketService.unsubscribeFromMatch(_matchId);
    _connectionSubscription?.cancel();
    _updatesSubscription?.cancel();
    super.dispose();
  }
}
