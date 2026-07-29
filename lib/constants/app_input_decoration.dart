import 'package:flutter/material.dart';
import 'package:spendwise/constants/app_colors.dart';

class AppInputDecoration {
  AppInputDecoration._();

  static const Color _primaryBlue = Color(0xFF005EFF);
  static const Color _red = Color(0xFFEF4444);

  /// Standard input decoration used across all form pages.
  static InputDecoration of(
    BuildContext context, {
    required String label,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: context.appTextSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: context.appTextSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: context.appInputFill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.appBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.appBorderColor),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _primaryBlue, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _red, width: 1.5),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _red, width: 1.5),
      ),
    );
  }
}
