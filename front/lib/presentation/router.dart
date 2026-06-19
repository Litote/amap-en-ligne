import 'dart:async';

import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/presentation/activation/activation_screen.dart';
import 'package:amap_en_ligne/presentation/admin/admin_requests_screen.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_screen.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_history_screen.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_overview_screen.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/received_requests_screen.dart';
import 'package:amap_en_ligne/presentation/admin/delivery_templates/delivery_template_form_screen.dart';
import 'package:amap_en_ligne/presentation/admin/delivery_templates/delivery_template_list_screen.dart';
import 'package:amap_en_ligne/presentation/admin/producers/enroll_producer_screen.dart';
import 'package:amap_en_ligne/presentation/admin/producers/producer_detail_screen.dart';
import 'package:amap_en_ligne/presentation/admin/producers/producer_list_screen.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/auth/forgot_password_screen.dart';
import 'package:amap_en_ligne/presentation/auth/login_screen.dart';
import 'package:amap_en_ligne/presentation/auth/reset_password_screen.dart';
import 'package:amap_en_ligne/presentation/admin/members/user_management_screen.dart';
import 'package:amap_en_ligne/data/auth/jwt_claims.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/presentation/common/placeholder_screen.dart';
import 'package:amap_en_ligne/presentation/common/alert_templates_bloc.dart';
import 'package:amap_en_ligne/presentation/common/user_preferences_bloc.dart';
import 'package:amap_en_ligne/presentation/common/user_preferences_screen.dart';
import 'package:amap_en_ligne/presentation/notifications/notification_inbox_screen.dart';
import 'package:amap_en_ligne/presentation/coordinator/attendance/attendance_sheets_screen.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_contracts_screen.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_member_contracts_screen.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_delivery_tracking_screen.dart';
import 'package:amap_en_ligne/presentation/coordinator/time_slots/time_slot_form_screen.dart';
import 'package:amap_en_ligne/presentation/coordinator/time_slots/time_slots_screen.dart';
import 'package:amap_en_ligne/presentation/amap_search/amap_search_screen.dart';
import 'package:amap_en_ligne/presentation/dashboard/mixed_dashboard_screen.dart';
import 'package:amap_en_ligne/presentation/home/home_screen.dart';
import 'package:amap_en_ligne/presentation/member/member_contracts_screen.dart';
import 'package:amap_en_ligne/presentation/member/member_delivery_plan_screen.dart';
import 'package:amap_en_ligne/presentation/member/member_history_screen.dart';
import 'package:amap_en_ligne/presentation/member/member_ranking_screen.dart';
import 'package:amap_en_ligne/presentation/nav/app_shell_layout.dart';
import 'package:amap_en_ligne/presentation/admin/membership_requests/membership_requests_screen.dart';
import 'package:amap_en_ligne/presentation/organization/organization_creation_screen.dart';
import 'package:amap_en_ligne/presentation/owner/invite_owner/invite_owner_screen.dart';
import 'package:amap_en_ligne/presentation/owner/owner_dashboard_screen.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_list_screen.dart';
import 'package:amap_en_ligne/presentation/producer/producer_dashboard_screen.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_screen.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_screen.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_screen.dart';
import 'package:amap_en_ligne/presentation/product_types/product_type_form_screen.dart';
import 'package:amap_en_ligne/presentation/product_types/product_types_screen.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Decodes the `email` query parameter from [uri] without treating `+` as a
/// space. Dart's `Uri.queryParameters` uses HTML form decoding where `+` means
/// space — safe for most parameters, but email addresses legitimately contain
/// `+` (e.g. `user+tag@example.com`). This helper uses `Uri.decodeComponent`
/// which only decodes `%XX` sequences, leaving `+` as a literal `+`.
@visibleForTesting
String? decodeEmailQueryParam(Uri uri) {
  for (final part in uri.query.split('&')) {
    final eqIdx = part.indexOf('=');
    if (eqIdx == -1) continue;
    if (Uri.decodeComponent(part.substring(0, eqIdx)) == 'email') {
      return Uri.decodeComponent(part.substring(eqIdx + 1));
    }
  }
  return null;
}

const _kLoginRoute = '/login';
const _kActivateRoute = '/activate';
const _kResetPasswordRoute = '/reset-password';
const _kProductTypesRoute = '/product-types';

const _publicRoutes = {
  _kLoginRoute,
  '/register',
  '/register/producer',
  '/amap-search',
  '/forgot-password',
  _kActivateRoute,
  _kResetPasswordRoute,
};

/// Computes the redirect target given the current [location] and auth state.
///
/// When [role] is provided it drives the post-login landing page; otherwise
/// the legacy [isAdmin] flag is used for backward compatibility.
///
/// Exposed for unit testing via [@visibleForTesting].
@visibleForTesting
String? computeRouterRedirect(
  Uri uri,
  String? producerAccountId, {
  bool isAdmin = false,
  UserRole? role,
  bool logoutRequested = false,
  bool initializing = false,
}) {
  // Wait for the auth bootstrap to settle before deciding. Without this the
  // very first redirect runs with `producerAccountId == null` and bounces an
  // already-authenticated user to `/login` on every page reload (F5).
  if (initializing) return null;

  final location = uri.path;

  final ownerGuard = _ownerGuardRedirect(
    uri,
    location,
    producerAccountId,
    role,
  );
  if (ownerGuard != null) return ownerGuard;

  if (producerAccountId != null) {
    return _authenticatedRedirect(uri, location, role: role, isAdmin: isAdmin);
  }

  // Unauthenticated: force login for any non-public route.
  if (!_publicRoutes.contains(location) && location != '/') {
    if (logoutRequested) return _kLoginRoute;
    return '/login?from=${Uri.encodeQueryComponent(uri.toString())}';
  }
  return null;
}

/// OWNER route guard: redirects when an /owner/* route is accessed without the
/// owner role (or unauthenticated).
String? _ownerGuardRedirect(
  Uri uri,
  String location,
  String? producerAccountId,
  UserRole? role,
) {
  final isOwnerRoute =
      location.startsWith('/owner/users') ||
      location == '/owner/invite-administrator';
  if (!isOwnerRoute) return null;
  if (producerAccountId == null) {
    return '/login?from=${Uri.encodeQueryComponent(uri.toString())}';
  }
  if (role != UserRole.owner) return _kLoginRoute;
  return null;
}

/// Redirect for an already-authenticated user: honour a `from` intent on the
/// login page, then bounce public/root routes to the role landing page.
String? _authenticatedRedirect(
  Uri uri,
  String location, {
  UserRole? role,
  bool isAdmin = false,
}) {
  if (location == _kLoginRoute) {
    final requested = _decodeRequestedRoute(uri.queryParameters['from']);
    if (requested != null) return requested;
  }
  if (location == '/' ||
      (_publicRoutes.contains(location) &&
          location != _kActivateRoute &&
          location != _kResetPasswordRoute)) {
    return _landingRouteFor(role: role, isAdmin: isAdmin);
  }
  return null;
}

/// Returns the landing route after a successful login, based on [role].
///
/// Falls back to [isAdmin] when [role] is null (backward-compatible path).
String _landingRouteFor({required UserRole? role, required bool isAdmin}) {
  return switch (role) {
    UserRole.owner => '/owner/dashboard',
    UserRole.producer => _kProductTypesRoute,
    UserRole.admin ||
    UserRole.coordinator ||
    UserRole.volunteer ||
    UserRole.memberNoRole => '/dashboard',
    null => isAdmin ? '/admin/organization-requests' : _kProductTypesRoute,
  };
}

/// Builds the app router. The `authBloc` instance drives both the redirect
/// logic and the protected-route screens (the screens read
/// `state.producerId` from it as their tenant id).
GoRouter buildRouter({required AuthBloc authBloc}) {
  final listenable = _AuthBlocListenable(authBloc);
  return GoRouter(
    refreshListenable: listenable,
    redirect: (context, state) => computeRouterRedirect(
      state.uri,
      authBloc.state.producerId,
      isAdmin: authBloc.state.isAdmin,
      role: authBloc.state.role,
      logoutRequested: authBloc.state.logoutRequested,
      initializing: authBloc.state.initializing,
    ),
    routes: [
      // Public routes — no shell wrapper.
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: _kLoginRoute,
        builder: (_, state) =>
            LoginScreen(initialEmail: decodeEmailQueryParam(state.uri)),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const OrganizationCreationScreen(),
      ),
      GoRoute(
        path: '/register/producer',
        builder: (_, state) {
          final prefill = state.extra as Map<String, String?>?;
          return ProducerRequestScreen(
            initialFirstName: prefill?['firstName'],
            initialLastName: prefill?['lastName'],
            initialEmail: prefill?['email'],
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, state) =>
            ForgotPasswordScreen(initialEmail: state.extra as String?),
      ),
      GoRoute(
        path: _kActivateRoute,
        builder: (_, state) =>
            ActivationScreen(token: state.uri.queryParameters['token'] ?? ''),
      ),
      GoRoute(
        path: _kResetPasswordRoute,
        builder: (_, _) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/amap-search',
        builder: (_, state) {
          final orgId = state.uri.queryParameters['organizationId'];
          return AmapSearchScreen(preselectedOrganizationId: orgId);
        },
      ),
      // Authenticated routes — wrapped in AppShellLayout which provides
      // NavBloc and the responsive navigation chrome.
      ShellRoute(
        builder: (context, state, child) => AppShellLayout(child: child),
        routes: [
          GoRoute(
            path: _kProductTypesRoute,
            builder: (_, _) =>
                ProductTypesScreen(tenantId: _requireTenant(authBloc)),
          ),
          GoRoute(
            path: '/product-types/new',
            builder: (_, _) =>
                ProductTypeFormScreen(tenantId: _requireTenant(authBloc)),
          ),
          GoRoute(
            path: '/product-types/:id',
            builder: (_, st) => ProductTypeFormScreen(
              tenantId: _requireTenant(authBloc),
              productTypeId: st.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: '/product-types/:productTypeId/items',
            builder: (_, st) =>
                ItemTypesScreen(productType: st.extra as ProductType),
          ),
          GoRoute(
            path: '/product-types/deliveries/:deliveryId/description',
            builder: (_, st) => DeliveryDescriptionScreen(
              org: st.extra as Organization,
              deliveryId: st.pathParameters['deliveryId']!,
            ),
          ),
          GoRoute(
            path: '/admin/organization-requests',
            builder: (_, _) => const AdminRequestsScreen(),
          ),
          GoRoute(
            path: '/admin/producers',
            builder: (_, state) =>
                ProducerListScreen(organizationId: _requireTenant(authBloc)),
          ),
          // Keep the static sub-route before `:producerAccountId`; otherwise
          // `/admin/producers/enroll` is interpreted as a detail page for the
          // producer id `enroll`.
          GoRoute(
            path: '/admin/producers/enroll',
            builder: (_, state) =>
                EnrollProducerScreen(organizationId: _requireTenant(authBloc)),
          ),
          GoRoute(
            path: '/admin/producers/:producerAccountId',
            builder: (_, state) => ProducerDetailScreen(
              organizationId: _requireTenant(authBloc),
              producerAccountId: state.pathParameters['producerAccountId']!,
            ),
          ),
          GoRoute(
            path: '/admin/delivery-templates',
            builder: (_, _) => DeliveryTemplateListScreen(
              organizationId: _requireTenant(authBloc),
            ),
          ),
          GoRoute(
            path: '/admin/delivery-templates/new',
            builder: (_, _) => DeliveryTemplateFormScreen(
              organizationId: _requireTenant(authBloc),
            ),
          ),
          GoRoute(
            path: '/admin/delivery-templates/:id',
            builder: (_, state) => DeliveryTemplateFormScreen(
              organizationId: _requireTenant(authBloc),
              template: state.extra as DeliveryTemplate?,
            ),
          ),
          // Role-based dashboards.
          GoRoute(
            path: '/owner/dashboard',
            builder: (_, _) => const OwnerDashboardScreen(),
          ),
          GoRoute(
            path: '/owner/users',
            builder: (_, _) => const UserListScreen(),
          ),
          GoRoute(
            path: '/owner/invite-administrator',
            builder: (_, _) => const InviteOwnerScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (_, _) =>
                MixedDashboardScreen(tenantId: _requireTenant(authBloc)),
          ),
          // Placeholder routes referenced by nav items but not yet implemented.
          GoRoute(
            path: '/contracts',
            builder: (_, _) =>
                MemberContractsScreen(tenantId: _requireTenant(authBloc)),
          ),
          GoRoute(
            path: '/planning',
            builder: (_, _) =>
                MemberDeliveryPlanScreen(tenantId: _requireTenant(authBloc)),
          ),
          GoRoute(
            path: '/history',
            builder: (_, _) =>
                MemberHistoryScreen(tenantId: _requireTenant(authBloc)),
          ),
          GoRoute(
            path: '/history/ranking',
            builder: (_, _) =>
                MemberRankingScreen(tenantId: _requireTenant(authBloc)),
          ),
          // Basket-exchange routes — keep static sub-routes before the
          // parametric `:offerId` route so `/basket-exchange/history` is not
          // interpreted as the requests screen for offerId="history".
          GoRoute(
            path: '/basket-exchange/history',
            builder: (context, _) => BasketExchangeHistoryScreen(
              orgId: _requireTenant(authBloc),
              memberId: _resolveSub(context),
            ),
          ),
          GoRoute(
            path: '/basket-exchange/overview',
            builder: (_, _) =>
                BasketExchangeOverviewScreen(orgId: _requireTenant(authBloc)),
          ),
          GoRoute(
            path: '/basket-exchange/:offerId/requests',
            builder: (_, state) => ReceivedRequestsScreen(
              orgId: _requireTenant(authBloc),
              offerId: state.pathParameters['offerId']!,
            ),
          ),
          GoRoute(
            path: '/basket-exchange',
            builder: (_, _) =>
                BasketExchangeScreen(tenantId: _requireTenant(authBloc)),
          ),
          GoRoute(
            path: '/slots',
            builder: (_, _) =>
                TimeSlotsScreen(tenantId: _requireTenant(authBloc)),
          ),
          GoRoute(
            path: '/coordinator/contracts',
            builder: (_, _) =>
                CoordinatorContractsScreen(tenantId: _requireTenant(authBloc)),
          ),
          GoRoute(
            path: '/coordinator/member-contracts',
            builder: (_, _) => CoordinatorMemberContractsScreen(
              tenantId: _requireTenant(authBloc),
            ),
          ),
          GoRoute(
            path: '/coordinator/time-slots',
            builder: (_, _) =>
                TimeSlotsScreen(tenantId: _requireTenant(authBloc)),
          ),
          GoRoute(
            path: '/coordinator/time-slots/new',
            builder: (_, _) =>
                TimeSlotFormScreen(tenantId: _requireTenant(authBloc)),
          ),
          GoRoute(
            path: '/coordinator/time-slots/:deliveryId',
            builder: (_, st) => TimeSlotFormScreen(
              tenantId: _requireTenant(authBloc),
              deliveryId: st.pathParameters['deliveryId'],
            ),
          ),
          GoRoute(
            path: '/coordinator/attendance',
            builder: (_, _) =>
                AttendanceSheetsScreen(tenantId: _requireTenant(authBloc)),
          ),
          GoRoute(
            path: '/coordinator/tracking/:deliveryId',
            builder: (_, st) => CoordinatorDeliveryTrackingScreen(
              tenantId: _requireTenant(authBloc),
              deliveryId: st.pathParameters['deliveryId'] ?? '',
            ),
          ),
          GoRoute(
            path: '/coordinator/deliveries/:deliveryId/description',
            builder: (_, st) => DeliveryDescriptionScreen(
              org: st.extra as Organization,
              deliveryId: st.pathParameters['deliveryId']!,
            ),
          ),
          GoRoute(
            path: '/members',
            builder: (_, _) => UserManagementScreen(
              organizationId: _requireTenant(authBloc),
              canEditAdminRole: authBloc.state.isAdmin,
            ),
          ),
          GoRoute(
            path: '/admin/membership-requests',
            builder: (_, _) => MembershipRequestsScreen(
              organizationId: _requireTenant(authBloc),
            ),
          ),
          GoRoute(
            path: '/admin/producer-requests',
            builder: (_, state) => ProducerRequestsScreen(
              initialRequest: state.extra as AdminProducerRequest?,
            ),
          ),
          GoRoute(
            path: '/admin/organization-config',
            builder: (_, _) => const PlaceholderScreen(
              title: "Configuration de l'organisation",
            ),
          ),
          GoRoute(
            path: '/producer-dashboard',
            builder: (_, _) =>
                ProducerDashboardScreen(tenantId: _requireTenant(authBloc)),
          ),
          GoRoute(
            path: '/producer-deliveries',
            builder: (_, _) => const PlaceholderScreen(title: 'Mes livraisons'),
          ),
          GoRoute(
            path: '/preferences',
            builder: (context, _) {
              final sub = _resolveSub(context);
              final role = authBloc.state.role;
              final UserPreferencesSource source;
              if (role == UserRole.owner) {
                source = OwnerSource(
                  ownerId: sub,
                  ownerRepository: context.read<OwnerRepository>(),
                );
              } else if (role == UserRole.producer) {
                source = ProducerSource(
                  producerAccountId: authBloc.state.producerId ?? '',
                  producerAccountRepository: context
                      .read<ProducerAccountRepository>(),
                );
              } else {
                source = MemberSource(
                  memberId: sub,
                  memberRepository: context.read<MemberRepository>(),
                );
              }
              // Org admins get an extra card to customise alert message copy,
              // backed by a dedicated AlertTemplatesBloc on the org scope.
              final isOrgAdmin = role == UserRole.admin;
              if (isOrgAdmin) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => UserPreferencesBloc(source: source),
                    ),
                    BlocProvider(
                      create: (_) => AlertTemplatesBloc(
                        organizationRepository: context
                            .read<OrganizationRepository>(),
                        tenantId: _requireTenant(authBloc),
                      ),
                    ),
                  ],
                  child: UserPreferencesScreen(
                    showAlertTemplates: true,
                    backupOrganizationId: _requireTenant(authBloc),
                  ),
                );
              }
              return BlocProvider(
                create: (_) => UserPreferencesBloc(source: source),
                child: const UserPreferencesScreen(),
              );
            },
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, _) =>
                NotificationInboxScreen(memberId: _resolveSub(context)),
          ),
          GoRoute(
            path: '/help',
            builder: (_, _) => const PlaceholderScreen(title: 'Aide'),
          ),
        ],
      ),
    ],
  );
}

/// Resolves the current user's `sub` claim from the active session.
///
/// Reads `AuthService.currentState` synchronously (the token was already
/// validated by the server on sign-in). Falls back to the empty string if the
/// session is not yet authenticated — the router redirect will bounce the user
/// to `/login` before this builder is reached in normal flow.
String _resolveSub(BuildContext context) {
  final authService = context.read<AuthService>();
  final state = authService.currentState;
  if (state is! Authenticated) return '';
  try {
    final claims = JwtClaims.decode(state.accessToken);
    return claims.string('sub') ?? '';
  } catch (_) {
    return '';
  }
}

String? _decodeRequestedRoute(String? encodedTarget) {
  if (encodedTarget == null || encodedTarget.isEmpty) return null;
  final parsed = Uri.tryParse(encodedTarget);
  if (parsed == null) return null;
  final location = parsed.path;
  if (location.isEmpty || _publicRoutes.contains(location) || location == '/') {
    return null;
  }
  return parsed.toString();
}

String _requireTenant(AuthBloc bloc) {
  final state = bloc.state;
  final id = state.organizationId ?? state.producerId;
  if (id == null) {
    // The redirect above prevents this branch in normal flow, but a
    // mid-navigation logout can race a builder — return a sentinel that
    // the StreamBuilder will treat as "no rows" until the redirect fires.
    return '';
  }
  return id;
}

/// Adapts an `AuthBloc` into a `Listenable` consumable by go_router's
/// `refreshListenable`. Notifies on every state change and is disposed via
/// the bloc's lifecycle (we never recreate the router so we never need to
/// dispose this manually within the app).
class _AuthBlocListenable extends ChangeNotifier {
  _AuthBlocListenable(AuthBloc bloc) {
    _sub = bloc.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthViewState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
