import 'dart:typed_data';

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/local/database_constants.dart';
import 'package:amap_en_ligne/data/local/database_open_web.dart';

Future<Uint8List> exportOpenedDatabaseBytesImpl(AppDatabase db) async {
  final probe = await probeAppDatabase();
  final chosenStorage = chooseAppDatabaseStorage(probe);

  for (final existing in probe.existingDatabases) {
    if (existing.$1 == chosenStorage.storageApi &&
        existing.$2 == appDatabaseName) {
      final bytes = await probe.exportDatabase(existing);
      if (bytes != null) return bytes;
    }
  }

  for (final existing in probe.existingDatabases) {
    if (existing.$2 == appDatabaseName) {
      final bytes = await probe.exportDatabase(existing);
      if (bytes != null) return bytes;
    }
  }

  throw StateError('No persisted local database was found in this browser.');
}
