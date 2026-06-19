import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/home/home_bloc.dart';
import 'package:amap_en_ligne/presentation/home/home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

const String _gitCommitHash = String.fromEnvironment(
  'GIT_COMMIT_HASH',
  defaultValue: 'dev',
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(publicApi: context.read<PublicApi>()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const SizedBox(height: 32),
              _ActionCard(
                title: "J'ai déjà un compte",
                subtitle: 'Connectez-vous à votre espace personnel',
                buttonLabel: 'SE CONNECTER',
                buttonColor: Colors.green,
                onPressed: () => context.go('/login'),
              ),
              const SizedBox(height: 16),
              const _JoinAmapCard(),
              const SizedBox(height: 16),
              _ActionCard(
                title: 'Je veux créer une nouvelle organisation',
                subtitle: "Créer une AMAP\nC'est totalement gratuit !",
                buttonLabel: 'CRÉER UNE AMAP',
                buttonColor: Colors.orange,
                onPressed: () => context.go('/register'),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                title: 'Je suis producteur',
                subtitle: 'Demandez votre espace producteur',
                buttonLabel: 'DEVENIR PRODUCTEUR',
                onPressed: () => context.go('/register/producer'),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const _InfoSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/wordmark.svg', height: 48);
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    this.buttonColor,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color? buttonColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            FilledButton(
              style: buttonColor == null
                  ? null
                  : FilledButton.styleFrom(backgroundColor: buttonColor),
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinAmapCard extends StatefulWidget {
  const _JoinAmapCard();

  @override
  State<_JoinAmapCard> createState() => _JoinAmapCardState();
}

class _JoinAmapCardState extends State<_JoinAmapCard> {
  Organization? _selected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Je veux rejoindre une AMAP',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Préinscrivez-vous',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            BlocListener<HomeBloc, HomeState>(
              listener: (context, state) {
                if (state is HomeLoaded &&
                    _selected == null &&
                    state.organizations.isNotEmpty) {
                  setState(() => _selected = state.organizations.first);
                }
              },
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  return switch (state) {
                    HomeLoading() => const LinearProgressIndicator(),
                    HomeLoaded(:final organizations) => _OrganizationDropdown(
                      organizations: organizations,
                      selected: _selected,
                      onChanged: (org) => setState(() => _selected = org),
                    ),
                    HomeError() => Text(
                      'Organisations indisponibles.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    HomeInitial() => const SizedBox.shrink(),
                  };
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                final orgId = _selected?.organizationId;
                final path = orgId != null
                    ? '/amap-search?organizationId=$orgId'
                    : '/amap-search';
                context.go(path);
              },
              child: const Text("S'INSCRIRE À UNE AMAP"),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganizationDropdown extends StatelessWidget {
  const _OrganizationDropdown({
    required this.organizations,
    required this.selected,
    required this.onChanged,
  });

  final List<Organization> organizations;
  final Organization? selected;
  final ValueChanged<Organization?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (organizations.isEmpty) return const SizedBox.shrink();
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Choisir une AMAP',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButton<Organization>(
        value: selected,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: organizations
            .map((org) => DropdownMenuItem(value: org, child: Text(org.name)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Qu'est-ce qu'une AMAP ?",
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          "Les AMAP (Association pour le Maintien d'une Agriculture Paysanne) "
          'créent des liens directs entre producteurs et consommateurs autour '
          'de produits locaux et de saison.',
        ),
        const SizedBox(height: 16),
        Text(
          'Amap en Ligne est gratuit, open-source et auto-hébergeable.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            alignment: Alignment.centerLeft,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
          onPressed: () => _showAboutAmap(context),
          child: const Text('À propos'),
        ),
      ],
    );
  }

  Future<void> _showAboutAmap(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    final versionText = _gitCommitHash == 'dev'
        ? 'v${info.version} (build ${info.buildNumber})'
        : 'v${info.version} (build ${info.buildNumber}) • $_gitCommitHash';
    showAboutDialog(
      context: context,
      applicationName: 'Amap en Ligne',
      applicationVersion: versionText,
      applicationLegalese: 'Gratuit, open-source et auto-hébergeable.',
    );
  }
}
