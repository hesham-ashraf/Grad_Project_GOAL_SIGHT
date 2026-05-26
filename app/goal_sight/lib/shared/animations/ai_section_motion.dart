import 'package:flutter/material.dart';

import '../../core/animations/motion_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../components/glass_container.dart';
import 'glow_pulse.dart';
import 'reveal_animations.dart';

class GoalSightAiSection extends StatefulWidget {
  const GoalSightAiSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.initiallyExpanded = true,
    this.accent = AppColors.accentCyan,
    this.icon = Icons.auto_awesome_rounded,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;
  final Color accent;
  final IconData icon;

  @override
  State<GoalSightAiSection> createState() => _GoalSightAiSectionState();
}

class _GoalSightAiSectionState extends State<GoalSightAiSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return GoalSightGlowPulse(
      color: widget.accent,
      enabled: _expanded,
      minOpacity: 0.04,
      maxOpacity: 0.12,
      child: GoalSightGlass(
        opacity: 0.82,
        borderColor: widget.accent.withValues(alpha: 0.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.accent.withValues(alpha: 0.08),
            AppColors.primaryPurple.withValues(alpha: 0.07),
            AppColors.surfaceElevated.withValues(alpha: 0.9),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: AppRadius.card,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: AppGradients.brand,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTextStyles.title(color: AppColors.textPrimary)
                              .copyWith(fontSize: 16),
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: GoalSightMotion.fast,
                    curve: GoalSightMotion.standard,
                    child: Icon(Icons.expand_more_rounded, color: widget.accent),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: GoalSightStaggeredReveal(
                  delayStep: const Duration(milliseconds: 55),
                  children: widget.children,
                ),
              ),
              crossFadeState:
                  _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: GoalSightMotion.normal,
              firstCurve: GoalSightMotion.exit,
              secondCurve: GoalSightMotion.entrance,
              sizeCurve: GoalSightMotion.standard,
            ),
          ],
        ),
      ),
    );
  }
}
