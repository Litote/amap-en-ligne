import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/notification.dart';
import 'package:amap_en_ligne/domain/model/notification_copy_override.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/common/alert_templates_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

const _tenantId = 'org-1';

final _org = Organization(
  organizationId: _tenantId,
  name: 'AMAP Test',
  contactEmail: 'test@amap.fr',
);

void main() {
  late _MockOrganizationRepository repo;

  setUpAll(() {
    registerFallbackValue(_org);
    registerFallbackValue(
      const <NotificationCategory, NotificationCopyOverride>{},
    );
  });

  setUp(() {
    repo = _MockOrganizationRepository();
  });

  AlertTemplatesBloc buildBloc() =>
      AlertTemplatesBloc(organizationRepository: repo, tenantId: _tenantId);

  blocTest<AlertTemplatesBloc, AlertTemplatesState>(
    'emits ready when the organization stream resolves',
    setUp: () {
      when(() => repo.watch(_tenantId)).thenAnswer((_) => Stream.value(_org));
    },
    build: buildBloc,
    expect: () => [
      isA<AlertTemplatesReady>().having(
        (s) => s.organization.organizationId,
        'organizationId',
        _tenantId,
      ),
    ],
  );

  blocTest<AlertTemplatesBloc, AlertTemplatesState>(
    'emits missing when the organization is not yet synced',
    setUp: () {
      when(() => repo.watch(_tenantId)).thenAnswer((_) => Stream.value(null));
    },
    build: buildBloc,
    expect: () => [isA<AlertTemplatesMissing>()],
  );

  blocTest<AlertTemplatesBloc, AlertTemplatesState>(
    'saved forwards overrides to the repository and reports success',
    setUp: () {
      when(() => repo.watch(_tenantId)).thenAnswer((_) => Stream.value(_org));
      when(
        () => repo.updateNotificationOverrides(
          currentOrg: any(named: 'currentOrg'),
          overrides: any(named: 'overrides'),
        ),
      ).thenAnswer((_) async {});
    },
    build: buildBloc,
    act: (bloc) async {
      // Let the organization stream emit the initial ready state first.
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const AlertTemplatesEvent.saved({
          NotificationCategory.slotCancelled: NotificationCopyOverride(
            title: 'Annulé',
          ),
        }),
      );
    },
    expect: () => [
      isA<AlertTemplatesReady>().having(
        (s) => s.saveStatus,
        'saveStatus',
        AlertTemplatesSaveStatus.idle,
      ),
      isA<AlertTemplatesReady>().having(
        (s) => s.saveStatus,
        'saveStatus',
        AlertTemplatesSaveStatus.saving,
      ),
      isA<AlertTemplatesReady>().having(
        (s) => s.saveStatus,
        'saveStatus',
        AlertTemplatesSaveStatus.success,
      ),
    ],
    verify: (_) {
      verify(
        () => repo.updateNotificationOverrides(
          currentOrg: _org,
          overrides: any(named: 'overrides'),
        ),
      ).called(1);
    },
  );
}
