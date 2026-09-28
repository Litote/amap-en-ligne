import 'package:flutter/widgets.dart';

/// Keeps a replaced subtree out of focus traversal until it is unmounted.
///
/// On web, the engine may move DOM focus mid-frame (it focuses the semantics
/// node of a freshly shown route), which runs a view focus traversal before
/// the frame unmounts the elements it deactivated. When a whole keyed subtree
/// is swapped — the app shell on a tenant change — its focus nodes are still
/// registered but their render objects are detached, and sorting them throws
/// (`Null check operator used on a null value` in `getTransformTo`).
///
/// Wrapping the subtree in a scope that stops accepting focus on deactivation
/// hides all of it from the traversal: descendant scopes are never expanded
/// and a scope that cannot request focus is skipped.
class InactiveSubtreeFocusGuard extends StatefulWidget {
  const InactiveSubtreeFocusGuard({required this.child, super.key});

  final Widget child;

  @override
  State<InactiveSubtreeFocusGuard> createState() =>
      _InactiveSubtreeFocusGuardState();
}

class _InactiveSubtreeFocusGuardState extends State<InactiveSubtreeFocusGuard> {
  final FocusScopeNode _scope = FocusScopeNode(
    debugLabel: 'InactiveSubtreeFocusGuard',
  );

  @override
  void activate() {
    super.activate();
    _scope.canRequestFocus = true;
  }

  @override
  void deactivate() {
    _scope.canRequestFocus = false;
    super.deactivate();
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FocusScope(node: _scope, child: widget.child);
}
