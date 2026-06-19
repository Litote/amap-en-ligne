import 'dart:async';

import 'package:amap_en_ligne/data/local/database.dart';
import 'package:amap_en_ligne/domain/auth/auth_error.dart';
import 'package:amap_en_ligne/domain/auth/remembered_user_context.dart';
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/auth/user_role.dart';
import 'package:amap_en_ligne/presentation/auth/auth_event.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:bloc/bloc.dart';

/// UI-facing auth bloc. Owns the login form state and proxies session
/// transitions from `AuthService.authState`.
///
/// `bootstrap()` runs once on construction via `AuthEvent.started`. The
/// service stream is subscribed eagerly so the bloc reflects external
/// session changes (token refresh failure, programmatic logout from the
/// dio 401 interceptor).
class AuthBloc extends Bloc<AuthEvent, AuthViewState> {
  AuthBloc({
    required AuthService service,
    required AppDatabase db,
    RememberedUserContextStore? rememberedUserContextStore,
    String serverId = '',
    Future<void> Function()? onLogout,
  }) : _service = service,
       _db = db,
       _rememberedUserContextStore =
           rememberedUserContextStore ?? _NoopRememberedUserContextStore(),
       _serverId = serverId,
       _onLogout = onLogout,
       super(const AuthViewState()) {
    on<AuthStarted>(_onStarted);
    on<AuthSessionChanged>(_onSessionChanged);
    on<AuthOrganizationIdChanged>(_onOrganizationIdChanged);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);

    _subscription = _service.authState.listen((session) {
      add(AuthEvent.sessionChanged(session));
    });

    add(const AuthEvent.started());
  }

  final AuthService _service;
  final AppDatabase _db;
  final RememberedUserContextStore _rememberedUserContextStore;
  final String _serverId;
  final Future<void> Function()? _onLogout;
  late final StreamSubscription<AuthState> _subscription;
  StreamSubscription<String?>? _orgIdSub;
  bool _logoutRequested = false;

  Future<void> _onStarted(
    AuthStarted event,
    Emitter<AuthViewState> emit,
  ) async {
    try {
      await _service.bootstrap();
    } catch (_) {
      // Corrupted stored session — treat as unauthenticated so the user can
      // log in again instead of being stuck on an infinite initializing screen.
      await _service.signOut();
    }
    // The bootstrap emits onto authState; the sessionChanged handler will
    // pick it up. We just clear the initializing flag here.
    emit(state.copyWith(initializing: false));
  }

  Future<void> _onSessionChanged(
    AuthSessionChanged event,
    Emitter<AuthViewState> emit,
  ) async {
    final session = event.session;
    _orgIdSub?.cancel();
    _orgIdSub = null;

    switch (session) {
      case Authenticated(:final producerId, :final roles):
        _logoutRequested = false;
        final role = roles.resolveRole();

        emit(
          state.copyWith(
            submitting: false,
            logoutRequested: false,
            producerId: producerId,
            isAdmin: roles.any((r) => r == 'ADMIN' || r == 'OWNER'),
            role: role,
            memberRoles: roles.resolveMemberRoles(),
            lastError: null,
            initializing: false,
          ),
        );

        if (role != UserRole.producer) {
          // Subscribe to organization ID changes and emit whenever it changes.
          // Use `await emit.forEach` to properly handle the stream and avoid
          // emitting after the event handler completes.
          _orgIdSub = _db
              .watchEffectiveOrganizationId(producerId)
              .listen(
                (orgId) {
                  // Emit organization ID updates as internal events to avoid
                  // emitting after event handler completes.
                  add(AuthEvent.organizationIdChanged(orgId));
                },
                onError: (Object _, StackTrace _) {
                  // Ignore errors from the organization stream
                },
              );
        }
      case Unauthenticated():
        final manualLogout = _logoutRequested;
        final sessionExpired = state.producerId != null && !manualLogout;
        _logoutRequested = false;
        emit(
          state.copyWith(
            producerId: null,
            isAdmin: false,
            role: UserRole.memberNoRole,
            initializing: false,
            submitting: false,
            logoutRequested: manualLogout,
            lastError: sessionExpired ? AuthError.unknown : null,
          ),
        );
    }
  }

  void _onOrganizationIdChanged(
    AuthOrganizationIdChanged event,
    Emitter<AuthViewState> emit,
  ) {
    emit(state.copyWith(organizationId: event.organizationId));
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthViewState> emit,
  ) async {
    emit(
      state.copyWith(submitting: true, logoutRequested: false, lastError: null),
    );
    try {
      await _service.signIn(
        email: event.email,
        password: event.password,
        rememberSession: event.rememberMe,
      );
      await _rememberedUserContextStore.write(
        RememberedUserContext(
          email: event.email,
          serverId: _serverId,
          rememberMe: event.rememberMe,
        ),
      );
      emit(state.copyWith(submitting: false));
    } on AuthException catch (e) {
      emit(state.copyWith(submitting: false, lastError: e.error));
    } catch (_) {
      emit(state.copyWith(submitting: false, lastError: AuthError.unknown));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthViewState> emit,
  ) async {
    _logoutRequested = true;
    emit(state.copyWith(logoutRequested: true));
    await _onLogout?.call();
    await _rememberedUserContextStore.clear();
    await _service.signOut();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await _orgIdSub?.cancel();
    return super.close();
  }
}

class _NoopRememberedUserContextStore implements RememberedUserContextStore {
  @override
  Future<void> clear() async {}

  @override
  Future<RememberedUserContext?> read({required String serverId}) async => null;

  @override
  Future<void> write(RememberedUserContext context) async {}
}
