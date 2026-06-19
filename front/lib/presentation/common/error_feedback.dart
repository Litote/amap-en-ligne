import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// User-facing copy for unexpected errors.
const String kUnexpectedErrorMessage =
    'Une erreur est survenue. Veuillez réessayer.';

/// Reports [error] to Sentry and shows the generic error snackbar.
///
/// Raw exception text must never reach the UI: the detail goes to Sentry,
/// the user only sees [kUnexpectedErrorMessage].
void showUnexpectedErrorSnackBar(
  BuildContext context,
  Object error,
  StackTrace stackTrace,
) {
  unawaited(Sentry.captureException(error, stackTrace: stackTrace));
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text(kUnexpectedErrorMessage)));
}
