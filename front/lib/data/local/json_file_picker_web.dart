import 'dart:async';
import 'dart:js_interop';

import 'package:amap_en_ligne/data/local/json_file_picker.dart';
import 'package:web/web.dart' as web;

/// Web implementation: drives a hidden `<input type="file">` and reads the
/// selected file as text via a [web.FileReader].
Future<PickedJsonFile?> pickJsonFileImpl() {
  final completer = Completer<PickedJsonFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.json,application/json'
    ..style.display = 'none';

  void finish(PickedJsonFile? result) {
    if (!completer.isCompleted) completer.complete(result);
    input.remove();
  }

  input.onchange = (web.Event _) {
    final files = input.files;
    if (files == null || files.length == 0) {
      finish(null);
      return;
    }
    final file = files.item(0);
    if (file == null) {
      finish(null);
      return;
    }
    final reader = web.FileReader();
    reader.onload = (web.Event _) {
      final text = (reader.result as JSString?)?.toDart ?? '';
      finish(PickedJsonFile(filename: file.name, content: text));
    }.toJS;
    reader.onerror = (web.Event _) {
      finish(null);
    }.toJS;
    reader.readAsText(file);
  }.toJS;

  // A cancelled chooser fires no event on most browsers; the future then stays
  // pending until the next pick. That is acceptable for a one-shot admin action.
  web.document.body?.append(input);
  input.click();
  return completer.future;
}
