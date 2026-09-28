import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final coordinators = [
    const Member(memberId: 'm-1', organizationId: 'org-1', firstName: 'Alice'),
    const Member(memberId: 'm-2', organizationId: 'org-1', firstName: 'Bob'),
  ];

  Widget buildHost({
    required GlobalKey<CoordinatorSelectorState> selectorKey,
    required Set<String> Function() initialIds,
    required void Function(StateSetter) onHostReady,
  }) => MaterialApp(
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) {
          onHostReady(setState);
          return CoordinatorSelector(
            key: selectorKey,
            coordinators: coordinators,
            saving: false,
            // A fresh (but equal) Set on every parent build, like the
            // contract form does with `{...?selectedContract?.coordinators}`.
            initialCoordinatorIds: initialIds(),
          );
        },
      ),
    ),
  );

  testWidgets(
    'keeps the user selection when the parent rebuilds with equal initial ids',
    (tester) async {
      final selectorKey = GlobalKey<CoordinatorSelectorState>();
      late StateSetter rebuildHost;
      await tester.pumpWidget(
        buildHost(
          selectorKey: selectorKey,
          initialIds: () => <String>{},
          onHostReady: (setState) => rebuildHost = setState,
        ),
      );

      await tester.tap(find.text('Alice'));
      await tester.pump();
      expect(selectorKey.currentState!.getSelectedCoordinators(), {'m-1'});

      // Unrelated parent rebuild (e.g. ticking a member basket).
      rebuildHost(() {});
      await tester.pump();

      expect(selectorKey.currentState!.getSelectedCoordinators(), {'m-1'});
    },
  );

  testWidgets('resets the selection when the initial ids actually change', (
    tester,
  ) async {
    final selectorKey = GlobalKey<CoordinatorSelectorState>();
    late StateSetter rebuildHost;
    var initial = <String>{'m-1'};
    await tester.pumpWidget(
      buildHost(
        selectorKey: selectorKey,
        initialIds: () => {...initial},
        onHostReady: (setState) => rebuildHost = setState,
      ),
    );
    expect(selectorKey.currentState!.getSelectedCoordinators(), {'m-1'});

    // Another contract is selected in the list.
    rebuildHost(() => initial = {'m-2'});
    await tester.pump();

    expect(selectorKey.currentState!.getSelectedCoordinators(), {'m-2'});
  });
}
