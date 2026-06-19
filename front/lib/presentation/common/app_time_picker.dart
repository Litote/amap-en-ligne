import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const appLocale = Locale('fr');

String formatAppTimeOfDay(BuildContext context, TimeOfDay time) {
  return MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(time, alwaysUse24HourFormat: true);
}

Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (context) {
      return Localizations.override(
        context: context,
        locale: appLocale,
        delegates: GlobalMaterialLocalizations.delegates,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: TimePickerDialog(initialTime: initialTime),
        ),
      );
    },
  );
}
