import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class FanSectionPlaceholder extends StatelessWidget {
  const FanSectionPlaceholder({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.badgeText = 'FAN VIEW',
    this.highlights = const [],
    this.body,
    this.footer,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String badgeText;
  final List<String> highlights;
  final Widget? body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        context.rs(18, min: 14, max: 24),
        context.rs(18, min: 14, max: 24),
        context.rs(18, min: 14, max: 24),
        context.rs(28, min: 24, max: 36),
      ),
      children: [
        ResponsiveCentered(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionBadge(text: badgeText),
              SizedBox(height: context.rs(14, min: 10, max: 18)),
              _SectionHeroCard(
                title: title,
                subtitle: subtitle,
                icon: icon,
                accentColor: accentColor,
              ),
              if (body != null) ...[
                SizedBox(height: context.rs(14, min: 10, max: 18)),
                body!,
              ],
              if (highlights.isNotEmpty) ...[
                SizedBox(height: context.rs(14, min: 10, max: 18)),
                Wrap(
                  spacing: context.rs(10, min: 8, max: 12),
                  runSpacing: context.rs(10, min: 8, max: 12),
                  children: highlights
                      .map((label) => _HighlightChip(label: label))
                      .toList(),
                ),
              ],
              if (footer != null) ...[
                SizedBox(height: context.rs(16, min: 12, max: 20)),
                footer!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionBadge extends StatelessWidget {
  const _SectionBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.rs(12, min: 10, max: 14),
          vertical: context.rs(7, min: 6, max: 8),
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.9),
          borderRadius: AppRadius.chip,
          border: Border.all(color: AppColors.outlineSubtle),
        ),
        child: Text(
          text.toUpperCase(),
          style: AppTextStyles.caption(color: AppColors.textMuted).copyWith(
            fontSize: context.rs(10, min: 9, max: 11),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class _SectionHeroCard extends StatelessWidget {
  const _SectionHeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.16),
            AppColors.surface,
            AppColors.surfaceElevated.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          const BoxShadow(
            color: Color(0x29000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(context.rs(18, min: 16, max: 24)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: context.rs(56, min: 50, max: 60),
              height: context.rs(56, min: 50, max: 60),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withValues(alpha: 0.28),
                    accentColor.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: context.rs(28, min: 24, max: 30),
              ),
            ),
            SizedBox(width: context.rs(16, min: 12, max: 18)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headline(color: AppColors.textPrimary)
                        .copyWith(
                      fontSize: context.rs(24, min: 22, max: 30),
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: context.rs(8, min: 6, max: 10)),
                  Text(
                    subtitle,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(color: AppColors.textSecondary)
                        .copyWith(
                      fontSize: context.rs(14, min: 13, max: 16),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rs(12, min: 10, max: 14),
        vertical: context.rs(8, min: 7, max: 9),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.85),
        borderRadius: AppRadius.chip,
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption(color: AppColors.textSecondary).copyWith(
          fontSize: context.rs(10, min: 9, max: 11),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}