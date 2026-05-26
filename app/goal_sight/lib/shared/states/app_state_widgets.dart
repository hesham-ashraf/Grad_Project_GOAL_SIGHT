import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../components/glass_container.dart';
import 'global_app_state.dart';

class GoalSightSkeleton extends StatelessWidget {
  const GoalSightSkeleton({
    super.key,
    this.width,
    this.height = 18,
    this.radius = 12,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceRaised.withValues(alpha: 0.7),
      highlightColor: AppColors.textMuted.withValues(alpha: 0.12),
      child: Container(
        width: width,
        height: context.rs(height, min: 8, max: height + 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class GoalSightCardSkeleton extends StatelessWidget {
  const GoalSightCardSkeleton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GoalSightGlass(
      opacity: 0.72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GoalSightSkeleton(width: context.rs(40, min: 34, max: 44), height: 40, radius: 16),
              SizedBox(width: context.rs(12, min: 8, max: 14)),
              Expanded(child: GoalSightSkeleton(height: compact ? 14 : 18)),
            ],
          ),
          SizedBox(height: context.rs(16, min: 12, max: 20)),
          GoalSightSkeleton(width: context.rs(150, min: 110, max: 190), height: compact ? 22 : 30),
          SizedBox(height: context.rs(10, min: 8, max: 12)),
          const GoalSightSkeleton(height: 12),
          if (!compact) ...[
            SizedBox(height: context.rs(8, min: 6, max: 10)),
            GoalSightSkeleton(width: context.rs(220, min: 150, max: 280), height: 12),
          ],
        ],
      ),
    );
  }
}

class GoalSightListSkeleton extends StatelessWidget {
  const GoalSightListSkeleton({
    super.key,
    this.itemCount = 4,
    this.compact = false,
  });

  final int itemCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: context.rs(12, min: 8, max: 14)),
          child: GoalSightCardSkeleton(compact: compact),
        ),
      ),
    );
  }
}

class GoalSightChartSkeleton extends StatelessWidget {
  const GoalSightChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GoalSightGlass(
      opacity: 0.45,
      shadow: GoalSightGlassShadow.none,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(8, (index) {
                final height = 34.0 + ((index * 19) % 86);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GoalSightSkeleton(height: height, radius: 10),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: context.rs(14, min: 10, max: 18)),
          const GoalSightSkeleton(height: 12),
        ],
      ),
    );
  }
}

class GoalSightEmptyState extends StatelessWidget {
  const GoalSightEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _StateShell(
      icon: icon,
      title: title,
      message: message,
      tint: AppColors.accentCyan,
      actionLabel: actionLabel,
      onAction: onAction,
      compact: compact,
    );
  }
}

class GoalSightErrorState extends StatelessWidget {
  const GoalSightErrorState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.retryLabel = 'Retry',
    this.onRetry,
    this.compact = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final String retryLabel;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _StateShell(
      icon: icon,
      title: title,
      message: message,
      tint: AppColors.danger,
      actionLabel: onRetry == null ? null : retryLabel,
      onAction: onRetry,
      compact: compact,
      pulse: true,
    );
  }
}

class GoalSightRetryState extends StatefulWidget {
  const GoalSightRetryState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String title;
  final String message;
  final Future<void> Function() onRetry;
  final String retryLabel;

  @override
  State<GoalSightRetryState> createState() => _GoalSightRetryStateState();
}

class _GoalSightRetryStateState extends State<GoalSightRetryState> {
  bool _loading = false;

  Future<void> _retry() async {
    setState(() => _loading = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StateShell(
      icon: Icons.refresh_rounded,
      title: widget.title,
      message: widget.message,
      tint: AppColors.warning,
      actionLabel: _loading ? 'Retrying...' : widget.retryLabel,
      onAction: _loading ? null : _retry,
      loadingAction: _loading,
    );
  }
}

class GoalSightOfflineBanner extends StatelessWidget {
  const GoalSightOfflineBanner({
    super.key,
    this.message = 'Offline mode. Cached analytics are available.',
    this.isReconnecting = false,
    this.onRetry,
  });

  final String message;
  final bool isReconnecting;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tint = isReconnecting ? AppColors.warning : AppColors.accentCyan;

    return GoalSightGlass(
      opacity: 0.9,
      blur: 12,
      borderColor: tint.withValues(alpha: 0.26),
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(14, min: 12, max: 18),
        vertical: context.rs(10, min: 8, max: 12),
      ),
      child: Row(
        children: [
          if (isReconnecting)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: tint),
            )
          else
            Icon(Icons.wifi_off_rounded, color: tint, size: 18),
          SizedBox(width: context.rs(10, min: 8, max: 12)),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption(color: AppColors.textSecondary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Reconnect'),
            ),
        ],
      ),
    );
  }
}

class GoalSightAppStateOverlay extends ConsumerWidget {
  const GoalSightAppStateOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(goalSightGlobalAppStateProvider);
    final showBanner = appState.bannerMessage != null || appState.isOffline;
    final isReconnecting =
        appState.connectionStatus == GoalSightConnectionStatus.reconnecting;

    return Stack(
      children: [
        child,
        Positioned(
          left: context.rs(14, min: 12, max: 22),
          right: context.rs(14, min: 12, max: 22),
          top: MediaQuery.paddingOf(context).top + context.rs(10, min: 8, max: 14),
          child: IgnorePointer(
            ignoring: !showBanner,
            child: AnimatedSlide(
              offset: showBanner ? Offset.zero : const Offset(0, -1.25),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: showBanner ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: GoalSightOfflineBanner(
                  message: appState.bannerMessage ??
                      'Offline mode. Cached analytics are available.',
                  isReconnecting: isReconnecting,
                  onRetry: () => ref
                      .read(goalSightGlobalAppStateProvider.notifier)
                      .setReconnecting(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StateShell extends StatelessWidget {
  const _StateShell({
    required this.icon,
    required this.title,
    required this.message,
    required this.tint,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.pulse = false,
    this.loadingAction = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color tint;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;
  final bool pulse;
  final bool loadingAction;

  @override
  Widget build(BuildContext context) {
    return GoalSightGlass(
      opacity: 0.78,
      borderColor: tint.withValues(alpha: 0.2),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 360 : 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedStateIcon(icon: icon, tint: tint, pulse: pulse),
              SizedBox(height: context.rs(compact ? 10 : 14, min: 8, max: 18)),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.title(color: AppColors.textPrimary).copyWith(
                  fontSize: context.sp(compact ? 16 : 18, min: 14, max: 22),
                ),
              ),
              SizedBox(height: context.rs(6, min: 4, max: 8)),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(
                  fontSize: context.sp(compact ? 12 : 13, min: 11, max: 15),
                ),
              ),
              if (actionLabel != null) ...[
                SizedBox(height: context.rs(16, min: 12, max: 20)),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: loadingAction
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedStateIcon extends StatefulWidget {
  const _AnimatedStateIcon({
    required this.icon,
    required this.tint,
    required this.pulse,
  });

  final IconData icon;
  final Color tint;
  final bool pulse;

  @override
  State<_AnimatedStateIcon> createState() => _AnimatedStateIconState();
}

class _AnimatedStateIconState extends State<_AnimatedStateIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.pulse) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: context.rs(58, min: 48, max: 68),
          height: context.rs(58, min: 48, max: 68),
          decoration: BoxDecoration(
            color: widget.tint.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: widget.tint.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: widget.tint.withValues(
                  alpha: widget.pulse ? 0.1 + _controller.value * 0.14 : 0.08,
                ),
                blurRadius: 24,
              ),
            ],
          ),
          child: Icon(widget.icon, color: widget.tint, size: context.rs(28, min: 24, max: 32)),
        );
      },
    );
  }
}
