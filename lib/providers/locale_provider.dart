import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spendwise/services/auth_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  void applyFromData(Map<String, dynamic>? data) {
    if (data == null) return;
    final localeCode = data['preferred_locale'] as String? ?? 'fr';
    final newLocale = Locale(localeCode);
    if (L10n.supportedLocales.contains(newLocale)) {
      _locale = newLocale;
      notifyListeners();
    }
  }

  Future<void> loadFromProfile() async {
    try {
      final data = await AuthService().getProfile();
      applyFromData(data);
    } catch (e) { debugPrint('LocaleProvider.loadFromProfile: $e'); }
  }

  Future<void> setLocale(Locale locale) async {
    if (!L10n.supportedLocales.contains(locale)) return;
    _locale = locale;
    notifyListeners();
    try {
      await AuthService().updateProfile(
        preferredLocale: locale.languageCode,
      );
    } catch (e) { debugPrint('LocaleProvider.setLocale: $e'); }
  }
}

class L10n {
  static const supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('es'),
  ];
}
