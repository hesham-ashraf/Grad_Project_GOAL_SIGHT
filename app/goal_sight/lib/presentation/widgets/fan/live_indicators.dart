import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

// ─── Live Match Banner ────────────────────────────────────────────────────────

/// Full-width live match banner for the Fan Home screen.
/// Features a continuously pulsing ring, gradient background and live count.
class LiveMatchBanner extends StatefulWidget {
  const LiveMatchBanner({
    super.key,
    required this.liveMatchCount,
    required this.matchDescription,
    this.onTap,
  });

  final int liveMatchCount;
  final String matchDescription;
  final VoidCallback? onTap;

  @override
  State<LiveMatchBanner> createState() => _LiveMatchBannerState();
}

class _LiveMatchBannerState extends State<LiveMatchBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: false);

    _scale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 0.65, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.success.withValues(alpha: 0.14),
              AppColors.accentCyan.withValues(alpha: 0.08),
              AppColors.success.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: AppRadius.cardLarge,
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.12),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.cardLarge,
          child: Stack(
            children: [
              // Glow orb background
              Positioned(
                right: -60,
                top: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.success.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rs(16, min: 14, max: 20),
                  vertical: context.rs(14, min: 12, max: 18),
                ),
                child: Row(
                  children: [
                    // Animated live dot
                    SizedBox(
                      width: context.rs(28, min: 24, max: 32),
                      height: context.rs(28, min: 24, max: 32),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              return Transform.scale(
                                scale: _scale.value,
                                child: Container(
                                  width: context.rs(12, min: 10, max: 14),
                                  height: context.rs(12, min: 10, max: 14),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.success
                                        .withValues(alpha: _opacity.value),
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            width: context.rs(12, min: 10, max: 14),
                            height: context.rs(12, min: 10, max: 14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withValues(alpha: 0.7),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.rs(12, min: 10, max: 14)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'LIVE NOW',
                                style: AppTextStyles.caption(
                                  color: AppColors.success,
                                ).copyWith(
                                  fontSize: context.rs(10, min: 9, max: 11),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              SizedBox(width: context.rs(8, min: 6, max: 10)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.rs(7, min: 6, max: 8),
                                  vertical: context.rs(2, min: 2, max: 3),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.18),
                                  borderRadius: AppRadius.chip,
                                  border: Border.all(
                                    color: AppColors.success.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  '${widget.liveMatchCount} match${widget.liveMatchCount != 1 ? 'es' : ''}',
                                  style: AppTextStyles.caption(
                                    color: AppColors.success,
                                  ).copyWith(
                                    fontSize: context.rs(9, min: 8, max: 10),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.rs(3, min: 2, max: 4)),
                          Text(
                            widget.matchDescription,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(
                              color: AppColors.textPrimary,
                            ).copyWith(
                              fontSize: context.rs(13, min: 12, max: 15),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.rs(8, min: 6, max: 10)),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: context.rs(20, min: 18, max: 22),
                      color: AppColors.success.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Live Analysis Indicator ──────────────────────────────────────────────────

/// Compact inline indicator used to flag that AI analysis is running.
class LiveAnalysisIndicator extends StatefulWidget {
  const LiveAnalysisIndicator({
    super.key,
    this.label = 'AI Analysis Running',
    this.color,
  });

  final String label;
  final Color? color;

  @override
  State<LiveAnalysisIndicator> createState() => _LiveAnalysisIndicatorState();
}

class _LiveAnalysisIndicatorState extends State<LiveAnalysisIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = widget.color ?? AppColors.accentCyan;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _fade,
          builder: (context, _) {
            return Container(
              width: context.rs(7, min: 6, max: 8),
              height: context.rs(7, min: 6, max: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: _fade.value),
                boxShadow: [
                  BoxShadow(
                    color: tint.withValues(alpha: _fade.value * 0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          },
        ),
        SizedBox(width: context.rs(6, min: 5, max: 7)),
        Text(
          widget.label,
          style: AppTextStyles.caption(color: tint).copyWith(
            fontSize: context.rs(10, min: 9, max: 11),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─── Pulsing Orb ─────────────────────────────────────────────────────────────

/// A standalone pulsing circle used as a decorative live signal indicator.
class PulsingOrb extends StatefulWidget {
  const PulsingOrb({
    super.key,
    required this.color,
    this.size = 12,
  });

  final Color color;
  final double size;

  @override
  State<PulsingOrb> createState() => _PulsingOrbState();
}

class _PulsingOrbState extends State<PulsingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _scale = Tween<double>(begin: 1.0, end: 2.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2.5,
      height: widget.size * 2.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color
                        .withValues(alpha: _opacity.value),
                  ),
                ),
              );
            },
          ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.55),
                  blurRadius: widget.size * 0.8,
                  spreadRadius: widget.size * 0.1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
