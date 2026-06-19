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

/// Records a breadcrumb for an expected, recoverable fallback (lookup miss,
/// claim decode failure, parse failure) that the call site deliberately
/// swallows.
///
/// Cheap and safe to call from build paths: it only annotates the Sentry
/// timeline of a later event, it never creates an event by itself.
void recordFallbackBreadcrumb(String message, Object error) {
  unawaited(
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'fallback',
        level: SentryLevel.warning,
        message: '$message: $error',
      ),
    ),
  );
}
