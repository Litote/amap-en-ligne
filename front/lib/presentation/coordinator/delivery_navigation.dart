import 'package:amap_en_ligne/presentation/common/french_date_formatting.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Leaves a delivery sub-screen (form, tracking, post-delivery): pops when
/// there is a previous page, otherwise (deep link, page reload) lands on the
/// coordinator delivery list.
void backToDeliveryList(BuildContext context) =>
    context.canPop() ? context.pop() : context.go('/coordinator/time-slots');

/// Opens the live tracking of a delivery. Uses `go` (not `push`) so the
/// browser URL reflects the screen: a page reload or a shared link reopens it.
void openDeliveryTracking(BuildContext context, String deliveryId) =>
    context.go('/coordinator/tracking/$deliveryId');

/// Opens the post-delivery finalisation screen, with a real URL (see
/// [openDeliveryTracking]).
void openPostDelivery(BuildContext context, String deliveryId) =>
    context.go('/coordinator/post-delivery/$deliveryId');

/// Leaves the post-delivery screen: pops when there is a previous page,
/// otherwise lands on the tracking of the same delivery.
void backToDeliveryTracking(BuildContext context, String deliveryId) =>
    context.canPop()
    ? context.pop()
    : openDeliveryTracking(context, deliveryId);

/// "La distribution pourra être clôturée à partir du jeudi 1 octobre."
String closableFromLabel(String scheduledDate) =>
    'La distribution pourra être clôturée à partir du '
    '${frenchDateFormat('EEEE d MMMM').format(DateTime.parse(scheduledDate))}.';

/// "Les présences et la collecte pourront être saisies à partir du jeudi
/// 1 octobre."
String recordableFromLabel(String scheduledDate) =>
    'Les présences et la collecte pourront être saisies à partir du '
    '${frenchDateFormat('EEEE d MMMM').format(DateTime.parse(scheduledDate))}.';
