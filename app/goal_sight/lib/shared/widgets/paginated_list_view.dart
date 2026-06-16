// ---------------------------------------------------------------------------
// GoalSight — Reusable Paginated List / Grid
//
// Infinite-scroll list or grid driven by a [PaginatedState]. Triggers
// [onLoadMore] near the end, renders a bottom loader / end-of-list / inline
// error footer, and supports pull-to-refresh. Pass [gridDelegate] for a grid.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/paginated_notifier.dart';
import 'app_error_view.dart';

class PaginatedListView<T> extends StatefulWidget {
  const PaginatedListView({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.onRefresh,
    this.gridDelegate,
    this.padding = EdgeInsets.zero,
    this.physics,
    this.emptyBuilder,
    this.loadingBuilder,
  });

  final PaginatedState<T> state;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;
  final SliverGridDelegate? gridDelegate;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? loadingBuilder;

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    // First-page loading.
    if (state.status == PaginatedStatus.loading && state.items.isEmpty) {
      return widget.loadingBuilder?.call(context) ??
          const Center(
            child: CircularProgressIndicator(
              color: AppColors.accentCyan,
              strokeWidth: 2.5,
            ),
          );
    }

    // First-page error.
    if (state.status == PaginatedStatus.error && state.items.isEmpty) {
      return AppErrorView(error: state.error!, onRetry: widget.onRefresh);
    }

    // Loaded-but-empty.
    if (state.items.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          Center(
            child: Text('Nothing here yet.',
                style: AppTextStyles.body(color: AppColors.textMuted)),
          );
    }

    final Widget content;
    if (widget.gridDelegate != null) {
      // Grid: render the footer beneath the grid via a CustomScrollView.
      content = _GridWithFooter<T>(
        controller: _scrollController,
        padding: widget.padding,
        physics: widget.physics,
        gridDelegate: widget.gridDelegate!,
        state: state,
        itemBuilder: widget.itemBuilder,
        onRetry: widget.onLoadMore,
      );
    } else {
      // List: footer is one extra trailing cell.
      content = ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        physics: widget.physics ??
            const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: state.items.length + 1,
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return _Footer<T>(state: state, onRetry: widget.onLoadMore);
          }
          return widget.itemBuilder(context, state.items[index], index);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.accentCyan,
      backgroundColor: AppColors.surface,
      strokeWidth: 2.5,
      child: content,
    );
  }
}

class _GridWithFooter<T> extends StatelessWidget {
  const _GridWithFooter({
    required this.controller,
    required this.padding,
    required this.physics,
    required this.gridDelegate,
    required this.state,
    required this.itemBuilder,
    required this.onRetry,
  });

  final ScrollController controller;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final SliverGridDelegate gridDelegate;
  final PaginatedState<T> state;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: physics ??
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverGrid(
            gridDelegate: gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (context, index) => itemBuilder(context, state.items[index], index),
              childCount: state.items.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: _Footer(state: state, onRetry: onRetry)),
      ],
    );
  }
}

class _Footer<T> extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final PaginatedState<T> state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: AppColors.accentCyan,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: AppErrorView(
          error: state.error!,
          onRetry: onRetry,
          compact: true,
        ),
      );
    }

    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            "You've reached the end",
            style: AppTextStyles.caption(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}
