import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart' as intl;

class WoMaterialLocalizations extends GlobalMaterialLocalizations {
  const WoMaterialLocalizations({
    required String localeName,
    required intl.DateFormat fullYearFormat,
    required intl.DateFormat compactDateFormat,
    required intl.DateFormat shortDateFormat,
    required intl.DateFormat mediumDateFormat,
    required intl.DateFormat longDateFormat,
    required intl.DateFormat yearMonthFormat,
    required intl.DateFormat shortMonthDayFormat,
    required intl.NumberFormat decimalFormat,
    required intl.NumberFormat twoDigitZeroPaddedFormat,
  }) : super(
            localeName: localeName,
            fullYearFormat: fullYearFormat,
            compactDateFormat: compactDateFormat,
            shortDateFormat: shortDateFormat,
            mediumDateFormat: mediumDateFormat,
            longDateFormat: longDateFormat,
            yearMonthFormat: yearMonthFormat,
            shortMonthDayFormat: shortMonthDayFormat,
            decimalFormat: decimalFormat,
            twoDigitZeroPaddedFormat: twoDigitZeroPaddedFormat);

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _WoMaterialLocalizationsDelegate();

  @override
  String get okButtonLabel => 'OK';

  @override
  String get cancelButtonLabel => 'Neenal';

  @override
  String get backButtonTooltip => 'Delloo';

  @override
  String get closeButtonLabel => 'Tëj';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WoMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _WoMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'wo';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    final String localeName = locale.toString();

    return SynchronousFuture(
      WoMaterialLocalizations(
        localeName: localeName,
        fullYearFormat: DateFormat.y(localeName),
        compactDateFormat: DateFormat.yMd(localeName),
        shortDateFormat: DateFormat.yMMMd(localeName),
        mediumDateFormat: DateFormat.MMMEd(localeName),
        longDateFormat: DateFormat.yMMMMEEEEd(localeName),
        yearMonthFormat: DateFormat.yMMMM(localeName),
        shortMonthDayFormat: DateFormat.yMMMM(localeName),
        decimalFormat: NumberFormat(localeName),
        twoDigitZeroPaddedFormat: NumberFormat(localeName),
      ) as MaterialLocalizations,
    );
  }

  @override
  bool shouldReload(LocalizationsDelegate<MaterialLocalizations> old) => false;
}
