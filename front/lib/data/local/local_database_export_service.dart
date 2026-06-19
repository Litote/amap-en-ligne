import 'dart:typed_data';

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/local/database_constants.dart';
import 'package:amap_en_ligne/data/local/database_export_save.dart';
import 'package:amap_en_ligne/data/local/database_export_source.dart';
import 'package:archive/archive.dart';

typedef DatabaseBytesExporter = Future<Uint8List> Function(AppDatabase db);
typedef DatabaseExportFileSaver =
    Future<DatabaseExportResult> Function({
      required String filename,
      required Uint8List bytes,
      required String mimeType,
    });

class LocalDatabaseExportService {
  LocalDatabaseExportService({
    required AppDatabase db,
    DatabaseBytesExporter? exportDatabaseBytes,
    DatabaseExportFileSaver? saveFile,
    DateTime Function()? now,
  }) : _db = db,
       _exportDatabaseBytes = exportDatabaseBytes ?? exportOpenedDatabaseBytes,
       _saveFile = saveFile ?? saveDatabaseExportFile,
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DatabaseBytesExporter _exportDatabaseBytes;
  final DatabaseExportFileSaver _saveFile;
  final DateTime Function() _now;

  Future<DatabaseExportResult> exportCurrentUserDatabase({
    required String userId,
  }) async {
    final rawBytes = await _exportDatabaseBytes(_db);
    final filename = _buildFilename(userId, _now().toUtc());
    final zipBytes = _buildZip(rawBytes);
    return _saveFile(
      filename: filename,
      bytes: zipBytes,
      mimeType: 'application/zip',
    );
  }

  Uint8List _buildZip(Uint8List databaseBytes) {
    final archive = Archive()
      ..add(ArchiveFile.bytes(appDatabaseFileName, databaseBytes));
    return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
  }

  String _buildFilename(String userId, DateTime instant) {
    final safeUserId = userId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final timestamp = _formatTimestamp(instant);
    return '${appDatabaseName}_${safeUserId}_$timestamp.zip';
  }

  String _formatTimestamp(DateTime instant) {
    final month = instant.month.toString().padLeft(2, '0');
    final day = instant.day.toString().padLeft(2, '0');
    final hour = instant.hour.toString().padLeft(2, '0');
    final minute = instant.minute.toString().padLeft(2, '0');
    final second = instant.second.toString().padLeft(2, '0');
    return '${instant.year}$month${day}T$hour$minute${second}Z';
  }
}
