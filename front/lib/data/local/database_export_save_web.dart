import 'dart:js_interop';
import 'dart:typed_data';

import 'package:amap_en_ligne/data/local/database_export_save.dart';
import 'package:web/web.dart' as web;

Future<DatabaseExportResult> saveDatabaseExportFileImpl({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return DatabaseExportResult(filename: filename, downloadTriggered: true);
}
