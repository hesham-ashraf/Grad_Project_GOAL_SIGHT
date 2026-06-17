// ---------------------------------------------------------------------------
// GoalSight — Admin Notifications Page
//
// Shows all club-scoped notifications for the signed-in admin.
// Supports mark-as-read on tap and mark-all-read in the app bar.
// Uses Riverpod Realtime stream so new notifications arrive live.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/notification_model.dart';
import '../../../providers/repository_providers.dart';
import '../../../shared/animations/gs_shimmer.dart';

class AdminNotificationsPage extends ConsumerStatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  ConsumerState<AdminNotificationsPage> createState() =>
      _AdminNotificationsPageState();
}

class _AdminNotificationsPageState
    extends ConsumerState<AdminNotificationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _headerFade;
  late Animation<double> _listFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _headerFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );
    _listFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _markAllRead(List<NotificationModel> notifications) async {
    if (notifications.every((n) => n.isRead)) return;
    await HapticService.success();
    await ref.read(notificationRepositoryProvider).markAllAsRead();
    ref.invalidate(notificationsProvider);
    ref.invalidate(notificationsStreamProvider);
  }

  Future<void> _markRead(NotificationModel n) async {
    if (n.isRead) return;
    await HapticService.selection();
    await ref.read(notificationRepositoryProvider).markAsRead(n.id);
    ref.invalidate(notificationsProvider);
    ref.invalidate(notificationsStreamProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Prefer the stream for live updates, fall back to FutureProvider while
    // stream is connecting.
    final asyncNotifs = ref.watch(notificationsStreamProvider).when(
          data: (list) => AsyncValue.data(list),
          loading: () => ref.watch(notificationsProvider),
          error: (e, st) => AsyncError<List<NotificationModel>>(e, st),
        );

    final hPad = context.rs(20, min: 16, max: 28);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.notifications_outlined,
                color: AppColors.accentCyan, size: 20),
            const SizedBox(width: 8),
            Text(
              'Notifications',
              style: AppTextStyles.title(color: Colors.white)
                  .copyWith(fontSize: context.sp(17, min: 15, max: 20)),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          asyncNotifs.whenOrNull(
                data: (list) {
                  final hasUnread = list.any((n) => !n.isRead);
                  if (!hasUnread) return const SizedBox.shrink();
                  return TextButton.icon(
                    onPressed: () => _markAllRead(list),
                    icon: const Icon(Icons.done_all,
                        color: AppColors.accentCyan, size: 16),
                    label: Text(
                      'All read',
                      style: AppTextStyles.caption(color: AppColors.accentCyan)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: FadeTransition(
        opacity: _listFade,
        child: asyncNotifs.when(
          loading: () => _LoadingShimmer(hPad: hPad),
          error: (e, _) => _ErrorView(
            onRetry: () {
              ref.invalidate(notificationsProvider);
              ref.invalidate(notificationsStreamProvider);
            },
          ),
          data: (notifications) => notifications.isEmpty
              ? _EmptyState(headerFade: _headerFade)
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(notificationsStreamProvider);
                    await Future.delayed(const Duration(milliseconds: 400));
                  },
                  color: AppColors.accentCyan,
                  backgroundColor: AppColors.surface,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      context.rs(8, min: 4, max: 12),
                      hPad,
                      context.rs(120, min: 100, max: 140),
                    ),
                    itemCount: notifications.length,
                    itemBuilder: (context, i) => _NotificationTile(
                      key: ValueKey(notifications[i].id),
                      notification: notifications[i],
                      delay: Duration(milliseconds: 40 * i),
                      onTap: () => _markRead(notifications[i]),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Notification Tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatefulWidget {
  const _NotificationTile({
    super.key,
    required this.notification,
    required this.delay,
    required this.onTap,
  });

  final NotificationModel notification;
  final Duration delay;
  final VoidCallback onTap;

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fade);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final icon = _iconFor(n.type);
    final color = _colorFor(n.type);
    final timeAgo = _formatTime(n.createdAt);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: n.isRead
                  ? AppColors.surfaceElevated
                  : color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: n.isRead
                    ? AppColors.outline
                    : color.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: AppTextStyles.body(color: Colors.white)
                                  .copyWith(
                                fontWeight: n.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.body,
                        style: AppTextStyles.caption(
                                color: AppColors.textSecondary)
                            .copyWith(height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeAgo,
                        style: AppTextStyles.caption(color: AppColors.textMuted)
                            .copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.uploadComplete:
        return Icons.check_circle_outline;
      case NotificationType.uploadFailed:
        return Icons.error_outline;
      case NotificationType.highRiskPlayer:
        return Icons.health_and_safety_outlined;
      case NotificationType.managerAdded:
        return Icons.person_add_outlined;
    }
  }

  Color _colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.uploadComplete:
        return AppColors.accentGreen;
      case NotificationType.uploadFailed:
        return AppColors.danger;
      case NotificationType.highRiskPlayer:
        return AppColors.warning;
      case NotificationType.managerAdded:
        return AppColors.accentCyan;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Loading shimmer ───────────────────────────────────────────────────────────

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer({required this.hPad});
  final double hPad;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 100),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GsShimmer.card(height: 80),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.headerFade});
  final Animation<double> headerFade;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: headerFade,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.accentCyan.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.notifications_none_outlined,
                    color: AppColors.accentCyan, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                'All clear',
                style: AppTextStyles.title(color: Colors.white)
                    .copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'You have no notifications yet.\nNew alerts will appear here.',
                style: AppTextStyles.body(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_outlined,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 16),
          Text(
            'Could not load notifications',
            style: AppTextStyles.body(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.button,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
