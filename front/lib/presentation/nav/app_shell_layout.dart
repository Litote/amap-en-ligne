import 'package:amap_en_ligne/presentation/auth/auth_bloc.dart';
import 'package:amap_en_ligne/presentation/nav/nav_bloc.dart';
import 'package:amap_en_ligne/presentation/nav/nav_event.dart';
import 'package:amap_en_ligne/presentation/nav/nav_menu_widget.dart';
import 'package:amap_en_ligne/presentation/nav/nav_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Responsive shell that wraps the authenticated portion of the app.
///
/// Provides a [NavBloc] and chooses the appropriate navigation layout:
/// - `width < 600`: overlay drawer (full-screen menu on top of content)
/// - `600 ≤ width < 1024`: retractable side rail (overlay when open)
/// - `width ≥ 1024`: permanent side navigation bar always visible
class AppShellLayout extends StatelessWidget {
  const AppShellLayout({super.key, required this.child, this.currentLocation});

  final Widget child;

  /// Path of the displayed screen; its menu entry is highlighted (null: none).
  final String? currentLocation;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (ctx) => NavBloc(authBloc: ctx.read<AuthBloc>()),
    child: _AppShellLayoutBody(currentLocation: currentLocation, child: child),
  );
}

class _AppShellLayoutBody extends StatelessWidget {
  const _AppShellLayoutBody({required this.child, this.currentLocation});

  final Widget child;
  final String? currentLocation;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (width >= 1024) {
        return _DesktopLayout(currentLocation: currentLocation, child: child);
      }
      return _MobileLayout(currentLocation: currentLocation, child: child);
    },
  );
}

/// Desktop layout — permanent sidebar always visible alongside the content.
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.child, this.currentLocation});

  final Widget child;
  final String? currentLocation;

  @override
  Widget build(BuildContext context) => BlocBuilder<NavBloc, NavState>(
    builder: (context, state) => Row(
      children: [
        SizedBox(
          width: 280,
          child: NavMenuWidget(
            items: state.items,
            currentLocation: currentLocation,
          ),
        ),
        const VerticalDivider(width: 1),
        // Own semantics container: the content is a navigator whose route
        // barrier (BlockSemantics) would otherwise hide the sidebar, painted
        // before it, from screen readers.
        Expanded(
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            child: child,
          ),
        ),
      ],
    ),
  );
}

/// Mobile/tablet layout — overlay menu on top of the content when open.
class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.child, this.currentLocation});

  final Widget child;
  final String? currentLocation;

  @override
  Widget build(BuildContext context) => BlocBuilder<NavBloc, NavState>(
    builder: (context, state) => Stack(
      children: [
        child,
        if (state.isOpen)
          NavMenuWidget(
            items: state.items,
            currentLocation: currentLocation,
            onClose: () => context.read<NavBloc>().add(const NavEvent.closed()),
          ),
      ],
    ),
  );
}
