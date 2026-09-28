import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Leaves a delivery sub-screen (form, tracking, post-delivery): pops when
/// there is a previous page, otherwise (deep link, page reload) lands on the
/// coordinator delivery list.
void backToDeliveryList(BuildContext context) =>
    context.canPop() ? context.pop() : context.go('/coordinator/time-slots');
