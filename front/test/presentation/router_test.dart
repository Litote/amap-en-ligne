import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/presentation/router.dart';
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
      test('on / is redirected to /product-types', () {
        expect(
          computeRouterRedirect(Uri.parse('/'), 'u-1', role: UserRole.producer),
          '/product-types',
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
}
