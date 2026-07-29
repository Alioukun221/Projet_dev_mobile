import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:spendwise/providers/profile_provider.dart';

String appLocaleName(BuildContext context) {
  final locale = Localizations.localeOf(context);
  final country = locale.countryCode;
  return country == null
      ? locale.languageCode
      : '${locale.languageCode}_$country';
}

String appCurrency(BuildContext context, {bool listen = false}) {
  final profileProvider = Provider.of<ProfileProvider>(context, listen: listen);
  return profileProvider.profile?.currency ?? 'CFA';
}

String formatMoney(
  BuildContext context,
  num amount, {
  bool withCurrency = true,
  bool listen = false,
}) {
  final value = NumberFormat('#,###', appLocaleName(context)).format(amount);
  if (!withCurrency) return value;
  return '$value ${appCurrency(context, listen: listen)}';
}

String formatCompactNumber(BuildContext context, num value) {
  return NumberFormat.compact(locale: appLocaleName(context)).format(value);
}

String formatDate(BuildContext context, String pattern, DateTime date) {
  return DateFormat(pattern, appLocaleName(context)).format(date);
}
