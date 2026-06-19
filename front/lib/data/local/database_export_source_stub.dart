import 'dart:typed_data';

import 'package:amap_en_ligne/data/local/database.dart';

Future<Uint8List> exportOpenedDatabaseBytesImpl(AppDatabase db) async {
  throw UnsupportedError('Database export is not supported on this platform.');
}
