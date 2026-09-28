import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

final Future<void> _frenchDateFormattingInitialization =
    initializeDateFormatting('fr');

Future<void> ensureFrenchDateFormattingInitialized() =>
    _frenchDateFormattingInitialization;

/// French date format whose day of month reads "1er" on the first ("jeudi
/// 1er octobre"), as French typography wants; other days are unchanged. Use it
/// instead of `DateFormat(pattern, 'fr')` for any pattern showing the day.
FrenchDateFormat frenchDateFormat(String pattern) => FrenchDateFormat(pattern);

class FrenchDateFormat {
  FrenchDateFormat(String pattern)
    : _format = DateFormat(pattern, 'fr'),
      _firstOfMonthFormat = DateFormat(_withFirstOfMonth(pattern), 'fr');

  final DateFormat _format;
  final DateFormat _firstOfMonthFormat;

  String format(DateTime date) =>
      (date.day == 1 ? _firstOfMonthFormat : _format).format(date);
}

/// [pattern] where each single `d` (day of month, not `dd`) outside quoted
/// text becomes the literal `1er`.
String _withFirstOfMonth(String pattern) {
  final out = StringBuffer();
  var quoted = false;
  for (var i = 0; i < pattern.length; i++) {
    final char = pattern[i];
    if (char == "'") quoted = !quoted;
    final singleDay =
        !quoted &&
        char == 'd' &&
        (i == 0 || pattern[i - 1] != 'd') &&
        (i == pattern.length - 1 || pattern[i + 1] != 'd');
    out.write(singleDay ? "'1er'" : char);
  }
  return out.toString();
}
