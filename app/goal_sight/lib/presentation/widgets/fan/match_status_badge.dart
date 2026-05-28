import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

// ─── Status Enum ─────────────────────────────────────────────────────────────

enum MatchStatus {
  live,
  fullTime,
  upcoming,
  analysisReady,
  delayed,
}

extension MatchStatusX on MatchStatus {
  String get label {
    switch (this) {
      case MatchStatus.live:
        return 'LIVE';
      case MatchStatus.fullTime:
        return 'FT';
      case MatchStatus.upcoming:
        return 'UPCOMING';
      case MatchStatus.analysisReady:
        return 'ANALYSIS';
      case MatchStatus.delayed:
        return 'DELAYED';
    }
  }

  Color get color {
    switch (this) {
      case MatchStatus.live:
        return const Color(0xFF4CE58A);
      case MatchStatus.fullTime:
        return AppColors.textMuted;
      case MatchStatus.upcoming:
        return AppColors.primaryBlue;
      case MatchStatus.analysisReady:
        return AppColors.accentCyan;
      case MatchStatus.delayed:
        return AppColors.warning;
    }
  }

  IconData get icon {
    switch (this) {
      case MatchStatus.live:
        return Icons.radio_button_checked_rounded;
      case MatchStatus.fullTime:
        return Icons.check_circle_outline_rounded;
      case MatchStatus.upcoming:
        return Icons.schedule_rounded;
      case MatchStatus.analysisReady:
        return Icons.auto_awesome_rounded;
      case MatchStatus.delayed:
        return Icons.warning_amber_rounded;
    }
  }

  /// Parse a raw API/mock status string into [MatchStatus].
  static MatchStatus fromString(String raw) {
    switch (raw.toUpperCase()) {
      case 'LIVE':
        return MatchStatus.live;
      case 'FT':
      case 'FULL TIME':
        return MatchStatus.fullTime;
      case 'UPCOMING':
        return MatchStatus.upcoming;
      case 'ANALYSIS':
      case 'ANALYSIS READY':
        return MatchStatus.analysisReady;
      case 'DELAYED':
        return MatchStatus.delayed;
      default:
        return MatchStatus.fullTime;
    }
  }
}

// ─── Badge Widget ─────────────────────────────────────────────────────────────

/// Premium reusable status badge. The LIVE variant includes a continuous
/// pulse animation so it's immediately distinguishable from static states.
class MatchStatusBadge extends StatefulWidget {
  const MatchStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final MatchStatus status;

  /// When [compact] is true the icon is omitted and font is smaller.
  final bool compact;

  @override
  State<MatchStatusBadge> createState() => _MatchStatusBadgeState();
}

class _MatchStatusBadgeState extends State<MatchStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.9).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
    );

    _pulseOpacity = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    if (widget.status == MatchStatus.live) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(MatchStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == MatchStatus.live && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (widget.status != MatchStatus.live && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final color = status.color;
    final isLive = status == MatchStatus.live;

    return Container(
      padding: widget.compact
          ? EdgeInsets.symmetric(
              horizontal: context.rs(8, min: 7, max: 10),
              vertical: context.rs(3, min: 3, max: 5),
            )
          : EdgeInsets.symmetric(
              horizontal: context.rs(10, min: 9, max: 12),
              vertical: context.rs(5, min: 4, max: 7),
            ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isLive ? 0.15 : 0.10),
        borderRadius: AppRadius.chip,
        border: Border.all(
          color: color.withValues(alpha: isLive ? 0.45 : 0.28),
        ),
        boxShadow: isLive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.22),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live pulse indicator dot
          if (isLive)
            SizedBox(
              width: context.rs(14, min: 12, max: 16),
              height: context.rs(14, min: 12, max: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Transform.scale(
                        scale: _pulseScale.value,
                        child: Container(
                          width: context.rs(8, min: 7, max: 9),
                          height: context.rs(8, min: 7, max: 9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: _pulseOpacity.value),
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: context.rs(7, min: 6, max: 8),
                    height: context.rs(7, min: 6, max: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (!widget.compact)
            Icon(
              status.icon,
              size: context.rs(12, min: 11, max: 14),
              color: color,
            ),
          if (!widget.compact || isLive)
            SizedBox(width: context.rs(5, min: 4, max: 6)),
          Text(
            status.label,
            style: AppTextStyles.caption(color: color).copyWith(
              fontSize: widget.compact
                  ? context.rs(9, min: 8, max: 10)
                  : context.rs(10, min: 9, max: 11),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience constructor: parse raw status string and build badge.
class MatchStatusBadgeFromString extends StatelessWidget {
  const MatchStatusBadgeFromString({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return MatchStatusBadge(
      status: MatchStatusX.fromString(status),
      compact: compact,
    );
  }
}
