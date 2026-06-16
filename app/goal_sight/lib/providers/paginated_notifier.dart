// ---------------------------------------------------------------------------
// GoalSight — Generic Pagination Notifier
//
// Reusable infinite-scroll controller backed by any repository `*Paged`
// method. Tracks loaded items, first-page loading, load-more, end-of-list,
// and error state with retry/refresh support.
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef PageFetcher<T> = Future<List<T>> Function(int page, int pageSize);

enum PaginatedStatus { loading, loaded, error }

class PaginatedState<T> {
  const PaginatedState({
    this.items = const [],
    this.status = PaginatedStatus.loading,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<T> items;
  final PaginatedStatus status;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  bool get isEmpty => items.isEmpty;

  PaginatedState<T> copyWith({
    List<T>? items,
    PaginatedStatus? status,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      status: status ?? this.status,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  PaginatedNotifier(this._fetch, {this.pageSize = 20})
      : super(PaginatedState<T>()) {
    loadInitial();
  }

  final PageFetcher<T> _fetch;
  final int pageSize;
  int _nextPage = 0;

  Future<void> loadInitial() async {
    state = PaginatedState<T>(status: PaginatedStatus.loading);
    _nextPage = 0;
    try {
      final page = await _fetch(0, pageSize);
      _nextPage = 1;
      state = PaginatedState<T>(
        items: page,
        status: PaginatedStatus.loaded,
        hasMore: page.length >= pageSize,
      );
    } catch (e) {
      state = PaginatedState<T>(status: PaginatedStatus.error, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.status != PaginatedStatus.loaded) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _fetch(_nextPage, pageSize);
      _nextPage += 1;
      state = state.copyWith(
        items: [...state.items, ...page],
        isLoadingMore: false,
        hasMore: page.length >= pageSize,
      );
    } catch (e) {
      // Keep existing items; surface the error so the footer can offer retry.
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> refresh() => loadInitial();
}
