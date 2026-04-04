import '../../data/models/live_match_update_model.dart';

class LiveMatchState {
  const LiveMatchState({
    this.connected = false,
    this.updates = const [],
  });

  final bool connected;
  final List<LiveMatchUpdateModel> updates;

  LiveMatchState copyWith({
    bool? connected,
    List<LiveMatchUpdateModel>? updates,
  }) {
    return LiveMatchState(
      connected: connected ?? this.connected,
      updates: updates ?? this.updates,
    );
  }
}
