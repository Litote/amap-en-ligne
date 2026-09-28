import 'dart:ui';

import 'package:amap_en_ligne/presentation/common/inactive_subtree_focus_guard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fires a view focus event while painting, i.e. mid-frame, after the new
/// subtree is built but before the replaced one is unmounted — what the web
/// engine does when it focuses the semantics node of a freshly shown route.
class _MidFrameViewFocus extends LeafRenderObjectWidget {
  const _MidFrameViewFocus();

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMidFrameViewFocus(View.of(context).viewId);
}

class _RenderMidFrameViewFocus extends RenderBox {
  _RenderMidFrameViewFocus(this._viewId);

  final int _viewId;

  @override
  void performLayout() => size = constraints.constrain(const Size(10, 10));

  @override
  void paint(PaintingContext context, Offset offset) {
    WidgetsBinding.instance.handleViewFocusChanged(
      ViewFocusEvent(
        viewId: _viewId,
        state: ViewFocusState.focused,
        direction: ViewFocusDirection.forward,
      ),
    );
  }
}

Widget _keyedApp(int generation, {required bool guarded}) {
  final Widget content = Column(
    children: [
      Focus(child: SizedBox(width: 10, height: 10, key: ValueKey(generation))),
      if (generation > 0) const _MidFrameViewFocus(),
    ],
  );
  return KeyedSubtree(
    key: ValueKey(generation),
    child: guarded ? InactiveSubtreeFocusGuard(child: content) : content,
  );
}

void main() {
  testWidgets(
    'unguarded: a mid-frame view focus crashes on the replaced subtree',
    (tester) async {
      await tester.pumpWidget(_keyedApp(0, guarded: false));
      await tester.pumpWidget(_keyedApp(1, guarded: false));

      // Documents the framework behaviour the guard works around.
      expect(tester.takeException(), isNotNull);
    },
  );

  testWidgets('guarded: a mid-frame view focus ignores the replaced subtree', (
    tester,
  ) async {
    await tester.pumpWidget(_keyedApp(0, guarded: true));
    await tester.pumpWidget(_keyedApp(1, guarded: true));

    expect(tester.takeException(), isNull);
  });

  testWidgets('guarded subtree stays focusable while mounted', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      InactiveSubtreeFocusGuard(
        child: Focus(focusNode: node, child: const SizedBox()),
      ),
    );

    node.requestFocus();
    await tester.pump();

    expect(node.hasPrimaryFocus, isTrue);
  });
}
