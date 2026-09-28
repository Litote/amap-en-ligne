@Tags(['acceptance'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the `acceptance/scenarios` catalog against orphan stories: every
/// scenario targeting `flutter` must be played by a test of this directory,
/// which loads it by id. The server side is guarded by the back
/// `AcceptanceCatalogTest`.
void main() {
  test('every flutter-targeted catalog scenario is played by a test', () {
    final catalog = Directory.fromUri(
      Directory.current.uri.resolve('../acceptance/scenarios/'),
    );
    final flutterIds = <String>[];
    for (final file in catalog.listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final targets = (json['targets']! as List<Object?>).cast<String>();
      if (targets.contains('flutter')) flutterIds.add(json['id']! as String);
    }
    expect(flutterIds, isNotEmpty);

    final testSources = Directory('test/acceptance')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_test.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');
    final orphans = flutterIds
        .where((id) => !testSources.contains("'$id'"))
        .toList();
    expect(
      orphans,
      isEmpty,
      reason: 'Scenarios tagged flutter but loaded by no acceptance test',
    );
  });
}
