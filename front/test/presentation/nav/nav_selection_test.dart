import 'package:amap_en_ligne/presentation/nav/nav_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const routes = [
    '/dashboard',
    '/contracts',
    '/history',
    '/planning',
    '/basket-exchange',
    '/coordinator/time-slots',
    '/coordinator/contracts',
    '/coordinator/member-contracts',
    '/admin/producers',
    '/notifications',
    '/preferences',
  ];

  group('selectedNavRoute', () {
    test('matches the exact route', () {
      expect(selectedNavRoute('/planning', routes), '/planning');
    });

    test('matches a sub-screen under the route', () {
      expect(selectedNavRoute('/history/ranking', routes), '/history');
      expect(
        selectedNavRoute('/basket-exchange/offer-1/requests', routes),
        '/basket-exchange',
      );
      expect(
        selectedNavRoute('/coordinator/time-slots/d-1', routes),
        '/coordinator/time-slots',
      );
    });

    test('does not match a mere text prefix of another segment', () {
      // '/coordinator/contracts' must not select '/contracts', and
      // '/coordinator/member-contracts' must not select the contracts screen.
      expect(
        selectedNavRoute('/coordinator/member-contracts', routes),
        '/coordinator/member-contracts',
      );
      expect(
        selectedNavRoute('/coordinator/contracts', routes),
        '/coordinator/contracts',
      );
    });

    test('attaches delivery sub-screens to Gestion des livraisons', () {
      for (final location in [
        '/coordinator/tracking/d-1',
        '/coordinator/post-delivery/d-1',
        '/coordinator/deliveries/d-1/description',
      ]) {
        expect(
          selectedNavRoute(location, routes),
          '/coordinator/time-slots',
          reason: location,
        );
      }
    });

    test('attaches the producer screens to the producer home', () {
      const producerRoutes = ['/producer-dashboard', '/notifications'];
      for (final location in [
        '/producer-deliveries',
        '/producer-deliveries/org-1/d-1/composition',
        '/product-types',
        '/product-types/pt-1/items',
      ]) {
        expect(
          selectedNavRoute(location, producerRoutes),
          '/producer-dashboard',
          reason: location,
        );
      }
    });

    test('returns null for a screen without menu entry', () {
      expect(selectedNavRoute('/slots', routes), isNull);
      expect(selectedNavRoute(null, routes), isNull);
    });

    test('ignores a trailing slash', () {
      expect(selectedNavRoute('/planning/', routes), '/planning');
    });
  });
}
