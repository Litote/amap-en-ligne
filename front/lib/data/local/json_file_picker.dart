import 'package:amap_en_ligne/data/local/json_file_picker_stub.dart'
    if (dart.library.js_interop) 'package:amap_en_ligne/data/local/json_file_picker_web.dart';

/// A picked JSON file: its [filename] and its decoded text [content].
class PickedJsonFile {
  const PickedJsonFile({required this.filename, required this.content});

  final String filename;
  final String content;
}

/// Opens the platform file chooser and returns the picked JSON file, or `null`
/// if the user cancelled.
///
/// Only implemented on the web in V1 (the import flow is web-only); the stub
/// throws [UnsupportedError] on other platforms.
Future<PickedJsonFile?> pickJsonFile() => pickJsonFileImpl();
