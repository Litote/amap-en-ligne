import 'dart:async';

import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/auth/auth_event.dart';
import 'package:amap_en_ligne/presentation/auth/auth_view_state.dart';
import 'package:amap_en_ligne/presentation/nav/nav_event.dart';
import 'package:amap_en_ligne/presentation/nav/nav_items_builder.dart';
import 'package:amap_en_ligne/presentation/nav/nav_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Manages the navigation menu state.
///
/// Subscribes to [AuthBloc] changes and rebuilds the item list whenever the
/// authenticated role changes. The menu is closed on every role change so it
/// cannot remain open after a session transition.
class NavBloc extends Bloc<NavEvent, NavState> {
  NavBloc({required AuthBloc authBloc})
    : _authBloc = authBloc,
      super(const NavState()) {
    on<NavOpened>(_onOpened);
    on<NavClosed>(_onClosed);
    on<NavRoleChanged>(_onRoleChanged);

    // Initialise with current role synchronously.
    add(_buildRoleChangedEvent(authBloc.state));

    // Keep in sync with subsequent auth state changes.
    _authSub = authBloc.stream.listen((authState) {
      add(_buildRoleChangedEvent(authState));
    });
  }

  final AuthBloc _authBloc;
  late final StreamSubscription<AuthViewState> _authSub;

  NavEvent _buildRoleChangedEvent(AuthViewState state) =>
      NavEvent.roleChanged(role: state.role, memberRoles: state.memberRoles);

  void _onOpened(NavOpened event, Emitter<NavState> emit) =>
      emit(state.copyWith(isOpen: true));

  void _onClosed(NavClosed event, Emitter<NavState> emit) =>
      emit(state.copyWith(isOpen: false));

  void _onRoleChanged(NavRoleChanged event, Emitter<NavState> emit) {
    void logout() => _authBloc.add(const AuthEvent.logoutRequested());
    final items = event.memberRoles.isNotEmpty
        ? buildNavItems(event.memberRoles, logout)
        : buildNavItemsForRole(event.role, logout);
    emit(
      state.copyWith(
        role: event.role,
        memberRoles: event.memberRoles,
        items: items,
        isOpen: false,
      ),
    );
  }

  @override
  Future<void> close() {
    _authSub.cancel();
    return super.close();
  }
}
