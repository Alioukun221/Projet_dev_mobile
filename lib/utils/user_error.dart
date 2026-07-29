import 'package:spendwise/l10n/app_localizations.dart';

String userErrorMessage(Object error, AppLocalizations l10n) {
  final raw = error.toString().toLowerCase();
  if (raw.contains('network') ||
      raw.contains('socket') ||
      raw.contains('connection') ||
      raw.contains('timeout')) {
    return l10n.processingError;
  }
  if (raw.contains('auth') || raw.contains('no authenticated user')) {
    return l10n.authUnexpectedError;
  }
  return l10n.processingError;
}
