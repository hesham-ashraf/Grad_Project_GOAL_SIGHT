import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: loading
            ? const LinearGradient(
                colors: [Color(0xFF9DA7BF), Color(0xFF8A95B5)],
              )
            : AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(14),
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
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon ?? Icons.arrow_forward, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
