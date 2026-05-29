// ---------------------------------------------------------------------------
// GoalSight — Haptic Service
//
// Centralised haptic feedback system.
// All UI interactions should call HapticService rather than
// HapticFeedback directly, so intensity/type can be tuned globally.
// ---------------------------------------------------------------------------

import 'package:flutter/services.dart';

abstract final class HapticService {
  HapticService._();

  // ── Selection / navigation ─────────────────────────────────────────────

  /// Light tap — chip selection, tab switches, list item taps
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Light impact — button presses, card taps, toggles
  static Future<void> light() => HapticFeedback.lightImpact();

  // ── Confirmation / success ─────────────────────────────────────────────

  /// Medium impact — upload start, filter apply, form submit
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Heavy impact + notification — analysis complete, upload success
  static Future<void> success() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  // ── Errors / warnings ─────────────────────────────────────────────────

  /// Vibrate — errors, destructive actions, form validation failures
  static Future<void> error() => HapticFeedback.vibrate();

  /// Heavy impact — critical warnings, delete confirmations
  static Future<void> warning() => HapticFeedback.heavyImpact();

  // ── Specialised patterns ───────────────────────────────────────────────

  /// Double tap — pull-to-refresh trigger
  static Future<void> refresh() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.lightImpact();
  }

  /// Triple pulse — AI processing complete, major insight reveal
  static Future<void> aiReveal() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  /// Long press confirm — drag, reorder, hold-to-delete
  static Future<void> longPress() => HapticFeedback.heavyImpact();
}
