import 'dart:typed_data';

import 'package:amap_en_ligne/data/local/database_export_save_stub.dart'
    if (dart.library.js_interop) 'package:amap_en_ligne/data/local/database_export_save_web.dart'
    if (dart.library.io) 'package:amap_en_ligne/data/local/database_export_save_native.dart';

class DatabaseExportResult {
  const DatabaseExportResult({
    required this.filename,
    this.path,
    this.downloadTriggered = false,
  });

  final String filename;
  final String? path;
  final bool downloadTriggered;
}

Future<DatabaseExportResult> saveDatabaseExportFile({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) => saveDatabaseExportFileImpl(
  filename: filename,
  bytes: bytes,
  mimeType: mimeType,
);
