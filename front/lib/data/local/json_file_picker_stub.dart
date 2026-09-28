import 'package:amap_en_ligne/data/local/json_file_picker.dart';

/// Non-web platforms have no implementation in V1: the import flow is web-only.
Future<PickedJsonFile?> pickJsonFileImpl() =>
    throw UnsupportedError('JSON file import is only supported on the web');
