import 'dart:async';

import 'package:amap_en_ligne/data/auth/jwt_claims.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/domain/model/admin_producer_request.dart';
import 'package:amap_en_ligne/domain/model/delivery_template.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/domain/model/product_type.dart';
import 'package:amap_en_ligne/presentation/activation/activation_screen.dart';
import 'package:amap_en_ligne/presentation/admin/admin_requests_screen.dart';
import 'package:amap_en_ligne/presentation/admin/delivery_templates/delivery_template_form_screen.dart';
import 'package:amap_en_ligne/presentation/admin/delivery_templates/delivery_template_list_screen.dart';
import 'package:amap_en_ligne/presentation/admin/members/user_management_screen.dart';
import 'package:amap_en_ligne/presentation/admin/membership_requests/membership_requests_screen.dart';
import 'package:amap_en_ligne/presentation/admin/organization_config_screen.dart';
import 'package:amap_en_ligne/presentation/admin/producer_requests/producer_requests_screen.dart';
import 'package:amap_en_ligne/presentation/admin/producers/enroll_producer_screen.dart';
import 'package:amap_en_ligne/presentation/admin/producers/producer_detail_screen.dart';
import 'package:amap_en_ligne/presentation/admin/producers/producer_list_screen.dart';
import 'package:amap_en_ligne/presentation/amap_search/amap_search_screen.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/auth/forgot_password_screen.dart';
import 'package:amap_en_ligne/presentation/auth/login_screen.dart';
import 'package:amap_en_ligne/presentation/auth/reset_password_screen.dart';
import 'package:amap_en_ligne/presentation/common/alert_templates_bloc.dart';
import 'package:amap_en_ligne/presentation/common/error_feedback.dart';
import 'package:amap_en_ligne/presentation/common/not_found_screen.dart';
import 'package:amap_en_ligne/presentation/common/user_preferences_bloc.dart';
import 'package:amap_en_ligne/presentation/common/user_preferences_screen.dart';
import 'package:amap_en_ligne/presentation/coordinator/attendance/attendance_sheets_screen.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_contracts_screen.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_delivery_tracking_screen.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_member_contracts_screen.dart';
import 'package:amap_en_ligne/presentation/coordinator/coordinator_post_delivery_sync_screen.dart';
import 'package:amap_en_ligne/presentation/coordinator/time_slots/time_slot_form_screen.dart';
import 'package:amap_en_ligne/presentation/coordinator/time_slots/time_slots_screen.dart';
import 'package:amap_en_ligne/presentation/dashboard/mixed_dashboard_screen.dart';
import 'package:amap_en_ligne/presentation/delivery_description/delivery_description_screen.dart';
import 'package:amap_en_ligne/presentation/help/help_screen.dart';
import 'package:amap_en_ligne/presentation/home/home_screen.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_history_screen.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_overview_screen.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/basket_exchange_screen.dart';
import 'package:amap_en_ligne/presentation/member/basket_exchange/received_requests_screen.dart';
import 'package:amap_en_ligne/presentation/member/member_contracts_screen.dart';
import 'package:amap_en_ligne/presentation/member/member_delivery_plan_screen.dart';
import 'package:amap_en_ligne/presentation/member/member_history_screen.dart';
import 'package:amap_en_ligne/presentation/member/member_ranking_screen.dart';
import 'package:amap_en_ligne/presentation/nav/app_shell_layout.dart';
import 'package:amap_en_ligne/presentation/notifications/notification_inbox_screen.dart';
import 'package:amap_en_ligne/presentation/organization/organization_creation_screen.dart';
import 'package:amap_en_ligne/presentation/owner/invite_owner/invite_owner_screen.dart';
import 'package:amap_en_ligne/presentation/owner/owner_dashboard_screen.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_list_screen.dart';
import 'package:amap_en_ligne/presentation/producer/producer_dashboard_screen.dart';
import 'package:amap_en_ligne/presentation/producer/producer_deliveries_screen.dart';
import 'package:amap_en_ligne/presentation/producer/producer_delivery_composition_screen.dart';
import 'package:amap_en_ligne/presentation/producer_request/producer_request_screen.dart';
import 'package:amap_en_ligne/presentation/product_types/item_types/item_types_screen.dart';
import 'package:amap_en_ligne/presentation/product_types/product_type_form_screen.dart';
import 'package:amap_en_ligne/presentation/product_types/product_types_screen.dart';
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
const _kOrganizationRequestsRoute = '/admin/organization-requests';
const _kProducerDashboardRoute = '/producer-dashboard';
const _kDashboardRoute = '/dashboard';

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
  Set<Role> memberRoles = const {},
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
    return _authenticatedRedirect(
          uri,
          location,
          role: role,
          isAdmin: isAdmin,
        ) ??
        _roleGuardRedirect(location, role: role, memberRoles: memberRoles);
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

/// Who a screen is meant for; mirrors the navigation menu of each role
/// (spec screen-common-01-menu).
enum _RouteAudience { member, coordinator, admin, owner, producer }

bool _isUnder(String location, String prefix) =>
    location == prefix || location.startsWith('$prefix/');

_RouteAudience? _audienceOf(String location) {
  if (_isUnder(location, '/owner') ||
      _isUnder(location, _kOrganizationRequestsRoute) ||
      _isUnder(location, '/admin/producer-requests')) {
    return _RouteAudience.owner;
  }
  if (_isUnder(location, '/admin') || _isUnder(location, '/members')) {
    return _RouteAudience.admin;
  }
  if (_isUnder(location, '/coordinator') || _isUnder(location, '/slots')) {
    return _RouteAudience.coordinator;
  }
  if (_isUnder(location, _kProducerDashboardRoute) ||
      _isUnder(location, '/producer-deliveries') ||
      _isUnder(location, '/product-types')) {
    return _RouteAudience.producer;
  }
  if (_isUnder(location, _kDashboardRoute) ||
      _isUnder(location, '/contracts') ||
      _isUnder(location, '/planning') ||
      _isUnder(location, '/history') ||
      _isUnder(location, '/basket-exchange')) {
    return _RouteAudience.member;
  }
  // Common screens (notifications, preferences, help…) and public routes.
  return null;
}

/// Sends an authenticated user back to their landing page when they open a
/// screen of another role (typed URL, stale link). The back stays the source
/// of truth for every write; this keeps forms and data of other roles out of
/// sight. Skipped for the legacy role-less callers.
String? _roleGuardRedirect(
  String location, {
  required UserRole? role,
  required Set<Role> memberRoles,
}) {
  if (role == null) return null;
  final audience = _audienceOf(location);
  if (audience == null) return null;
  final isAdmin = role == UserRole.admin || memberRoles.contains(Role.admin);
  final allowed = switch (audience) {
    _RouteAudience.owner => role == UserRole.owner,
    _RouteAudience.producer => role == UserRole.producer,
    _RouteAudience.admin => isAdmin,
    _RouteAudience.coordinator =>
      isAdmin ||
          role == UserRole.coordinator ||
          memberRoles.contains(Role.coordinator),
    _RouteAudience.member =>
      memberRoles.isNotEmpty ||
          (role != UserRole.owner && role != UserRole.producer),
  };
  return allowed ? null : _landingRouteFor(role: role, isAdmin: false);
}

/// Returns the landing route after a successful login, based on [role].
///
/// Falls back to [isAdmin] when [role] is null (backward-compatible path).
String _landingRouteFor({required UserRole? role, required bool isAdmin}) =>
    switch (role) {
      UserRole.owner => '/owner/dashboard',
      // Spec screen-common-01-menu: the producer home is its dashboard.
      UserRole.producer => _kProducerDashboardRoute,
      UserRole.admin ||
      UserRole.coordinator ||
      UserRole.volunteer ||
      UserRole.memberNoRole => _kDashboardRoute,
      null => isAdmin ? _kOrganizationRequestsRoute : _kProductTypesRoute,
    };

/// Builds the app router. The `authBloc` instance drives both the redirect
/// logic and the protected-route screens (the screens read
/// `state.producerId` from it as their tenant id).
GoRouter buildRouter({required AuthBloc authBloc}) {
  final listenable = _AuthBlocListenable(authBloc);
  return GoRouter(
    refreshListenable: listenable,
    errorBuilder: (_, _) => const NotFoundScreen(),
    redirect: (context, state) => computeRouterRedirect(
      state.uri,
      authBloc.state.producerId,
      isAdmin: authBloc.state.isAdmin,
      role: authBloc.state.role,
      memberRoles: authBloc.state.memberRoles,
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
            builder: (_, _) => tenantScoped(
              (tenantId) => ProductTypesScreen(tenantId: tenantId),
            ),
          ),
          GoRoute(
            path: '/product-types/new',
            builder: (_, _) => tenantScoped(
              (tenantId) => ProductTypeFormScreen(tenantId: tenantId),
            ),
          ),
          GoRoute(
            path: '/product-types/:id',
            builder: (_, st) => tenantScoped(
              (tenantId) => ProductTypeFormScreen(
                tenantId: tenantId,
                productTypeId: st.pathParameters['id'],
              ),
            ),
          ),
          GoRoute(
            path: '/product-types/:productTypeId/items',
            builder: (_, st) => tenantScoped(
              (tenantId) => ItemTypesRouteScreen(
                tenantId: tenantId,
                productTypeId: st.pathParameters['productTypeId']!,
                productType: st.extra as ProductType?,
              ),
            ),
          ),
          GoRoute(
            path: _kOrganizationRequestsRoute,
            builder: (_, state) => AdminRequestsScreen(
              initialTab: state.uri.queryParameters['tab'] == 'producers'
                  ? AdminRequestsTab.producers
                  : AdminRequestsTab.amap,
            ),
          ),
          GoRoute(
            path: '/admin/producers',
            builder: (_, state) => tenantScoped(
              (tenantId) => ProducerListScreen(organizationId: tenantId),
            ),
          ),
          // Keep the static sub-route before `:producerAccountId`; otherwise
          // `/admin/producers/enroll` is interpreted as a detail page for the
          // producer id `enroll`.
          GoRoute(
            path: '/admin/producers/enroll',
            builder: (_, state) => tenantScoped(
              (tenantId) => EnrollProducerScreen(organizationId: tenantId),
            ),
          ),
          GoRoute(
            path: '/admin/producers/:producerAccountId',
            builder: (_, state) => tenantScoped(
              (tenantId) => ProducerDetailScreen(
                organizationId: tenantId,
                producerAccountId: state.pathParameters['producerAccountId']!,
              ),
            ),
          ),
          GoRoute(
            path: '/admin/delivery-templates',
            builder: (_, _) => tenantScoped(
              (tenantId) =>
                  DeliveryTemplateListScreen(organizationId: tenantId),
            ),
          ),
          GoRoute(
            path: '/admin/delivery-templates/new',
            builder: (_, _) => tenantScoped(
              (tenantId) =>
                  DeliveryTemplateFormScreen(organizationId: tenantId),
            ),
          ),
          GoRoute(
            path: '/admin/delivery-templates/:id',
            builder: (_, state) => tenantScoped(
              (tenantId) => DeliveryTemplateFormScreen(
                organizationId: tenantId,
                template: state.extra as DeliveryTemplate?,
              ),
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
            path: _kDashboardRoute,
            builder: (_, _) => tenantScoped(
              (tenantId) => MixedDashboardScreen(tenantId: tenantId),
            ),
          ),
          GoRoute(
            path: '/contracts',
            builder: (_, _) => tenantScoped(
              (tenantId) => MemberContractsScreen(tenantId: tenantId),
            ),
          ),
          GoRoute(
            path: '/planning',
            builder: (_, _) => tenantScoped(
              (tenantId) => MemberDeliveryPlanScreen(tenantId: tenantId),
            ),
          ),
          GoRoute(
            path: '/history',
            builder: (_, _) => tenantScoped(
              (tenantId) => MemberHistoryScreen(tenantId: tenantId),
            ),
          ),
          GoRoute(
            path: '/history/ranking',
            builder: (_, _) => tenantScoped(
              (tenantId) => MemberRankingScreen(tenantId: tenantId),
            ),
          ),
          // Basket-exchange routes — keep static sub-routes before the
          // parametric `:offerId` route so `/basket-exchange/history` is not
          // interpreted as the requests screen for offerId="history".
          GoRoute(
            path: '/basket-exchange/history',
            builder: (context, _) => tenantScoped(
              (tenantId) => BasketExchangeHistoryScreen(
                orgId: tenantId,
                memberId: _resolveSub(context),
              ),
            ),
          ),
          GoRoute(
            path: '/basket-exchange/overview',
            builder: (_, _) => tenantScoped(
              (tenantId) => BasketExchangeOverviewScreen(orgId: tenantId),
            ),
          ),
          GoRoute(
            path: '/basket-exchange/:offerId/requests',
            builder: (_, state) => tenantScoped(
              (tenantId) => ReceivedRequestsScreen(
                orgId: tenantId,
                offerId: state.pathParameters['offerId']!,
              ),
            ),
          ),
          GoRoute(
            path: '/basket-exchange',
            builder: (_, _) => tenantScoped(
              (tenantId) => BasketExchangeScreen(tenantId: tenantId),
            ),
          ),
          GoRoute(
            path: '/slots',
            builder: (_, _) =>
                tenantScoped((tenantId) => TimeSlotsScreen(tenantId: tenantId)),
          ),
          GoRoute(
            path: '/coordinator/contracts',
            builder: (_, _) => tenantScoped(
              (tenantId) => CoordinatorContractsScreen(tenantId: tenantId),
            ),
          ),
          GoRoute(
            path: '/coordinator/member-contracts',
            builder: (_, _) => tenantScoped(
              (tenantId) =>
                  CoordinatorMemberContractsScreen(tenantId: tenantId),
            ),
          ),
          GoRoute(
            path: '/coordinator/time-slots',
            builder: (_, _) =>
                tenantScoped((tenantId) => TimeSlotsScreen(tenantId: tenantId)),
          ),
          GoRoute(
            path: '/coordinator/time-slots/new',
            builder: (_, _) => tenantScoped(
              (tenantId) => TimeSlotFormScreen(tenantId: tenantId),
            ),
          ),
          GoRoute(
            path: '/coordinator/time-slots/:deliveryId',
            builder: (_, st) => tenantScoped(
              (tenantId) => TimeSlotFormScreen(
                tenantId: tenantId,
                deliveryId: st.pathParameters['deliveryId'],
              ),
            ),
          ),
          GoRoute(
            path: '/coordinator/attendance',
            builder: (_, _) => tenantScoped(
              (tenantId) => AttendanceSheetsScreen(tenantId: tenantId),
            ),
          ),
          GoRoute(
            path: '/coordinator/tracking/:deliveryId',
            builder: (_, st) => tenantScoped(
              (tenantId) => CoordinatorDeliveryTrackingScreen(
                tenantId: tenantId,
                deliveryId: st.pathParameters['deliveryId'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: '/coordinator/post-delivery/:deliveryId',
            builder: (_, st) => tenantScoped(
              (tenantId) => CoordinatorPostDeliverySyncScreen(
                tenantId: tenantId,
                deliveryId: st.pathParameters['deliveryId'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: '/coordinator/deliveries/:deliveryId/description',
            builder: (_, st) => DeliveryDescriptionScreen(
              org: st.extra! as Organization,
              deliveryId: st.pathParameters['deliveryId']!,
            ),
          ),
          GoRoute(
            path: '/members',
            builder: (_, _) => tenantScoped(
              (tenantId) => UserManagementScreen(
                organizationId: tenantId,
                canEditAdminRole: authBloc.state.isAdmin,
              ),
            ),
          ),
          GoRoute(
            path: '/admin/membership-requests',
            builder: (_, _) => tenantScoped(
              (tenantId) => MembershipRequestsScreen(organizationId: tenantId),
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
            builder: (_, _) => tenantScoped(
              (tenantId) => OrganizationConfigScreen(tenantId: tenantId),
            ),
          ),
          GoRoute(
            path: _kProducerDashboardRoute,
            builder: (_, _) => tenantScoped(
              (tenantId) => ProducerDashboardScreen(tenantId: tenantId),
            ),
          ),
          GoRoute(
            path: '/producer-deliveries',
            builder: (_, _) => tenantScoped(
              // A producer's tenant is its account id.
              (tenantId) =>
                  ProducerDeliveriesScreen(producerAccountId: tenantId),
            ),
          ),
          GoRoute(
            path:
                '/producer-deliveries/:organizationId/:deliveryId/composition',
            builder: (_, st) => tenantScoped(
              (tenantId) => ProducerDeliveryCompositionScreen(
                producerAccountId: tenantId,
                organizationId: st.pathParameters['organizationId']!,
                deliveryId: st.pathParameters['deliveryId']!,
              ),
            ),
          ),
          GoRoute(
            path: '/preferences',
            builder: (context, _) {
              final sub = _resolveSub(context);
              final role = authBloc.state.role;
              if (role == UserRole.producer) {
                // Keyed on the resolved producer account id (see tenantScoped).
                return tenantScoped(
                  (tenantId) => BlocProvider(
                    create: (_) => UserPreferencesBloc(
                      source: ProducerSource(
                        producerAccountId: tenantId,
                        producerAccountRepository: context
                            .read<ProducerAccountRepository>(),
                      ),
                    ),
                    child: const UserPreferencesScreen(),
                  ),
                );
              }
              final UserPreferencesSource source;
              if (role == UserRole.owner) {
                source = OwnerSource(
                  ownerId: sub,
                  ownerRepository: context.read<OwnerRepository>(),
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
                return tenantScoped(
                  (tenantId) => MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => UserPreferencesBloc(source: source),
                      ),
                      BlocProvider(
                        create: (_) => AlertTemplatesBloc(
                          organizationRepository: context
                              .read<OrganizationRepository>(),
                          tenantId: tenantId,
                        ),
                      ),
                    ],
                    child: UserPreferencesScreen(
                      showAlertTemplates: true,
                      backupOrganizationId: tenantId,
                    ),
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
          GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
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
  } on Exception catch (e) {
    recordFallbackBreadcrumb('JWT sub decode failed', e);
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

/// The current tenant: a producer's account id (resolved from the synced
/// scope, it may differ from the auth `sub` in `producerId`), otherwise the
/// member's organization id; the `sub` until either is resolved.
@visibleForTesting
String tenantOf(AuthViewState state) =>
    (state.role == UserRole.producer
        ? state.producerAccountId
        : state.organizationId) ??
    state.producerId ??
    '';

/// Builds a tenant-scoped screen, rebuilt from scratch — its blocs included —
/// whenever the tenant changes.
///
/// It listens to [AuthBloc] itself: go_router does not re-run the builder of
/// a page already on screen when the auth state changes. On a page reload the
/// tenant starts as the `sub` (Cognito tokens carry no tenant claim) until
/// [AuthBloc] resolves the real organization / producer account id from the
/// local cache; without the remount the screen would keep reading and writing
/// under the `sub` (e.g. invitations missing, producer catalog empty).
@visibleForTesting
Widget tenantScoped(Widget Function(String tenantId) buildScreen) =>
    BlocSelector<AuthBloc, AuthViewState, String>(
      selector: tenantOf,
      builder: (context, tenantId) => KeyedSubtree(
        key: ValueKey('tenant:$tenantId'),
        child: buildScreen(tenantId),
      ),
    );

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
