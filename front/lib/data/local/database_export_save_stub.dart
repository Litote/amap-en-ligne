import 'dart:typed_data';

import 'package:amap_en_ligne/data/local/database_export_save.dart';

Future<DatabaseExportResult> saveDatabaseExportFileImpl({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) async {
  throw UnsupportedError('Database export is not supported on this platform.');
}
