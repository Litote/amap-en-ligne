import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Leaves a sub-screen: pops when there is a previous page, otherwise (the
/// screen was opened by its URL: `go`, deep link, page reload) goes to
/// [fallback], its parent screen.
void popOrGo(BuildContext context, String fallback) =>
    context.canPop() ? context.pop() : context.go(fallback);
