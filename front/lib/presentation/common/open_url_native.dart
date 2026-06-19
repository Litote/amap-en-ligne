import 'package:flutter/foundation.dart' show debugPrint;
import 'package:url_launcher/url_launcher.dart';

Future<void> openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } on Exception catch (e) {
    debugPrint('Failed to open URL "$url": $e');
  }
}
