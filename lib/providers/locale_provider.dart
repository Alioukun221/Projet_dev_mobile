import 'package:flutter/material.dart';
import 'package:spendwise/services/auth_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  Future<void> loadFromProfile() async {
    try {
      final profile = await AuthService().getProfile();
      if (profile != null) {
        final localeCode = profile['preferred_locale'] as String? ?? 'fr';
        final newLocale = Locale(localeCode);
        if (L10n.supportedLocales.contains(newLocale)) {
          _locale = newLocale;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> setLocale(Locale locale) async {
    if (!L10n.supportedLocales.contains(locale)) return;
    _locale = locale;
    notifyListeners();
    try {
      await AuthService().updateProfile(
        preferredLocale: locale.languageCode,
      );
    } catch (_) {}
  }
}

class L10n {
  static const supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('es'),
  ];
}
