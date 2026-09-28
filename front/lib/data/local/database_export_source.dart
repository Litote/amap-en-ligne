import 'dart:typed_data';

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/local/database_export_source_stub.dart'
    if (dart.library.js_interop) 'package:amap_en_ligne/data/local/database_export_source_web.dart'
    if (dart.library.io) 'package:amap_en_ligne/data/local/database_export_source_native.dart';

Future<Uint8List> exportOpenedDatabaseBytes(AppDatabase db) =>
    exportOpenedDatabaseBytesImpl(db);
