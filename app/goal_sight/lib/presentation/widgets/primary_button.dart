import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final radius = context.rs(14, min: 12, max: 18);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: loading
            ? const LinearGradient(
                colors: [Color(0xFF9DA7BF), Color(0xFF8A95B5)],
              )
            : AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x447057F5),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? SizedBox(
                  width: context.rs(18, min: 14, max: 22),
                  height: context.rs(18, min: 14, max: 22),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  icon ?? Icons.arrow_forward,
                  color: Colors.white,
                  size: context.rs(20, min: 16, max: 24),
                ),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                fontSize: context.sp(14, min: 12, max: 18),
              ),
            ),
          ),
          style: TextButton.styleFrom(
            padding: context.padSym(v: 14, h: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
