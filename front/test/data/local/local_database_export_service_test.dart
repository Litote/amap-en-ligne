import 'dart:typed_data';

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/local/database_export_save.dart';
import 'package:amap_en_ligne/data/local/local_database_export_service.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  test(
    'zips exported sqlite bytes and saves them with a user-specific filename',
    () async {
      final db = _MockAppDatabase();
      final savedFiles =
          <({String filename, Uint8List bytes, String mimeType})>[];
      final sourceBytes = Uint8List.fromList([1, 2, 3, 4]);
      final service = LocalDatabaseExportService(
        db: db,
        exportDatabaseBytes: (_) async => sourceBytes,
        saveFile:
            ({
              required String filename,
              required Uint8List bytes,
              required String mimeType,
            }) async {
              savedFiles.add((
                filename: filename,
                bytes: bytes,
                mimeType: mimeType,
              ));
              return DatabaseExportResult(
                filename: filename,
                path: '/exports/$filename',
              );
            },
        now: () => DateTime.utc(2026, 1, 2, 3, 4, 5),
      );

      final result = await service.exportCurrentUserDatabase(
        userId: 'owner:42',
      );

      expect(result.filename, 'amap_en_ligne_owner_42_20260102T030405Z.zip');
      expect(
        result.path,
        '/exports/amap_en_ligne_owner_42_20260102T030405Z.zip',
      );
      expect(savedFiles, hasLength(1));
      expect(savedFiles.single.mimeType, 'application/zip');

      final archive = ZipDecoder().decodeBytes(savedFiles.single.bytes);
      expect(archive.files, hasLength(1));
      expect(archive.files.single.name, 'amap_en_ligne.sqlite');
      expect(archive.files.single.content as List<int>, sourceBytes);
    },
  );

  test('reports browser downloads without a local path', () async {
    final db = _MockAppDatabase();
    final service = LocalDatabaseExportService(
      db: db,
      exportDatabaseBytes: (_) async => Uint8List.fromList([9, 8, 7]),
      saveFile:
          ({
            required String filename,
            required Uint8List bytes,
            required String mimeType,
          }) async =>
              DatabaseExportResult(filename: filename, downloadTriggered: true),
      now: () => DateTime.utc(2026, 6, 4, 12, 0, 0),
    );

    final result = await service.exportCurrentUserDatabase(userId: 'member-7');

    expect(result.filename, 'amap_en_ligne_member-7_20260604T120000Z.zip');
    expect(result.downloadTriggered, isTrue);
    expect(result.path, isNull);
  });
}
