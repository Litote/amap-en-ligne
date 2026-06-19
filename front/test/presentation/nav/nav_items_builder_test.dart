import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/presentation/nav/nav_item.dart';
import 'package:amap_en_ligne/presentation/nav/nav_items_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void noop() {}

  // Helper: action item labels only (excludes separators and section headers).
  List<String> actionLabels(List<NavItem> items) => items
      .where((i) => i.kind == NavItemKind.action)
      .map((i) => i.label)
      .toList();

  // Helper: section header labels.
  List<String> sectionHeaders(List<NavItem> items) => items
      .where((i) => i.kind == NavItemKind.sectionHeader)
      .map((i) => i.label)
      .toList();

  group('buildNavItemsForRole — common items', () {
    test('Se déconnecter present for every role with onTap', () {
      for (final role in UserRole.values) {
        final items = buildNavItemsForRole(role, noop);
        final signOut = items.where((i) => i.label == 'Se déconnecter');
        expect(signOut, hasLength(1), reason: 'role=$role');
        expect(signOut.first.onTap, isNotNull, reason: 'role=$role');
      }
    });

    test('Préférences and Se déconnecter present for every role', () {
      for (final role in UserRole.values) {
        final labels = actionLabels(buildNavItemsForRole(role, noop));
        expect(labels, contains('Préférences'), reason: 'role=$role');
        expect(labels, contains('Se déconnecter'), reason: 'role=$role');
      }
    });

    test('separator present for every role', () {
      for (final role in UserRole.values) {
        final items = buildNavItemsForRole(role, noop);
        expect(
          items.any((i) => i.kind == NavItemKind.separator),
          isTrue,
          reason: 'role=$role',
        );
      }
    });

    test('onLogout callback wired to Se déconnecter', () {
      var called = false;
      final items = buildNavItemsForRole(UserRole.volunteer, () {
        called = true;
      });
      items.firstWhere((i) => i.label == 'Se déconnecter').onTap!();
      expect(called, isTrue);
    });
  });

  group('buildNavItemsForRole — volunteer', () {
    test(
      'contains Accueil, Mes contrats, Mon historique and Planning des livraisons',
      () {
        final labels = actionLabels(
          buildNavItemsForRole(UserRole.volunteer, noop),
        );
        expect(labels, contains('Accueil'));
        expect(labels, contains('Mes contrats'));
        expect(labels, contains('Mon historique'));
        expect(labels, contains('Planning des livraisons'));
      },
    );

    test('correct routes', () {
      final items = buildNavItemsForRole(UserRole.volunteer, noop);
      final routes = {
        for (final i in items)
          if (i.route != null) i.label: i.route,
      };
      expect(routes['Accueil'], '/dashboard');
      expect(routes['Mes contrats'], '/contracts');
      expect(routes['Mon historique'], '/history');
      expect(routes['Planning des livraisons'], '/planning');
    });

    test('no section headers (single role)', () {
      expect(
        sectionHeaders(buildNavItemsForRole(UserRole.volunteer, noop)),
        isEmpty,
      );
    });
  });

  group('buildNavItemsForRole — coordinator', () {
    test(
      'contains Accueil, Mes contrats, Mon historique, Planning des livraisons, Gestion des livraisons, Feuilles d\'émargement, Gestion des contrats and Contrats par Amapien',
      () {
        final labels = actionLabels(
          buildNavItemsForRole(UserRole.coordinator, noop),
        );
        expect(labels, contains('Accueil'));
        expect(labels, contains('Mes contrats'));
        expect(labels, contains('Mon historique'));
        expect(labels, contains('Planning des livraisons'));
        expect(labels, contains('Gestion des livraisons'));
        expect(labels, contains("Feuilles d'émargement"));
        expect(labels, contains('Gestion des contrats'));
        expect(labels, contains('Contrats par Amapien'));
        expect(labels, isNot(contains('Suivi des livraisons')));
        expect(labels, isNot(contains('Gestion des membres')));
      },
    );

    test('correct routes', () {
      final items = buildNavItemsForRole(UserRole.coordinator, noop);
      final routes = {
        for (final i in items)
          if (i.route != null) i.label: i.route,
      };
      expect(routes['Accueil'], '/dashboard');
      expect(routes['Mes contrats'], '/contracts');
      expect(routes['Mon historique'], '/history');
      expect(routes['Planning des livraisons'], '/planning');
      expect(routes['Gestion des livraisons'], '/coordinator/time-slots');
      expect(routes["Feuilles d'émargement"], '/coordinator/attendance');
      expect(routes['Gestion des contrats'], '/coordinator/contracts');
      expect(routes['Contrats par Amapien'], '/coordinator/member-contracts');
      expect(routes.containsKey('Suivi des livraisons'), isFalse);
    });

    test('no section headers (single role)', () {
      expect(
        sectionHeaders(buildNavItemsForRole(UserRole.coordinator, noop)),
        isEmpty,
      );
    });
  });

  group('buildNavItemsForRole — admin', () {
    test(
      "contains Accueil, Utilisateurs, Producteurs, Templates de livraison and Demandes d'adhésion",
      () {
        final labels = actionLabels(buildNavItemsForRole(UserRole.admin, noop));
        expect(labels, contains('Accueil'));
        expect(labels, contains('Utilisateurs'));
        expect(labels, contains('Producteurs'));
        expect(labels, contains('Templates de livraison'));
        expect(labels, contains("Demandes d'adhésion"));
      },
    );

    test('correct routes', () {
      final items = buildNavItemsForRole(UserRole.admin, noop);
      final routes = {
        for (final i in items)
          if (i.route != null) i.label: i.route,
      };
      expect(routes['Accueil'], '/dashboard');
      expect(routes['Utilisateurs'], '/members');
      expect(routes['Producteurs'], '/admin/producers');
      expect(routes['Templates de livraison'], '/admin/delivery-templates');
      expect(routes["Demandes d'adhésion"], '/admin/membership-requests');
    });
  });

  group('buildNavItemsForRole — owner', () {
    test(
      "contains Accueil, request entries, Utilisateurs and Nouvel Administrateur",
      () {
        final labels = actionLabels(buildNavItemsForRole(UserRole.owner, noop));
        expect(labels, contains('Accueil'));
        expect(labels, contains("Demandes d'organisation"));
        expect(labels, contains('Demandes producteurs'));
        expect(labels, contains('Utilisateurs'));
        expect(labels, contains('Nouvel Administrateur'));
      },
    );

    test(
      'owner routes include organization requests, producer requests, users and invite administrator',
      () {
        final items = buildNavItemsForRole(UserRole.owner, noop);
        final routes = items.map((i) => i.route).whereType<String>();
        expect(routes, contains('/admin/organization-requests'));
        expect(routes, contains('/admin/producer-requests'));
        expect(routes, contains('/owner/users'));
        expect(routes, contains('/owner/invite-administrator'));
      },
    );
  });

  group('buildNavItemsForRole — producer', () {
    test('contains Accueil producteur', () {
      final labels = actionLabels(
        buildNavItemsForRole(UserRole.producer, noop),
      );
      expect(labels, contains('Accueil producteur'));
    });
  });

  group('buildNavItemsForRole — memberNoRole', () {
    test('contains only Accueil + common items', () {
      final labels = actionLabels(
        buildNavItemsForRole(UserRole.memberNoRole, noop),
      );
      expect(labels, contains('Accueil'));
      expect(
        labels.where(
          (l) => !['Accueil', 'Préférences', 'Se déconnecter'].contains(l),
        ),
        isEmpty,
      );
    });
  });

  group('buildNavItems — multi-role sections', () {
    test('empty set → only common items, no headers, no separator', () {
      final items = buildNavItems(const {}, noop);
      expect(sectionHeaders(items), isEmpty);
      expect(items.any((i) => i.kind == NavItemKind.separator), isFalse);
      expect(
        actionLabels(items),
        containsAll(['Préférences', 'Se déconnecter']),
      );
    });

    test('single role → no section headers, has separator', () {
      final items = buildNavItems({Role.volunteer}, noop);
      expect(sectionHeaders(items), isEmpty);
      expect(items.any((i) => i.kind == NavItemKind.separator), isTrue);
    });

    test('VOLUNTEER + COORDINATOR → two section headers in order', () {
      final headers = sectionHeaders(
        buildNavItems({Role.volunteer, Role.coordinator}, noop),
      );
      expect(headers, ['— Bénévole —', '— Coordinateur —']);
    });

    test('COORDINATOR + ADMIN → correct items in each section', () {
      final items = buildNavItems({Role.coordinator, Role.admin}, noop);
      final labels = actionLabels(items);
      expect(labels, contains('Accueil'));
      expect(labels, contains('Mes contrats'));
      expect(labels, contains('Mon historique'));
      expect(labels, contains('Planning des livraisons'));
      expect(labels, contains('Gestion des livraisons'));
      expect(labels, contains("Feuilles d'émargement"));
      expect(labels, contains('Gestion des contrats'));
      expect(labels, contains('Contrats par Amapien'));
      expect(labels, isNot(contains('Suivi des livraisons')));
      expect(labels, isNot(contains('Gestion des membres')));
      expect(labels, contains('Utilisateurs'));
      expect(labels, contains('Producteurs'));
      expect(labels, contains('Templates de livraison'));
      expect(labels, contains("Demandes d'adhésion"));
    });

    test('all three roles → three section headers in ascending order', () {
      final headers = sectionHeaders(
        buildNavItems({Role.volunteer, Role.coordinator, Role.admin}, noop),
      );
      expect(headers, ['— Bénévole —', '— Coordinateur —', '— Admin —']);
    });

    test('separator appears before common items in multi-role', () {
      final items = buildNavItems({Role.volunteer, Role.coordinator}, noop);
      final sepIdx = items.indexWhere((i) => i.kind == NavItemKind.separator);
      final logoutIdx = items.indexWhere((i) => i.label == 'Se déconnecter');
      expect(sepIdx, lessThan(logoutIdx));
    });

    test('common items appear exactly once regardless of role count', () {
      final items = buildNavItems({
        Role.volunteer,
        Role.coordinator,
        Role.admin,
      }, noop);
      final labels = actionLabels(items);
      expect(labels.where((l) => l == 'Préférences'), hasLength(1));
      expect(labels.where((l) => l == 'Se déconnecter'), hasLength(1));
    });

    test(
      'duplicate items (same label+route across roles) appear only once',
      () {
        final items = buildNavItems({Role.coordinator, Role.admin}, noop);
        final keys = items
            .where((i) => i.kind == NavItemKind.action)
            .map((i) => '${i.label}|${i.route}')
            .toList();
        expect(keys.length, equals(keys.toSet().length));
      },
    );
  });
}
