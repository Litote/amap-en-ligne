import 'dart:io';
import 'dart:typed_data';

import 'package:amap_en_ligne/data/local/database_export_save.dart';
import 'package:path_provider/path_provider.dart';

Future<DatabaseExportResult> saveDatabaseExportFileImpl({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final directory =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  await directory.create(recursive: true);
  final path = '${directory.path}${Platform.pathSeparator}$filename';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return DatabaseExportResult(filename: filename, path: path);
}
