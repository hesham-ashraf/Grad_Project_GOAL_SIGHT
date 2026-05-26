import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GoalSightConnectionStatus { online, offline, reconnecting }

class GoalSightGlobalAppState {
  const GoalSightGlobalAppState({
    this.connectionStatus = GoalSightConnectionStatus.online,
    this.isSyncing = false,
    this.bannerMessage,
    this.lastUpdated,
  });

  final GoalSightConnectionStatus connectionStatus;
  final bool isSyncing;
  final String? bannerMessage;
  final DateTime? lastUpdated;

  bool get isOffline => connectionStatus == GoalSightConnectionStatus.offline;

  GoalSightGlobalAppState copyWith({
    GoalSightConnectionStatus? connectionStatus,
    bool? isSyncing,
    String? bannerMessage,
    bool clearBanner = false,
    DateTime? lastUpdated,
  }) {
    return GoalSightGlobalAppState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      isSyncing: isSyncing ?? this.isSyncing,
      bannerMessage: clearBanner ? null : (bannerMessage ?? this.bannerMessage),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class GoalSightGlobalAppController
    extends StateNotifier<GoalSightGlobalAppState> {
  GoalSightGlobalAppController() : super(const GoalSightGlobalAppState());

  void setOffline({String message = 'Offline mode. Showing cached data.'}) {
    state = state.copyWith(
      connectionStatus: GoalSightConnectionStatus.offline,
      bannerMessage: message,
      lastUpdated: DateTime.now(),
    );
  }

  void setReconnecting() {
    state = state.copyWith(
      connectionStatus: GoalSightConnectionStatus.reconnecting,
      isSyncing: true,
      bannerMessage: 'Reconnecting to GOALSIGHT services...',
    );
  }

  void setOnline() {
    state = state.copyWith(
      connectionStatus: GoalSightConnectionStatus.online,
      isSyncing: false,
      clearBanner: true,
      lastUpdated: DateTime.now(),
    );
  }

  void setSyncing(bool value) {
    state = state.copyWith(isSyncing: value, lastUpdated: DateTime.now());
  }

  void showBanner(String message) {
    state = state.copyWith(bannerMessage: message);
  }

  void clearBanner() {
    state = state.copyWith(clearBanner: true);
  }
}

final goalSightGlobalAppStateProvider =
    StateNotifierProvider<GoalSightGlobalAppController, GoalSightGlobalAppState>(
  (ref) => GoalSightGlobalAppController(),
);
