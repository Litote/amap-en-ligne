import 'dart:js_interop';

@JS('window.open')
external void _windowOpen(String url, String target);

Future<void> openUrl(String url) async {
  _windowOpen(url, '_blank');
}
