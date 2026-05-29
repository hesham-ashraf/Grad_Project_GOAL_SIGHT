// ---------------------------------------------------------------------------
// GoalSight — GsSuccessOverlay
//
// Full-screen success animation overlay for key moments:
//   • Upload complete
//   • Analysis generated
//   • Settings saved
//   • Action confirmed
//
// Usage:
//   GsSuccessOverlay.show(context, message: 'Analysis Ready!');
//
// The overlay auto-dismisses after [duration] and calls [onDismiss].
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../core/animations/motion_tokens.dart';
import '../../core/services/haptic_service.dart';
import '../../core/theme/app_theme.dart';

enum GsSuccessType {
  uploadComplete,
  analysisReady,
  settingsSaved,
  actionConfirmed,
  custom,
}

extension _GsSuccessTypeExt on GsSuccessType {
  IconData get icon {
    switch (this) {
      case GsSuccessType.uploadComplete:
        return Icons.cloud_done_rounded;
      case GsSuccessType.analysisReady:
        return Icons.auto_awesome_rounded;
      case GsSuccessType.settingsSaved:
        return Icons.check_circle_rounded;
      case GsSuccessType.actionConfirmed:
        return Icons.task_alt_rounded;
      case GsSuccessType.custom:
        return Icons.check_circle_rounded;
    }
  }

  Color get color {
    switch (this) {
      case GsSuccessType.uploadComplete:
        return AppColors.accentCyan;
      case GsSuccessType.analysisReady:
        return AppColors.primaryPurple;
      case GsSuccessType.settingsSaved:
        return AppColors.accentGreen;
      case GsSuccessType.actionConfirmed:
        return AppColors.accentGreen;
      case GsSuccessType.custom:
        return AppColors.accentCyan;
    }
  }

  String get defaultMessage {
    switch (this) {
      case GsSuccessType.uploadComplete:
        return 'Upload Complete';
      case GsSuccessType.analysisReady:
        return 'Analysis Ready';
      case GsSuccessType.settingsSaved:
        return 'Settings Saved';
      case GsSuccessType.actionConfirmed:
        return 'Action Confirmed';
      case GsSuccessType.custom:
        return 'Done!';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class GsSuccessOverlay {
  GsSuccessOverlay._();

  /// Show a floating success overlay — auto-dismisses after [duration]
  static void show(
    BuildContext context, {
    String? message,
    String? subtitle,
    GsSuccessType type = GsSuccessType.actionConfirmed,
    IconData? icon,
    Color? color,
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onDismiss,
  }) {
    final entry = OverlayEntry(
      builder: (_) => _GsSuccessWidget(
        message: message ?? type.defaultMessage,
        subtitle: subtitle,
        icon: icon ?? type.icon,
        color: color ?? type.color,
        duration: duration,
      ),
    );

    Overlay.of(context).insert(entry);

    Future.delayed(duration + const Duration(milliseconds: 500), () {
      if (entry.mounted) entry.remove();
      onDismiss?.call();
    });
  }
}

// ── Internal animated widget ──────────────────────────────────────────────

class _GsSuccessWidget extends StatefulWidget {
  const _GsSuccessWidget({
    required this.message,
    required this.icon,
    required this.color,
    required this.duration,
    this.subtitle,
  });

  final String message;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Duration duration;

  @override
  State<_GsSuccessWidget> createState() => _GsSuccessWidgetState();
}

class _GsSuccessWidgetState extends State<_GsSuccessWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _ringExpand;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: GoalSightMotion.slow);

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.4, curve: Curves.easeOut)),
    );
    _scale = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.elasticOut)),
    );
    _ringExpand = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic)),
    );

    _ctrl.forward();
    HapticService.success();

    // Schedule fade-out
    Future.delayed(widget.duration, () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.32,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fade,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: 220,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.cardLarge,
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated ring + icon
                  AnimatedBuilder(
                    animation: _ringExpand,
                    builder: (_, child) => Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 72 * _ringExpand.value,
                          height: 72 * _ringExpand.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.color.withValues(alpha: 0.08 * _ringExpand.value),
                            border: Border.all(
                              color: widget.color.withValues(alpha: 0.3 * _ringExpand.value),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child!,
                      ],
                    ),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: 0.15),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 26),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    widget.message,
                    style: AppTextStyles.title(color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),

                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle!,
                      style: AppTextStyles.caption(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GsSuccessSnackBar — lightweight inline snack for smaller confirmations
// ---------------------------------------------------------------------------

class GsSuccessSnackBar {
  GsSuccessSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    Color? color,
    IconData icon = Icons.check_circle_rounded,
    Duration duration = const Duration(seconds: 3),
  }) {
    final c = color ?? AppColors.accentGreen;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        margin: const EdgeInsets.all(12),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: c, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
