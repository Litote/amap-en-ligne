import 'package:intl/date_symbol_data_local.dart';

final Future<void> _frenchDateFormattingInitialization =
    initializeDateFormatting('fr');

Future<void> ensureFrenchDateFormattingInitialized() {
  return _frenchDateFormattingInitialization;
}
