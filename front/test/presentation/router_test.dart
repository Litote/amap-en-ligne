import 'dart:async';

import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_event.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/router.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeRouterRedirect', () {
    group('auth bootstrap in flight', () {
      test('initializing=true returns null even on protected route', () {
        // Without this guard, the first redirect on F5 would bounce the user
        // to /login before bootstrap restores the session.
        expect(
          computeRouterRedirect(
            Uri.parse('/owner/users'),
            null,
            initializing: true,
          ),
          isNull,
        );
      });

      test('initializing=true returns null on /login too', () {
        expect(
          computeRouterRedirect(Uri.parse('/login'), null, initializing: true),
          isNull,
        );
      });
    });

    group('authenticated producer (non-admin)', () {
      test('on / is redirected to /product-types', () {
        expect(computeRouterRedirect(Uri.parse('/'), 'u-1'), '/product-types');
      });

      test('on /login is redirected to /product-types', () {
        expect(
          computeRouterRedirect(Uri.parse('/login'), 'u-1'),
          '/product-types',
        );
      });

      test('on /register is redirected to /product-types', () {
        expect(
          computeRouterRedirect(Uri.parse('/register'), 'u-1'),
          '/product-types',
        );
      });

      test('on /product-types stays (no redirect)', () {
        expect(
          computeRouterRedirect(Uri.parse('/product-types'), 'u-1'),
          isNull,
        );
      });
    });

    group('authenticated admin / owner', () {
      test('on / is redirected to /admin/organization-requests', () {
        expect(
          computeRouterRedirect(Uri.parse('/'), 'u-1', isAdmin: true),
          '/admin/organization-requests',
        );
      });

      test('on /login is redirected to /admin/organization-requests', () {
        expect(
          computeRouterRedirect(Uri.parse('/login'), 'u-1', isAdmin: true),
          '/admin/organization-requests',
        );
      });

      test('on /register is redirected to /admin/organization-requests', () {
        expect(
          computeRouterRedirect(Uri.parse('/register'), 'u-1', isAdmin: true),
          '/admin/organization-requests',
        );
      });

      test('on /admin/organization-requests stays (no redirect)', () {
        expect(
          computeRouterRedirect(
            Uri.parse('/admin/organization-requests'),
            'u-1',
            isAdmin: true,
          ),
          isNull,
        );
      });

      test('on /product-types stays (no redirect)', () {
        expect(
          computeRouterRedirect(
            Uri.parse('/product-types'),
            'u-1',
            isAdmin: true,
          ),
          isNull,
        );
      });
    });

    group('unauthenticated user', () {
      test('on / stays (no redirect)', () {
        expect(computeRouterRedirect(Uri.parse('/'), null), isNull);
      });

      test('on /login stays (no redirect)', () {
        expect(computeRouterRedirect(Uri.parse('/login'), null), isNull);
      });

      test('on /register stays (no redirect)', () {
        expect(computeRouterRedirect(Uri.parse('/register'), null), isNull);
      });

      test('on /register/producer stays (no redirect)', () {
        expect(
          computeRouterRedirect(Uri.parse('/register/producer'), null),
          isNull,
        );
      });

      test('on /forgot-password stays (no redirect)', () {
        expect(
          computeRouterRedirect(Uri.parse('/forgot-password'), null),
          isNull,
        );
      });

      test('on /product-types is redirected to /login with from', () {
        expect(
          computeRouterRedirect(Uri.parse('/product-types'), null),
          '/login?from=%2Fproduct-types',
        );
      });
    });

    group('authenticated user on public routes', () {
      test('on /forgot-password is redirected to /product-types', () {
        expect(
          computeRouterRedirect(Uri.parse('/forgot-password'), 'u-1'),
          '/product-types',
        );
      });

      test('on /register/producer is redirected to /product-types', () {
        expect(
          computeRouterRedirect(Uri.parse('/register/producer'), 'u-1'),
          '/product-types',
        );
      });

      test(
        'on /activate stays (no redirect — one-time link, auth-agnostic)',
        () {
          expect(computeRouterRedirect(Uri.parse('/activate'), 'u-1'), isNull);
        },
      );

      test('on /activate stays even for admin', () {
        expect(
          computeRouterRedirect(Uri.parse('/activate'), 'u-1', isAdmin: true),
          isNull,
        );
      });
    });

    group('role-based landing — admin role', () {
      test('on / is redirected to /dashboard (unified composite)', () {
        expect(
          computeRouterRedirect(Uri.parse('/'), 'u-1', role: UserRole.admin),
          '/dashboard',
        );
      });

      test('on /login is redirected to /dashboard', () {
        expect(
          computeRouterRedirect(
            Uri.parse('/login'),
            'u-1',
            role: UserRole.admin,
          ),
          '/dashboard',
        );
      });

      test('on /dashboard stays (no redirect)', () {
        expect(
          computeRouterRedirect(
            Uri.parse('/dashboard'),
            'u-1',
            role: UserRole.admin,
          ),
          isNull,
        );
      });
    });

    group('role-based landing — owner role', () {
      test('on / is redirected to /owner/dashboard', () {
        expect(
          computeRouterRedirect(Uri.parse('/'), 'u-1', role: UserRole.owner),
          '/owner/dashboard',
        );
      });

      test('on /login is redirected to /owner/dashboard', () {
        expect(
          computeRouterRedirect(
            Uri.parse('/login'),
            'u-1',
            role: UserRole.owner,
          ),
          '/owner/dashboard',
        );
      });
    });

    group('role-based landing — producer role', () {
      // Spec screen-common-01-menu: the producer home is its dashboard.
      test('on / is redirected to /producer-dashboard', () {
        expect(
          computeRouterRedirect(Uri.parse('/'), 'u-1', role: UserRole.producer),
          '/producer-dashboard',
        );
      });
    });

    group('role-based landing — member / volunteer / coordinator', () {
      test('volunteer on / is redirected to /dashboard', () {
        expect(
          computeRouterRedirect(
            Uri.parse('/'),
            'u-1',
            role: UserRole.volunteer,
          ),
          '/dashboard',
        );
      });

      test('coordinator on / is redirected to /dashboard', () {
        expect(
          computeRouterRedirect(
            Uri.parse('/'),
            'u-1',
            role: UserRole.coordinator,
          ),
          '/dashboard',
        );
      });

      test('memberNoRole on / is redirected to /dashboard', () {
        expect(
          computeRouterRedirect(
            Uri.parse('/'),
            'u-1',
            role: UserRole.memberNoRole,
          ),
          '/dashboard',
        );
      });

      test('on /dashboard stays (no redirect)', () {
        expect(
          computeRouterRedirect(
            Uri.parse('/dashboard'),
            'u-1',
            role: UserRole.volunteer,
          ),
          isNull,
        );
      });
    });

    group('OWNER guard — /owner/users routes', () {
      test('authenticated owner can access /owner/users (no redirect)', () {
        expect(
          computeRouterRedirect(
            Uri.parse('/owner/users'),
            'u-1',
            role: UserRole.owner,
          ),
          isNull,
        );
      });

      test(
        'unauthenticated user accessing /owner/users is redirected to /login with from',
        () {
          expect(
            computeRouterRedirect(Uri.parse('/owner/users'), null),
            '/login?from=%2Fowner%2Fusers',
          );
        },
      );

      test(
        'non-owner authenticated user accessing /owner/users is redirected to /login',
        () {
          expect(
            computeRouterRedirect(
              Uri.parse('/owner/users'),
              'u-1',
              role: UserRole.admin,
            ),
            '/login',
          );
        },
      );

      test('volunteer accessing /owner/users is redirected to /login', () {
        expect(
          computeRouterRedirect(
            Uri.parse('/owner/users'),
            'u-1',
            role: UserRole.volunteer,
          ),
          '/login',
        );
      });

      test(
        'authenticated owner can access /owner/invite-administrator (no redirect)',
        () {
          expect(
            computeRouterRedirect(
              Uri.parse('/owner/invite-administrator'),
              'u-1',
              role: UserRole.owner,
            ),
            isNull,
          );
        },
      );

      test(
        'unauthenticated user accessing /owner/invite-administrator redirects to /login with from',
        () {
          expect(
            computeRouterRedirect(
              Uri.parse('/owner/invite-administrator'),
              null,
            ),
            '/login?from=%2Fowner%2Finvite-administrator',
          );
        },
      );

      test(
        'non-owner accessing /owner/invite-administrator is redirected to /login',
        () {
          expect(
            computeRouterRedirect(
              Uri.parse('/owner/invite-administrator'),
              'u-1',
              role: UserRole.admin,
            ),
            '/login',
          );
        },
      );
    });

    group('role guard — screens outside the user role', () {
      String? redirect(
        String path,
        UserRole role, [
        Set<Role> memberRoles = const {},
      ]) => computeRouterRedirect(
        Uri.parse(path),
        'u-1',
        role: role,
        memberRoles: memberRoles,
      );

      test('a volunteer is sent home from admin, coordinator, owner and '
          'producer screens', () {
        for (final path in [
          '/members',
          '/admin/organization-config',
          '/admin/producers',
          '/admin/producers/enroll',
          '/admin/delivery-templates',
          '/admin/membership-requests',
          '/coordinator/contracts',
          '/coordinator/time-slots',
          '/coordinator/tracking/d-1',
          '/slots',
          // The all-members exchange overview is a coordinator screen.
          '/basket-exchange/overview',
          '/owner/dashboard',
          '/admin/organization-requests',
          '/producer-dashboard',
          '/product-types/new',
        ]) {
          expect(
            redirect(path, UserRole.volunteer, {Role.volunteer}),
            '/dashboard',
            reason: path,
          );
        }
      });

      test('a volunteer keeps the member and common screens', () {
        for (final path in [
          '/dashboard',
          '/contracts',
          '/planning',
          '/history/ranking',
          '/basket-exchange',
          '/basket-exchange/history',
          '/notifications',
          '/preferences',
          '/help',
        ]) {
          expect(
            redirect(path, UserRole.volunteer, {Role.volunteer}),
            isNull,
            reason: path,
          );
        }
      });

      test('a coordinator reaches coordinator screens, not admin ones', () {
        const roles = {Role.volunteer, Role.coordinator};
        expect(
          redirect('/coordinator/time-slots', UserRole.coordinator, roles),
          isNull,
        );
        expect(
          redirect(
            '/coordinator/post-delivery/d-1',
            UserRole.coordinator,
            roles,
          ),
          isNull,
        );
        expect(redirect('/planning', UserRole.coordinator, roles), isNull);
        expect(
          redirect('/basket-exchange/overview', UserRole.coordinator, roles),
          isNull,
        );
        expect(redirect('/members', UserRole.coordinator, roles), '/dashboard');
      });

      test(
        'an admin reaches admin and coordinator screens, not owner ones',
        () {
          const roles = {Role.admin};
          expect(redirect('/members', UserRole.admin, roles), isNull);
          expect(
            redirect('/admin/organization-config', UserRole.admin, roles),
            isNull,
          );
          expect(
            redirect('/coordinator/time-slots', UserRole.admin, roles),
            isNull,
          );
          expect(
            redirect('/admin/organization-requests', UserRole.admin, roles),
            '/dashboard',
          );
          expect(
            redirect('/admin/producer-requests', UserRole.admin, roles),
            '/dashboard',
          );
          expect(
            redirect('/owner/dashboard', UserRole.admin, roles),
            '/dashboard',
          );
        },
      );

      test('an owner reaches owner screens only', () {
        expect(redirect('/owner/dashboard', UserRole.owner), isNull);
        expect(
          redirect('/admin/organization-requests', UserRole.owner),
          isNull,
        );
        expect(redirect('/admin/producer-requests', UserRole.owner), isNull);
        expect(redirect('/members', UserRole.owner), '/owner/dashboard');
        expect(redirect('/dashboard', UserRole.owner), '/owner/dashboard');
      });

      test('an owner who is also an AMAP admin keeps the admin screens', () {
        expect(redirect('/members', UserRole.owner, {Role.admin}), isNull);
      });

      test('a producer reaches producer screens only', () {
        expect(redirect('/producer-dashboard', UserRole.producer), isNull);
        expect(redirect('/producer-deliveries', UserRole.producer), isNull);
        expect(redirect('/product-types/p-1/items', UserRole.producer), isNull);
        expect(redirect('/notifications', UserRole.producer), isNull);
        expect(
          redirect('/dashboard', UserRole.producer),
          '/producer-dashboard',
        );
        expect(
          redirect('/coordinator/time-slots', UserRole.producer),
          '/producer-dashboard',
        );
      });
    });

    group('intended destination preservation', () {
      test(
        'protected route with query params redirects to login with from',
        () {
          expect(
            computeRouterRedirect(Uri.parse('/members?page=2'), null),
            '/login?from=%2Fmembers%3Fpage%3D2',
          );
        },
      );

      test(
        'authenticated user on login with from returns to requested route',
        () {
          expect(
            computeRouterRedirect(
              Uri.parse('/login?from=%2Fmembers%3Fpage%3D2'),
              'u-1',
            ),
            '/members?page=2',
          );
        },
      );

      test('explicit logout clears pending protected redirect', () {
        expect(
          computeRouterRedirect(
            Uri.parse('/members?page=2'),
            null,
            logoutRequested: true,
          ),
          '/login',
        );
      });
    });
  });

  group('decodeEmailQueryParam', () {
    test('returns null when no email param', () {
      expect(decodeEmailQueryParam(Uri.parse('/login')), isNull);
      expect(
        decodeEmailQueryParam(Uri.parse('/login?from=%2Fdashboard')),
        isNull,
      );
    });

    test('preserves + as + (does not decode + as space)', () {
      expect(
        decodeEmailQueryParam(Uri.parse('/login?email=user+tag@example.com')),
        'user+tag@example.com',
      );
    });

    test('decodes %2B as +', () {
      expect(
        decodeEmailQueryParam(
          Uri.parse('/login?email=user%2Btag%40example.com'),
        ),
        'user+tag@example.com',
      );
    });

    test('plain email without + works normally', () {
      expect(
        decodeEmailQueryParam(Uri.parse('/login?email=user@example.com')),
        'user@example.com',
      );
    });

    test('returns null when query is empty string', () {
      expect(decodeEmailQueryParam(Uri.parse('/login?')), isNull);
    });
  });

  group('tenantOf', () {
    test('a producer uses its resolved account id, never an organization', () {
      expect(
        tenantOf(
          const AuthViewState(
            role: UserRole.producer,
            producerId: 'sub',
            producerAccountId: 'pa-1',
            organizationId: 'stale-org',
          ),
        ),
        'pa-1',
      );
    });

    test('a member uses the resolved organization, the sub until then', () {
      expect(
        tenantOf(
          const AuthViewState(
            role: UserRole.admin,
            producerId: 'sub',
            organizationId: 'org-1',
          ),
        ),
        'org-1',
      );
      expect(
        tenantOf(const AuthViewState(role: UserRole.admin, producerId: 'sub')),
        'sub',
      );
    });
  });

  group('tenantScoped', () {
    // Cognito access tokens carry no tenant claim: after a page reload the
    // tenant is the user's `sub` until AuthBloc resolves the real one. The
    // screen must then be rebuilt from scratch — by listening to AuthBloc
    // itself, since go_router does not re-run an on-screen page's builder.
    testWidgets(
      'remounts the screen when the resolved tenant changes and keeps it '
      'otherwise',
      (tester) async {
        final authBloc = _MockAuthBloc();
        final states = StreamController<AuthViewState>();
        const initial = AuthViewState(role: UserRole.admin, producerId: 'sub');
        whenListen(authBloc, states.stream, initialState: initial);
        final mountedFor = <String>[];

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: tenantScoped(
                (tenantId) =>
                    _MountProbe(tenantId: tenantId, onMount: mountedFor.add),
              ),
            ),
          ),
        );
        states.add(initial.copyWith(firstName: 'Alice'));
        await tester.pump();
        expect(mountedFor, ['sub']);

        states.add(initial.copyWith(organizationId: 'org-1'));
        await tester.pump();
        expect(mountedFor, ['sub', 'org-1']);

        await states.close();
      },
    );
  });
}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthViewState>
    implements AuthBloc {}

class _MountProbe extends StatefulWidget {
  const _MountProbe({required this.tenantId, required this.onMount});

  final String tenantId;
  final void Function(String tenantId) onMount;

  @override
  State<_MountProbe> createState() => _MountProbeState();
}

class _MountProbeState extends State<_MountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMount(widget.tenantId);
  }

  @override
  Widget build(BuildContext context) => Text(widget.tenantId);
}
