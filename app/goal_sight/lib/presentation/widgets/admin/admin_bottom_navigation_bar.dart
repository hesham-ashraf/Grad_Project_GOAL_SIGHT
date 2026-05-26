import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class AdminNavigationTab {
  const AdminNavigationTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class AdminBottomNavigationBar extends StatelessWidget {
  const AdminBottomNavigationBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onChanged,
  });

  static const double _horizontalPadding = 16;
  static const double _verticalPadding = 10;
  static const double _contentHeight = 72;
  static const double _radius = 28;
  static const Duration _animationDuration = Duration(milliseconds: 220);

  final List<AdminNavigationTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  static double totalHeight(BuildContext context) {
    return MediaQuery.of(context).viewPadding.bottom +
        (_verticalPadding * 2) +
        _contentHeight;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final iconSize = context.isCompact ? 19.0 : 20.0;
    final labelFontSize = context.isCompact ? 9.5 : 10.5;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _horizontalPadding,
        0,
        _horizontalPadding,
        bottomInset + _verticalPadding,
      ),
      child: Align(
        heightFactor: 1,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(
                    color: AppColors.outlineSubtle.withValues(alpha: 0.95),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.1),
                      blurRadius: 22,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: _contentHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: List.generate(tabs.length, (index) {
                        final tab = tabs[index];
                        final isSelected = index == currentIndex;
                        final iconColor = isSelected
                            ? Colors.white
                            : AppColors.textMuted;

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.rs(2, min: 1, max: 4),
                            ),
                            child: _AdminTabButton(
                              tab: tab,
                              isSelected: isSelected,
                              iconSize: iconSize,
                              labelFontSize: labelFontSize,
                              iconColor: iconColor,
                              onTap: () => onChanged(index),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminTabButton extends StatelessWidget {
  const _AdminTabButton({
    required this.tab,
    required this.isSelected,
    required this.iconSize,
    required this.labelFontSize,
    required this.iconColor,
    required this.onTap,
  });

  final AdminNavigationTab tab;
  final bool isSelected;
  final double iconSize;
  final double labelFontSize;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: tab.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AdminBottomNavigationBar._animationDuration,
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            vertical: context.rs(6, min: 4, max: 8),
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryPurple.withValues(alpha: 0.28),
                      AppColors.accentCyan.withValues(alpha: 0.18),
                    ],
                  )
                : null,
            color: isSelected
                ? AppColors.primaryPurple.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1 : 0.92,
                duration: AdminBottomNavigationBar._animationDuration,
                curve: Curves.easeOutCubic,
                child: Icon(
                  isSelected ? tab.activeIcon : tab.icon,
                  size: iconSize,
                  color: iconColor,
                ),
              ),
              SizedBox(height: context.rs(4, min: 3, max: 5)),
              AnimatedDefaultTextStyle(
                duration: AdminBottomNavigationBar._animationDuration,
                curve: Curves.easeOutCubic,
                style: AppTextStyles.caption(
                  color: iconColor,
                ).copyWith(
                  fontSize: labelFontSize,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  height: 1.05,
                ),
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
