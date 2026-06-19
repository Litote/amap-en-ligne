import 'dart:async';

import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/error_report_repository.dart';
import 'package:amap_en_ligne/data/repositories/notification_repository.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_invitation_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_join_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_invitation_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/sync/sync_request.dart';
import 'package:amap_en_ligne/main.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSyncApi extends Mock implements SyncApi {}

class _FakeSyncRequest extends Fake implements SyncRequest {}

class _TestAuthService implements AuthService {
  _TestAuthService(this._current);

  final _controller = StreamController<AuthState>.broadcast();
  AuthState _current;
  int signOutCalls = 0;

  @override
  Stream<AuthState> get authState async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  AuthState get currentState => _current;

  @override
  Future<void> bootstrap() async {}

  @override
  Future<String?> currentAccessToken() async => switch (_current) {
    Authenticated(:final accessToken) => accessToken,
    Unauthenticated() => null,
  };

  @override
  Future<void> signIn({
    required String email,
    required String password,
    bool? rememberSession,
  }) async {
    _current = const AuthState.authenticated(
      producerId: 'producerAccountId',
      accessToken: 'test-token',
    );
    _controller.add(_current);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _current = const AuthState.unauthenticated();
    _controller.add(_current);
  }

  void emit(AuthState state) {
    _current = state;
    _controller.add(state);
  }

  @override
  Future<void> requestPasswordReset({
    required String email,
    String? redirectTo,
  }) async {}

  @override
  Future<void> updatePassword({
    required String accessToken,
    required String newPassword,
  }) async {}

  @override
  Future<void> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {}

  @override
  Future<void> signInWithSession({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
    bool? rememberSession,
  }) async {}

  @override
  Future<void> refreshSession() async {}

  Future<void> dispose() => _controller.close();
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSyncRequest());
  });

  testWidgets('App boots with empty product types list', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    final api = _MockSyncApi();
    when(() => api.sync(any())).thenAnswer((_) async {
      // Bloc-triggered sync at startup; respond with no data so the bloc
      // settles into idle/success and the screen can render.
      throw DioException(requestOptions: RequestOptions(path: '/v1/sync'));
    });
    final syncRepo = SyncRepository(db: db, api: api);
    final productTypeRepo = ProductTypeRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final organizationRepo = OrganizationRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final memberRepo = MemberRepository(db: db, idGenerator: IdGenerator());
    final memberInvitationRepo = MemberInvitationRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final memberJoinRequestRepo = MemberJoinRequestRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final deliveryTemplateRepo = DeliveryTemplateRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final contractRepo = ContractRepository(db: db, idGenerator: IdGenerator());
    final organizationRequestRepo = OrganizationRequestRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final producerRequestRepo = ProducerRequestRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final ownerRepo = OwnerRepository(db: db);
    final ownerInvitationRepo = OwnerInvitationRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final producerAccountRepo = ProducerAccountRepository(db: db);
    final basketExchangeRepo = BasketExchangeRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final notificationRepo = NotificationRepository(
      db: db,
      idGenerator: IdGenerator(),
    );

    // Use PRODUCER role so the router lands on /product-types after login.
    final authService = _TestAuthService(
      const AuthState.authenticated(
        producerId: 'producerAccountId',
        accessToken: 'test-token',
        roles: ['PRODUCER'],
      ),
    );

    await tester.pumpWidget(
      AmapEnLigneApp(
        prefs: prefs,
        db: db,
        productTypeRepo: productTypeRepo,
        organizationRepo: organizationRepo,
        memberRepo: memberRepo,
        memberInvitationRepo: memberInvitationRepo,
        memberJoinRequestRepo: memberJoinRequestRepo,
        deliveryTemplateRepo: deliveryTemplateRepo,
        contractRepo: contractRepo,
        organizationRequestRepo: organizationRequestRepo,
        producerRequestRepo: producerRequestRepo,
        ownerRepo: ownerRepo,
        ownerInvitationRepo: ownerInvitationRepo,
        producerAccountRepo: producerAccountRepo,
        basketExchangeRepo: basketExchangeRepo,
        notificationRepo: notificationRepo,
        errorReportRepo: ErrorReportRepository(
          db: db,
          idGenerator: IdGenerator(),
        ),
        authServiceOverride: authService,
        syncRepoOverride: syncRepo,
      ),
    );

    // Drain async work: auth bootstrap → session emission → BlocBuilder rebuild
    // → router redirect → ProductTypesScreen mount → initial sync attempt.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Types de produits'), findsOneWidget);
    expect(find.text('Aucun type de produit.'), findsOneWidget);

    await authService.dispose();
    await db.close();
  });

  testWidgets(
    'App redirects to login without SyncBloc provider crash when session expires',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      final api = _MockSyncApi();
      when(() => api.sync(any())).thenAnswer((_) async {
        throw DioException(requestOptions: RequestOptions(path: '/v1/sync'));
      });
      final syncRepo = SyncRepository(db: db, api: api);
      final productTypeRepo = ProductTypeRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final organizationRepo = OrganizationRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final memberRepo = MemberRepository(db: db, idGenerator: IdGenerator());
      final memberInvitationRepo = MemberInvitationRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final memberJoinRequestRepo = MemberJoinRequestRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final deliveryTemplateRepo = DeliveryTemplateRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final contractRepo = ContractRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final organizationRequestRepo = OrganizationRequestRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final producerRequestRepo = ProducerRequestRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final ownerRepo = OwnerRepository(db: db);
      final ownerInvitationRepo = OwnerInvitationRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final producerAccountRepo = ProducerAccountRepository(db: db);
      final basketExchangeRepo = BasketExchangeRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final notificationRepo = NotificationRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      // Use PRODUCER role so the router lands on /product-types after login.
      final authService = _TestAuthService(
        const AuthState.authenticated(
          producerId: 'producerAccountId',
          accessToken: 'test-token',
          roles: ['PRODUCER'],
        ),
      );

      await tester.pumpWidget(
        AmapEnLigneApp(
          prefs: prefs,
          db: db,
          productTypeRepo: productTypeRepo,
          organizationRepo: organizationRepo,
          memberRepo: memberRepo,
          memberInvitationRepo: memberInvitationRepo,
          memberJoinRequestRepo: memberJoinRequestRepo,
          deliveryTemplateRepo: deliveryTemplateRepo,
          contractRepo: contractRepo,
          organizationRequestRepo: organizationRequestRepo,
          producerRequestRepo: producerRequestRepo,
          ownerRepo: ownerRepo,
          ownerInvitationRepo: ownerInvitationRepo,
          producerAccountRepo: producerAccountRepo,
          basketExchangeRepo: basketExchangeRepo,
          notificationRepo: notificationRepo,
          errorReportRepo: ErrorReportRepository(
            db: db,
            idGenerator: IdGenerator(),
          ),
          authServiceOverride: authService,
          syncRepoOverride: syncRepo,
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('Types de produits'), findsOneWidget);

      authService.emit(const AuthState.unauthenticated());
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(
        find.text("Échec de l'authentification. Veuillez réessayer."),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await authService.dispose();
      await db.close();
    },
  );

  testWidgets(
    'SyncBloc is constructed eagerly on auth — admin landing triggers /v1/sync',
    (tester) async {
      // Regression: BlocProvider<SyncBloc> used to be lazy, so the bloc was
      // only constructed when a descendant called context.read<SyncBloc>().
      // Admin/coordinator/volunteer landing screens (now all on /dashboard)
      // never read SyncBloc, so the initial sync triggered by SyncBloc's
      // constructor (`add(SyncEvent.started())`) never fired. Owner
      // (/owner/dashboard) and producer (/product-types) landed on screens
      // that did read it, masking the bug.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      final api = _MockSyncApi();
      when(() => api.sync(any())).thenAnswer((_) async {
        throw DioException(requestOptions: RequestOptions(path: '/v1/sync'));
      });
      final syncRepo = SyncRepository(db: db, api: api);
      final productTypeRepo = ProductTypeRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final organizationRepo = OrganizationRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final memberRepo = MemberRepository(db: db, idGenerator: IdGenerator());
      final memberInvitationRepo = MemberInvitationRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final memberJoinRequestRepo = MemberJoinRequestRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final deliveryTemplateRepo = DeliveryTemplateRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final contractRepo = ContractRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final organizationRequestRepo = OrganizationRequestRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final producerRequestRepo = ProducerRequestRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final ownerRepo = OwnerRepository(db: db);
      final ownerInvitationRepo = OwnerInvitationRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final producerAccountRepo = ProducerAccountRepository(db: db);
      final basketExchangeRepo = BasketExchangeRepository(
        db: db,
        idGenerator: IdGenerator(),
      );
      final notificationRepo = NotificationRepository(
        db: db,
        idGenerator: IdGenerator(),
      );

      // ADMIN role → router lands on /dashboard, which does NOT read
      // SyncBloc. With lazy:true this never invoked the API.
      final authService = _TestAuthService(
        const AuthState.authenticated(
          producerId: 'amap-dev',
          accessToken: 'test-token',
          roles: ['ADMIN'],
        ),
      );

      await tester.pumpWidget(
        AmapEnLigneApp(
          prefs: prefs,
          db: db,
          productTypeRepo: productTypeRepo,
          organizationRepo: organizationRepo,
          memberRepo: memberRepo,
          memberInvitationRepo: memberInvitationRepo,
          memberJoinRequestRepo: memberJoinRequestRepo,
          deliveryTemplateRepo: deliveryTemplateRepo,
          contractRepo: contractRepo,
          organizationRequestRepo: organizationRequestRepo,
          producerRequestRepo: producerRequestRepo,
          ownerRepo: ownerRepo,
          ownerInvitationRepo: ownerInvitationRepo,
          producerAccountRepo: producerAccountRepo,
          basketExchangeRepo: basketExchangeRepo,
          notificationRepo: notificationRepo,
          errorReportRepo: ErrorReportRepository(
            db: db,
            idGenerator: IdGenerator(),
          ),
          authServiceOverride: authService,
          syncRepoOverride: syncRepo,
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      verify(() => api.sync(any())).called(greaterThanOrEqualTo(1));

      // Unmount the app subtree so SyncBloc.close() cancels its connectivity
      // subscription before we tear down the auth service and the database.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await authService.dispose();
      await db.close();
    },
  );

  testWidgets('Logout button signs out and returns to login screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    final api = _MockSyncApi();
    when(() => api.sync(any())).thenAnswer((_) async {
      throw DioException(requestOptions: RequestOptions(path: '/v1/sync'));
    });
    final syncRepo = SyncRepository(db: db, api: api);
    final productTypeRepo = ProductTypeRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final organizationRepo = OrganizationRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final memberRepo = MemberRepository(db: db, idGenerator: IdGenerator());
    final memberInvitationRepo = MemberInvitationRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final memberJoinRequestRepo = MemberJoinRequestRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final deliveryTemplateRepo = DeliveryTemplateRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final contractRepo = ContractRepository(db: db, idGenerator: IdGenerator());
    final organizationRequestRepo = OrganizationRequestRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final producerRequestRepo = ProducerRequestRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final ownerRepo = OwnerRepository(db: db);
    final ownerInvitationRepo = OwnerInvitationRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final producerAccountRepo = ProducerAccountRepository(db: db);
    final basketExchangeRepo = BasketExchangeRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final notificationRepo = NotificationRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    // Use PRODUCER role so the router lands on /product-types after login.
    final authService = _TestAuthService(
      const AuthState.authenticated(
        producerId: 'producerAccountId',
        accessToken: 'test-token',
        roles: ['PRODUCER'],
      ),
    );

    await tester.pumpWidget(
      AmapEnLigneApp(
        prefs: prefs,
        db: db,
        productTypeRepo: productTypeRepo,
        organizationRepo: organizationRepo,
        memberRepo: memberRepo,
        memberInvitationRepo: memberInvitationRepo,
        memberJoinRequestRepo: memberJoinRequestRepo,
        deliveryTemplateRepo: deliveryTemplateRepo,
        contractRepo: contractRepo,
        organizationRequestRepo: organizationRequestRepo,
        producerRequestRepo: producerRequestRepo,
        ownerRepo: ownerRepo,
        ownerInvitationRepo: ownerInvitationRepo,
        producerAccountRepo: producerAccountRepo,
        basketExchangeRepo: basketExchangeRepo,
        notificationRepo: notificationRepo,
        errorReportRepo: ErrorReportRepository(
          db: db,
          idGenerator: IdGenerator(),
        ),
        authServiceOverride: authService,
        syncRepoOverride: syncRepo,
      ),
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Types de produits'), findsOneWidget);

    // Open the navigation menu to access the sign-out item.
    await tester.tap(find.byKey(const Key('nav_menu_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));

    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(authService.signOutCalls, 1);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(
      find.text('Authentication failed. Please sign in again.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    await authService.dispose();
    await db.close();
  });

  testWidgets('Logout during an in-flight sync does not throw', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    final api = _MockSyncApi();
    final syncRelease = Completer<void>();
    when(() => api.sync(any())).thenAnswer((_) async {
      await syncRelease.future;
      throw DioException(requestOptions: RequestOptions(path: '/v1/sync'));
    });
    final syncRepo = SyncRepository(db: db, api: api);
    final productTypeRepo = ProductTypeRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final organizationRepo = OrganizationRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final memberRepo = MemberRepository(db: db, idGenerator: IdGenerator());
    final memberInvitationRepo = MemberInvitationRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final memberJoinRequestRepo = MemberJoinRequestRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final deliveryTemplateRepo = DeliveryTemplateRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final contractRepo = ContractRepository(db: db, idGenerator: IdGenerator());
    final organizationRequestRepo = OrganizationRequestRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final producerRequestRepo = ProducerRequestRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final ownerRepo = OwnerRepository(db: db);
    final ownerInvitationRepo = OwnerInvitationRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final producerAccountRepo = ProducerAccountRepository(db: db);
    final basketExchangeRepo = BasketExchangeRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final notificationRepo = NotificationRepository(
      db: db,
      idGenerator: IdGenerator(),
    );
    final authService = _TestAuthService(
      const AuthState.authenticated(
        producerId: 'producerAccountId',
        accessToken: 'test-token',
        roles: ['PRODUCER'],
      ),
    );

    await tester.pumpWidget(
      AmapEnLigneApp(
        prefs: prefs,
        db: db,
        productTypeRepo: productTypeRepo,
        organizationRepo: organizationRepo,
        memberRepo: memberRepo,
        memberInvitationRepo: memberInvitationRepo,
        memberJoinRequestRepo: memberJoinRequestRepo,
        deliveryTemplateRepo: deliveryTemplateRepo,
        contractRepo: contractRepo,
        organizationRequestRepo: organizationRequestRepo,
        producerRequestRepo: producerRequestRepo,
        ownerRepo: ownerRepo,
        ownerInvitationRepo: ownerInvitationRepo,
        producerAccountRepo: producerAccountRepo,
        basketExchangeRepo: basketExchangeRepo,
        notificationRepo: notificationRepo,
        errorReportRepo: ErrorReportRepository(
          db: db,
          idGenerator: IdGenerator(),
        ),
        authServiceOverride: authService,
        syncRepoOverride: syncRepo,
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('nav_menu_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_menu_button')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Se déconnecter'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    syncRelease.complete();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(authService.signOutCalls, 1);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await authService.dispose();
    await db.close();
  });
}
