import 'package:amap_en_ligne/presentation/coordinator/delivery_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Router whose screens render a marker text and expose the navigation
/// helpers as buttons.
GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/coordinator/time-slots',
      builder: (_, _) => const Text('list'),
    ),
    GoRoute(
      path: '/coordinator/tracking/:deliveryId',
      builder: (context, st) => Column(
        children: [
          Text('track:${st.pathParameters['deliveryId']}'),
          TextButton(
            onPressed: () =>
                openPostDelivery(context, st.pathParameters['deliveryId']!),
            child: const Text('close'),
          ),
        ],
      ),
    ),
    GoRoute(
      path: '/coordinator/post-delivery/:deliveryId',
      builder: (context, st) => Column(
        children: [
          Text('post:${st.pathParameters['deliveryId']}'),
          TextButton(
            onPressed: () => backToDeliveryTracking(
              context,
              st.pathParameters['deliveryId']!,
            ),
            child: const Text('back'),
          ),
        ],
      ),
    ),
  ],
);

String? _browserPath(GoRouter router) => router.routeInformationParser
    .restoreRouteInformation(router.routerDelegate.currentConfiguration)
    ?.uri
    .path;

void main() {
  testWidgets('openPostDelivery gives the finalisation screen a real URL', (
    tester,
  ) async {
    final router = _router('/coordinator/tracking/d-1');
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();

    expect(find.text('post:d-1'), findsOneWidget);
    expect(_browserPath(router), '/coordinator/post-delivery/d-1');
  });

  testWidgets(
    'backToDeliveryTracking lands on the same delivery tracking after a '
    'reload or a shared link',
    (tester) async {
      final router = _router('/coordinator/post-delivery/d-1');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();

      expect(find.text('track:d-1'), findsOneWidget);
      expect(_browserPath(router), '/coordinator/tracking/d-1');
    },
  );
}
