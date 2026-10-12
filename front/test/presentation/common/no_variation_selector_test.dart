import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Flutter web finds no Noto fallback font for the invisible emoji variation
/// selector U+FE0F (as in « ⚠️ »), and logs « Could not find a set of Noto fonts
/// to display all missing characters » on every page showing one. The emoji
/// renders the same without it, so the UI copy must not carry it.
void main() {
  test('no UI copy carries the U+FE0F emoji variation selector', () {
    final offenders = <String>[
      for (final entity in Directory('lib').listSync(recursive: true))
        if (entity is File &&
            entity.path.endsWith('.dart') &&
            entity.readAsStringSync().contains('️'))
          entity.path,
    ];

    expect(offenders, isEmpty);
  });
}
