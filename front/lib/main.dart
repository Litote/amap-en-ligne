import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:amap_en_ligne/data/auth/auth_service_factory.dart';
import 'package:amap_en_ligne/data/auth/auth_token_storage.dart';
import 'package:amap_en_ligne/data/auth/remembered_user_context_storage.dart';
import 'package:amap_en_ligne/data/id_generator.dart';
import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/data/local/local_database_export_service.dart';
import 'package:amap_en_ligne/data/network/admin_api.dart';
import 'package:amap_en_ligne/data/network/dio_factory.dart';
import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/data/network/sync_api.dart';
import 'package:amap_en_ligne/data/push/fcm_push_token_source.dart';
import 'package:amap_en_ligne/data/push/push_registration_service.dart';
import 'package:amap_en_ligne/data/repositories/attendance_email_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/error_report_repository.dart';
import 'package:amap_en_ligne/data/repositories/basket_exchange_repository.dart';
import 'package:amap_en_ligne/data/repositories/device_token_repository.dart';
import 'package:amap_en_ligne/data/repositories/notification_repository.dart';
import 'package:amap_en_ligne/data/repositories/delivery_template_repository.dart';
import 'package:amap_en_ligne/data/repositories/contract_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_invitation_repository.dart';
import 'package:amap_en_ligne/data/repositories/member_join_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_repository.dart';
import 'package:amap_en_ligne/data/repositories/organization_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_repository.dart';
import 'package:amap_en_ligne/data/repositories/owner_invitation_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_account_repository.dart';
import 'package:amap_en_ligne/data/repositories/producer_request_repository.dart';
import 'package:amap_en_ligne/data/repositories/product_type_repository.dart';
import 'package:amap_en_ligne/data/server/server_catalog.dart';
import 'package:amap_en_ligne/data/server/server_config_storage.dart';
import 'package:amap_en_ligne/data/server/server_presets.dart';
import 'package:amap_en_ligne/data/server/web_discovery.dart';
import 'package:amap_en_ligne/data/sync/sync_repository.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/remembered_user_context.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/common/app_time_picker.dart';
import 'package:amap_en_ligne/presentation/common/french_date_formatting.dart';
import 'package:amap_en_ligne/presentation/router.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_offline_listener.dart';
import 'package:amap_en_ligne/presentation/sync/sync_state.dart';
import 'package:amap_en_ligne/data/web_initial_fragment.dart';
import 'package:amap_en_ligne/firebase_options.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  // Capture the URL fragment before usePathUrlStrategy / go_router strips it.
  // GoTrue recovery redirects land as /reset-password#access_token=...
  if (kIsWeb) webInitialFragment = Uri.base.fragment;
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await ensureFrenchDateFormattingInitialized();
  // Best-effort Firebase init for push (ADR-005). With placeholder config this
  // still succeeds; real delivery requires real Firebase config. Any failure
  // disables push without blocking app boot.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Push disabled — the app boots and works without it.
  }
  final prefs = await SharedPreferences.getInstance();

  // On web, auto-discover the server configuration from the current origin so
  // the deployed CloudFront app points at the right backend instead of the
  // localhost preset. The result is persisted once so subsequent launches skip
  // the fetch and boot from the stored config. Falls back silently to the
  // preset list on failure (network error, unknown format, non-web platform).
  final webConfig = await tryWebDiscovery();
  if (webConfig != null) {
    final storage = ServerConfigStorage(prefs: prefs);
    await storage.write(webConfig);
  }

  final db = AppDatabase();
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
  final errorReportRepo = ErrorReportRepository(
    db: db,
    idGenerator: IdGenerator(),
  );

  if (_sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
      },
      appRunner: () => runApp(
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
          errorReportRepo: errorReportRepo,
        ),
      ),
    );
  } else {
    runApp(
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
        errorReportRepo: errorReportRepo,
      ),
    );
  }
}

/// Top-level widget. Owns:
///  - the `ServerConfig` selection (persisted in `SharedPreferences`),
///  - the `AuthService` matching the selected server,
///  - the `SyncRepository` whose dio is wired to the selected backend URL.
///
/// The app always starts on the public home screen (`/`). If no server has
/// been selected yet, the first preset is used as the default so that the
/// public endpoints (organizations list, org creation) are available
/// immediately. On server switch we tear down the auth+sync stack and
/// re-build it with the new config, keyed off `ServerConfig.id`.
class AmapEnLigneApp extends StatefulWidget {
  AmapEnLigneApp({
    super.key,
    required this.prefs,
    required this.db,
    required this.productTypeRepo,
    required this.organizationRepo,
    required this.memberRepo,
    required this.memberInvitationRepo,
    required this.memberJoinRequestRepo,
    required this.deliveryTemplateRepo,
    required this.contractRepo,
    required this.organizationRequestRepo,
    required this.producerRequestRepo,
    required this.ownerRepo,
    required this.ownerInvitationRepo,
    required this.producerAccountRepo,
    required this.basketExchangeRepo,
    required this.notificationRepo,
    required this.errorReportRepo,
    ServerCatalog? serverCatalog,
    this.authServiceOverride,
    this.syncRepoOverride,
  }) : serverCatalog = serverCatalog ?? StaticServerCatalog();

  final SharedPreferences prefs;
  final AppDatabase db;
  final ProductTypeRepository productTypeRepo;
  final OrganizationRepository organizationRepo;
  final MemberRepository memberRepo;
  final MemberInvitationRepository memberInvitationRepo;
  final MemberJoinRequestRepository memberJoinRequestRepo;
  final DeliveryTemplateRepository deliveryTemplateRepo;
  final ContractRepository contractRepo;
  final OrganizationRequestRepository organizationRequestRepo;
  final ProducerRequestRepository producerRequestRepo;
  final OwnerRepository ownerRepo;
  final OwnerInvitationRepository ownerInvitationRepo;
  final ProducerAccountRepository producerAccountRepo;
  final BasketExchangeRepository basketExchangeRepo;
  final NotificationRepository notificationRepo;
  final ErrorReportRepository errorReportRepo;
  final ServerCatalog serverCatalog;

  /// Test seam — when non-null, skips the server picker and the factory
  /// and uses the provided service directly. Used by `widget_test.dart`.
  final AuthService? authServiceOverride;

  /// Test seam — when non-null, replaces the dio-built `SyncRepository`
  /// so widget tests can inject a mocked `SyncApi`.
  final SyncRepository? syncRepoOverride;

  @override
  State<AmapEnLigneApp> createState() => _AmapEnLigneAppState();
}

class _AmapEnLigneAppState extends State<AmapEnLigneApp> {
  late final _serverStorage = ServerConfigStorage(prefs: widget.prefs);
  late final _tokenStorage = AdaptiveAuthTokenStorage(
    prefs: widget.prefs,
    isWeb: kIsWeb,
  );
  late final RememberedUserContextStore _rememberedUserContextStore =
      SharedPreferencesRememberedUserContextStore(prefs: widget.prefs);

  ServerConfig _resolveConfig() {
    if (widget.authServiceOverride != null) {
      final options = widget.serverCatalog.listSelectionOptions();
      return options.isNotEmpty ? options.first : serverPresets.first;
    }
    return _serverStorage.read() ?? serverPresets.first;
  }

  late ServerConfig _serverConfig = _resolveConfig();

  Future<void> _onSwitchServer() async {
    await _tokenStorage.clear();
    await _serverStorage.clear();
    setState(() => _serverConfig = serverPresets.first);
  }

  Future<void> _onServerSelected(ServerConfig config) async {
    await _serverStorage.write(config);
    setState(() => _serverConfig = config);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      useMaterial3: true,
    );
    return _AuthenticatedAppShell(
      key: ValueKey(_serverConfig.id),
      theme: theme,
      config: _serverConfig,
      tokenStorage: _tokenStorage,
      rememberedUserContextStore: _rememberedUserContextStore,
      authServiceOverride: widget.authServiceOverride,
      syncRepoOverride: widget.syncRepoOverride,
      db: widget.db,
      productTypeRepo: widget.productTypeRepo,
      organizationRepo: widget.organizationRepo,
      memberRepo: widget.memberRepo,
      memberInvitationRepo: widget.memberInvitationRepo,
      memberJoinRequestRepo: widget.memberJoinRequestRepo,
      deliveryTemplateRepo: widget.deliveryTemplateRepo,
      contractRepo: widget.contractRepo,
      organizationRequestRepo: widget.organizationRequestRepo,
      producerRequestRepo: widget.producerRequestRepo,
      ownerRepo: widget.ownerRepo,
      ownerInvitationRepo: widget.ownerInvitationRepo,
      producerAccountRepo: widget.producerAccountRepo,
      basketExchangeRepo: widget.basketExchangeRepo,
      notificationRepo: widget.notificationRepo,
      errorReportRepo: widget.errorReportRepo,
      onSwitchServer: _onSwitchServer,
      onServerSelected: _onServerSelected,
    );
  }
}

/// Subtree mounted once a `ServerConfig` is known. Keyed by config id at
/// the parent level so switching servers tears down and recreates the
/// whole stack (auth bloc, sync bloc, dio, router).
class _AuthenticatedAppShell extends StatefulWidget {
  const _AuthenticatedAppShell({
    super.key,
    required this.theme,
    required this.config,
    required this.tokenStorage,
    required this.rememberedUserContextStore,
    required this.authServiceOverride,
    required this.syncRepoOverride,
    required this.db,
    required this.productTypeRepo,
    required this.organizationRepo,
    required this.memberRepo,
    required this.memberInvitationRepo,
    required this.memberJoinRequestRepo,
    required this.deliveryTemplateRepo,
    required this.contractRepo,
    required this.organizationRequestRepo,
    required this.producerRequestRepo,
    required this.ownerRepo,
    required this.ownerInvitationRepo,
    required this.producerAccountRepo,
    required this.basketExchangeRepo,
    required this.notificationRepo,
    required this.errorReportRepo,
    required this.onSwitchServer,
    required this.onServerSelected,
  });

  final ThemeData theme;
  final ServerConfig config;
  final AuthTokenStorage tokenStorage;
  final RememberedUserContextStore rememberedUserContextStore;
  final AuthService? authServiceOverride;
  final SyncRepository? syncRepoOverride;
  final AppDatabase db;
  final ProductTypeRepository productTypeRepo;
  final OrganizationRepository organizationRepo;
  final MemberRepository memberRepo;
  final MemberInvitationRepository memberInvitationRepo;
  final MemberJoinRequestRepository memberJoinRequestRepo;
  final DeliveryTemplateRepository deliveryTemplateRepo;
  final ContractRepository contractRepo;
  final OrganizationRequestRepository organizationRequestRepo;
  final ProducerRequestRepository producerRequestRepo;
  final OwnerRepository ownerRepo;
  final OwnerInvitationRepository ownerInvitationRepo;
  final ProducerAccountRepository producerAccountRepo;
  final BasketExchangeRepository basketExchangeRepo;
  final NotificationRepository notificationRepo;
  final ErrorReportRepository errorReportRepo;
  final VoidCallback onSwitchServer;
  final ValueChanged<ServerConfig> onServerSelected;

  @override
  State<_AuthenticatedAppShell> createState() => _AuthenticatedAppShellState();
}

/// Registers the device's push token (ADR-005) once sync has established the
/// user's authorized private feeds. Mounted inside the `SyncBloc` provider, so it
/// only acts for authenticated sessions (sync is disabled when logged out — no
/// registration, no FORBIDDEN). Binds token rotation for the session's lifetime.
class _PushRegistrationBinder extends StatefulWidget {
  const _PushRegistrationBinder({required this.child});

  final Widget child;

  @override
  State<_PushRegistrationBinder> createState() =>
      _PushRegistrationBinderState();
}

class _PushRegistrationBinderState extends State<_PushRegistrationBinder> {
  StreamSubscription<String>? _refreshSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshSub = context.read<PushRegistrationService>().bindTokenRefresh();
    });
  }

  @override
  void dispose() {
    _refreshSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SyncBloc, SyncState>(
      listenWhen: (previous, current) => current is SyncSucceeded,
      listener: (context, state) {
        // Best-effort: register the current push token on the authorized feeds.
        context.read<PushRegistrationService>().registerCurrentDevice();
      },
      child: widget.child,
    );
  }
}

class _AuthenticatedAppShellState extends State<_AuthenticatedAppShell> {
  late final AuthService _authService =
      widget.authServiceOverride ??
      buildAuthService(config: widget.config, storage: widget.tokenStorage);
  late final SyncRepository _syncRepo =
      widget.syncRepoOverride ??
      SyncRepository(
        db: widget.db,
        api: SyncApi(
          buildSyncDio(
            backendUrl: widget.config.backendUrl,
            auth: _authService,
          ),
        ),
      );
  late final PublicApi _publicApi = PublicApi(
    buildPublicDio(backendUrl: widget.config.backendUrl),
  );
  late final AdminApi _adminApi = AdminApi(
    buildSyncDio(backendUrl: widget.config.backendUrl, auth: _authService),
  );
  late final AttendanceEmailRequestRepository
  _attendanceEmailRequestRepository = AttendanceEmailRequestRepository(
    db: widget.db,
  );
  late final DeviceTokenRepository _deviceTokenRepo = DeviceTokenRepository(
    db: widget.db,
    idGenerator: IdGenerator(),
  );
  late final PushRegistrationService
  _pushRegistration = PushRegistrationService(
    source: const FcmPushTokenSource(),
    repository: _deviceTokenRepo,
    // Server-authoritative: register only on the private feeds the server
    // actually granted (persisted as sync cursors), never guessed from claims.
    resolvePrivateFeeds: () async =>
        privateFeedScopeKeys((await widget.db.readAllScopeCursors()).keys),
  );
  late final LocalDatabaseExportService _databaseExportService =
      LocalDatabaseExportService(db: widget.db);
  // Lets SyncOfflineListener, which sits above the MaterialApp, show
  // snackbars on whatever screen is currently displayed.
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late final _wiredAuthBloc = AuthBloc(
    service: _authService,
    db: widget.db,
    rememberedUserContextStore: widget.rememberedUserContextStore,
    serverId: widget.config.id,
    onLogout: _syncRepo.clearAll,
  );
  late final _router = buildRouter(authBloc: _wiredAuthBloc);

  @override
  void dispose() {
    _wiredAuthBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: widget.db),
        RepositoryProvider<LocalDatabaseExportService>.value(
          value: _databaseExportService,
        ),
        RepositoryProvider<ProductTypeRepository>.value(
          value: widget.productTypeRepo,
        ),
        RepositoryProvider<OrganizationRepository>.value(
          value: widget.organizationRepo,
        ),
        RepositoryProvider<MemberRepository>.value(value: widget.memberRepo),
        RepositoryProvider<MemberInvitationRepository>.value(
          value: widget.memberInvitationRepo,
        ),
        RepositoryProvider<MemberJoinRequestRepository>.value(
          value: widget.memberJoinRequestRepo,
        ),
        RepositoryProvider<DeliveryTemplateRepository>.value(
          value: widget.deliveryTemplateRepo,
        ),
        RepositoryProvider<ContractRepository>.value(
          value: widget.contractRepo,
        ),
        RepositoryProvider<OrganizationRequestRepository>.value(
          value: widget.organizationRequestRepo,
        ),
        RepositoryProvider<ProducerRequestRepository>.value(
          value: widget.producerRequestRepo,
        ),
        RepositoryProvider<OwnerRepository>.value(value: widget.ownerRepo),
        RepositoryProvider<OwnerInvitationRepository>.value(
          value: widget.ownerInvitationRepo,
        ),
        RepositoryProvider<ProducerAccountRepository>.value(
          value: widget.producerAccountRepo,
        ),
        RepositoryProvider<BasketExchangeRepository>.value(
          value: widget.basketExchangeRepo,
        ),
        RepositoryProvider<NotificationRepository>.value(
          value: widget.notificationRepo,
        ),
        RepositoryProvider<DeviceTokenRepository>.value(
          value: _deviceTokenRepo,
        ),
        RepositoryProvider<PushRegistrationService>.value(
          value: _pushRegistration,
        ),
        RepositoryProvider<SyncRepository>.value(value: _syncRepo),
        RepositoryProvider<AuthService>.value(value: _authService),
        RepositoryProvider<RememberedUserContextStore>.value(
          value: widget.rememberedUserContextStore,
        ),
        RepositoryProvider<ServerConfig>.value(value: widget.config),
        RepositoryProvider<PublicApi>.value(value: _publicApi),
        RepositoryProvider<AdminApi>.value(value: _adminApi),
        RepositoryProvider<AttendanceEmailRequestRepository>.value(
          value: _attendanceEmailRequestRepository,
        ),
        RepositoryProvider<ErrorReportRepository>.value(
          value: widget.errorReportRepo,
        ),
        RepositoryProvider<VoidCallback>.value(value: widget.onSwitchServer),
        RepositoryProvider<ValueChanged<ServerConfig>>.value(
          value: widget.onServerSelected,
        ),
      ],
      child: BlocProvider.value(
        value: _wiredAuthBloc,
        child: BlocBuilder<AuthBloc, AuthViewState>(
          buildWhen: (a, b) => a.producerId != b.producerId,
          builder: (context, state) {
            final app = MaterialApp.router(
              title: 'Amap en Ligne',
              scaffoldMessengerKey: _scaffoldMessengerKey,
              locale: appLocale,
              supportedLocales: const [appLocale],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              theme: widget.theme,
              routerConfig: _router,
            );
            final producerId = state.producerId;
            return BlocProvider(
              key: ValueKey('${state.producerId}_${state.organizationId}'),
              // Eager: SyncBloc's constructor dispatches the initial sync.
              // Without lazy:false, landing pages that never read SyncBloc
              // (e.g. /dashboard) would skip the first sync until a
              // downstream screen happened to read it.
              lazy: false,
              create: (_) => SyncBloc(
                repository: _syncRepo,
                tenantId: producerId ?? '',
                enabled: producerId != null,
                mutationStream: widget.db.onMutationEnqueued,
                authService: _authService,
              ),
              child: _PushRegistrationBinder(
                child: SyncOfflineListener(
                  messengerKey: _scaffoldMessengerKey,
                  child: app,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
