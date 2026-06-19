import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:amap_en_ligne/data/local/database_constants.dart';
import 'package:path_provider/path_provider.dart';

QueryExecutor openDatabaseExecutor() => driftDatabase(
  name: appDatabaseName,
  native: const DriftNativeOptions(
    databaseDirectory: getApplicationSupportDirectory,
  ),
);
