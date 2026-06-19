import 'dart:io';
import 'dart:typed_data';

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/local/database_constants.dart';
import 'package:path_provider/path_provider.dart';

Future<Uint8List> exportOpenedDatabaseBytesImpl(AppDatabase db) async {
  final directory = await getTemporaryDirectory();
  final filename =
      '${DateTime.now().microsecondsSinceEpoch}_$appDatabaseFileName';
  final exportPath = '${directory.path}${Platform.pathSeparator}$filename';

  try {
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    await db.customStatement("VACUUM INTO '${_escapeSqlLiteral(exportPath)}'");
    return await File(exportPath).readAsBytes();
  } finally {
    final file = File(exportPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

String _escapeSqlLiteral(String value) => value.replaceAll("'", "''");
