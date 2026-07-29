import 'package:flutter/material.dart';
import 'package:spendwise/theme/app_theme.dart';

/// BuildContext extension providing theme-aware color shortcuts.
/// Usage in build/helper methods: `context.appCardColor`, `context.isDark`, etc.
extension AppThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get appBgColor =>
      isDark ? AppTheme.darkBgColor : const Color(0xFFF7F8FC);

  Color get appCardColor =>
      isDark ? AppTheme.darkCardColor : Colors.white;

  Color get appTextPrimary =>
      isDark ? Colors.white : const Color(0xFF1A1D29);

  Color get appTextSecondary =>
      isDark ? AppTheme.darkTextSecondaryColor : const Color(0xFF6B7280);

  Color get appBorderColor =>
      isDark ? AppTheme.darkBorderColor : Colors.black.withOpacity(0.04);

  Color get appSurfaceColor =>
      isDark ? AppTheme.darkSurfaceColor : const Color(0xFFF7F8FC);

  Color get appInputFill =>
      isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F3F8);
}
