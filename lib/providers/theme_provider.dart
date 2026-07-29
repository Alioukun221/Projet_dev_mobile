import 'package:flutter/material.dart';
import 'package:spendwise/services/auth_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void applyFromData(Map<String, dynamic>? data) {
    if (data == null) return;
    final theme = data['preferred_theme'] as String? ?? 'light';
    _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      await AuthService().updateProfile(
        preferredTheme: _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (e) { debugPrint('ThemeProvider.toggleTheme: $e'); }
  }
}
