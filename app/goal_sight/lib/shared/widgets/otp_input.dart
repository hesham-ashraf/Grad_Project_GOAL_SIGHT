// ---------------------------------------------------------------------------
// GoalSight — OTP Input Widget
// 6-box one-time-password entry that auto-advances between cells and
// supports paste of the full code.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.enabled = true,
    this.length = 6,
    this.autofocus = true,
  });

  final void Function(String code) onCompleted;
  final void Function(String code)? onChanged;
  final bool enabled;
  final int length;
  final bool autofocus;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Paste handling: distribute across boxes.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.length && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final nextFocus = (digits.length < widget.length)
          ? digits.length
          : widget.length - 1;
      _nodes[nextFocus].requestFocus();
    } else if (value.length == 1) {
      if (index < widget.length - 1) {
        _nodes[index + 1].requestFocus();
      } else {
        _nodes[index].unfocus();
      }
    }
    final code = _code;
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
    setState(() {});
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _nodes[index - 1].requestFocus();
      widget.onChanged?.call(_code);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (i) {
        final isFilled = _controllers[i].text.isNotEmpty;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.length > 4 ? 4 : 8),
          child: KeyboardListener(
            focusNode: FocusNode(skipTraversal: true),
            onKeyEvent: (e) => _onKeyEvent(i, e),
            child: SizedBox(
              width: 42,
              height: 52,
              child: TextFormField(
                controller: _controllers[i],
                focusNode: _nodes[i],
                autofocus: widget.autofocus && i == 0,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6, // allow paste of full code in any box
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.title(color: AppColors.textPrimary)
                    .copyWith(fontSize: 22, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: isFilled
                      ? AppColors.primaryPurple.withValues(alpha: 0.12)
                      : AppColors.surfaceElevated.withValues(alpha: 0.7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isFilled
                          ? AppColors.primaryPurple.withValues(alpha: 0.6)
                          : AppColors.outlineSubtle,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isFilled
                          ? AppColors.primaryPurple.withValues(alpha: 0.6)
                          : AppColors.outlineSubtle,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primaryPurple,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => _onChanged(i, v),
              ),
            ),
          ),
        );
      }),
    );
  }
}
