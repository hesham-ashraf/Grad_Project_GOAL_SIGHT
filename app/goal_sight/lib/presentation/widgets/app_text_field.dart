import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.hintText,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? hintText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(fontSize: context.sp(15, min: 13, max: 19)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixIcon: suffixIcon,
        isDense: true,
        contentPadding: context.padSym(h: 14, v: 14),
      ),
    );
  }
}
