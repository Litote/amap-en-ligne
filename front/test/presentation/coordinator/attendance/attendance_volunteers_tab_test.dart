import 'package:amap_en_ligne/data/repositories/attendance_email_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/domain/model/basket_exchange.dart';
import 'package:amap_en_ligne/domain/model/contract.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/coordinator/attendance/attendance_sheets_screen.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/organization_fixtures.dart';

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

class _MockContractRepository extends Mock implements ContractRepository {}

class _MockMemberRepository extends Mock implements MemberRepository {}

class _MockBasketExchangeRepository extends Mock
    implements BasketExchangeRepository {}

class _MockAttendanceEmailRequestRepository extends Mock
    implements AttendanceEmailRequestRepository {}

class _MockSyncBloc extends MockBloc<SyncEvent, SyncState>
    implements SyncBloc {}

const _orgId = 'org-1';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr', null);
  });

  late _MockOrganizationRepository orgRepo;
  late _MockContractRepository contractRepo;
  late _MockMemberRepository memberRepo;
  late _MockBasketExchangeRepository exchangeRepo;
  late _MockAttendanceEmailRequestRepository attendanceRepo;
  late _MockSyncBloc syncBloc;

  setUp(() {
    orgRepo = _MockOrganizationRepository();
    contractRepo = _MockContractRepository();
    memberRepo = _MockMemberRepository();
    exchangeRepo = _MockBasketExchangeRepository();
    attendanceRepo = _MockAttendanceEmailRequestRepository();
    syncBloc = _MockSyncBloc();

    when(() => syncBloc.state).thenReturn(const SyncState.idle());
    when(() => syncBloc.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => contractRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <Contract>[]));
    when(
      () => memberRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <Member>[]));
    when(
      () => exchangeRepo.watch(any()),
    ).thenAnswer((_) => Stream.value(const <BasketExchange>[]));
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<OrganizationRepository>.value(value: orgRepo),
          RepositoryProvider<ContractRepository>.value(value: contractRepo),
          RepositoryProvider<MemberRepository>.value(value: memberRepo),
          RepositoryProvider<BasketExchangeRepository>.value(
            value: exchangeRepo,
          ),
          RepositoryProvider<AttendanceEmailRequestRepository>.value(
            value: attendanceRepo,
          ),
        ],
        child: BlocProvider<SyncBloc>.value(
          value: syncBloc,
          child: const MaterialApp(
            home: AttendanceSheetsScreen(tenantId: _orgId),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'Bénévoles tab excludes the delivery coordinators from the list',
    (tester) async {
      final coordinatorReg = buildRegistration(
        memberId: 'coord-1',
        displayName: 'Chef Coordinateur',
        status: RegistrationStatus.confirmed,
      );
      final volunteerReg = buildRegistration(
        memberId: 'vol-1',
        displayName: 'Vraie Bénévole',
        status: RegistrationStatus.confirmed,
      );
      final slot = buildSlot(
        registrations: [coordinatorReg, volunteerReg],
        requiredVolunteers: 2,
        currentRegistrations: 2,
      );
      final contract = buildContract(
        coordinators: const ['coord-1'],
        slots: [slot],
      );
      final delivery = buildDelivery(
        scheduledDate: '2030-01-15T18:00:00',
        contracts: [contract],
      );
      when(
        () => orgRepo.watch(any()),
      ).thenAnswer((_) => Stream.value(buildOrg(deliveries: [delivery])));

      await pump(tester);

      // Select the delivery — the default "Bénévoles" tab is then shown.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('janvier 2030').last);
      await tester.pumpAndSettle();

      expect(find.text('Vraie Bénévole'), findsOneWidget);
      expect(find.text('Chef Coordinateur'), findsNothing);
    },
  );
}
