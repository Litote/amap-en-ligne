// Which menu entry the current screen belongs to (spec:
// screen-common-01-menu.md — the entry of the displayed screen is
// highlighted, a sub-screen highlights the entry it depends on).

/// Sub-screens whose path does not sit under their menu entry's route,
/// mapped to the route prefix of that entry.
const _kParentRoutes = {
  '/coordinator/tracking': _kDeliveryListRoute,
  '/coordinator/post-delivery': _kDeliveryListRoute,
  '/coordinator/deliveries': _kDeliveryListRoute,
  '/producer-deliveries': _kProducerHomeRoute,
  '/product-types': _kProducerHomeRoute,
};

const _kDeliveryListRoute = '/coordinator/time-slots';
const _kProducerHomeRoute = '/producer-dashboard';

/// Returns the route, among [menuRoutes], of the entry to highlight for
/// [location] (a URI path), or null when the screen has no menu entry.
///
/// A route matches its own path and every path below it (segment-wise:
/// `/coordinator/contracts` never selects `/contracts`); the longest match
/// wins. Sub-screens listed in [_kParentRoutes] are first re-attached to
/// their entry.
String? selectedNavRoute(String? location, Iterable<String> menuRoutes) {
  if (location == null) return null;
  var path = location.length > 1 && location.endsWith('/')
      ? location.substring(0, location.length - 1)
      : location;
  for (final entry in _kParentRoutes.entries) {
    if (_isUnder(path, entry.key)) {
      path = entry.value;
      break;
    }
  }
  String? best;
  for (final route in menuRoutes) {
    if (_isUnder(path, route) && (best == null || route.length > best.length)) {
      best = route;
    }
  }
  return best;
}

bool _isUnder(String path, String route) =>
    path == route || path.startsWith('$route/');
