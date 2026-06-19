import 'package:amap_en_ligne/presentation/nav/nav_bloc.dart';
import 'package:amap_en_ligne/presentation/nav/nav_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Width threshold above which the navigation is always visible (sidebar
/// mode) and the hamburger button is hidden from the AppBar.
const _desktopBreakpoint = 1024.0;

/// A drop-in replacement for [Scaffold] in connected (authenticated) screens.
///
/// On screens narrower than [_desktopBreakpoint] the AppBar shows a hamburger
/// icon that dispatches [NavEvent.opened] to the nearest [NavBloc]. On wider
/// screens the sidebar is always visible, so the hamburger is omitted.
class ConnectedScaffold extends StatelessWidget {
  const ConnectedScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _desktopBreakpoint;
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            leading: isDesktop
                ? null
                : Semantics(
                    button: true,
                    label: 'Ouvrir le menu de navigation',
                    onTap: () =>
                        context.read<NavBloc>().add(const NavEvent.opened()),
                    excludeSemantics: true,
                    child: IconButton(
                      key: const Key('nav_menu_button'),
                      icon: const Icon(Icons.menu),
                      tooltip: 'Ouvrir le menu de navigation',
                      onPressed: () =>
                          context.read<NavBloc>().add(const NavEvent.opened()),
                    ),
                  ),
            automaticallyImplyLeading: !isDesktop,
            actions: actions,
          ),
          body: body,
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }
}
