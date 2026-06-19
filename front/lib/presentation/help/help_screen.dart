import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Screen title — kept as a constant so tests can find it by text.
const _kScreenTitle = 'Aide';

class _FaqEntry {
  const _FaqEntry(this.question, this.answer);

  final String question;
  final String answer;
}

const _kFaqEntries = [
  _FaqEntry(
    "Je n'ai pas reçu l'e-mail d'activation ou d'invitation",
    "L'e-mail peut mettre quelques minutes à arriver ; vérifiez votre "
        'dossier de courrier indésirable. Le lien a une durée limitée (en '
        "général 7 jours) — s'il a expiré, demandez à votre administrateur "
        'de vous renvoyer une invitation.',
  ),
  _FaqEntry(
    "J'ai oublié mon mot de passe",
    "Sur l'écran de connexion, touchez « Mot de passe oublié ? » et "
        'saisissez votre e-mail. Un code à 6 chiffres valable 1 heure vous '
        'sera envoyé.',
  ),
  _FaqEntry(
    'L\'application affiche « Serveur injoignable »',
    'Problème réseau ou serveur temporairement indisponible. Vos données '
        'restent consultables hors connexion et vos actions sont mémorisées '
        'localement — elles seront envoyées au retour du réseau. Ne vous '
        'déconnectez pas avant le rétablissement de la connexion.',
  ),
  _FaqEntry(
    'Je ne vois aucun contrat dans « Mes contrats »',
    'Les contrats sont créés et attribués par votre coordinateur. Si '
        "l'écran est vide, contactez votre coordinateur.",
  ),
  _FaqEntry(
    "Il n'y a pas de bouton pour m'inscrire comme bénévole sur une "
        'livraison',
    'Le créneau peut être complet, annulé, ou pas encore ouvert. '
        'Renseignez-vous auprès de votre coordinateur si la situation '
        'persiste.',
  ),
];

/// Static help screen: guide pointer, contact instructions, a short FAQ and
/// the installed app version.
///
/// Mirrors `documentation/feature/fr/ui/common/screen-common-05-help.md`.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) => const ConnectedScaffold(
      title: _kScreenTitle,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GuideCard(),
            SizedBox(height: 12),
            _ContactCard(),
            SizedBox(height: 24),
            _FaqSection(),
            SizedBox(height: 24),
            Divider(),
            _AboutSection(),
          ],
        ),
      ),
    );
}

class _GuideCard extends StatelessWidget {
  const _GuideCard();

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Consulter le guide d'utilisation",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Le guide complet est organisé par rôle et couvre toutes les '
              "fonctionnalités de l'application. Votre coordinateur ou "
              'administrateur peut vous indiquer comment y accéder.',
            ),
            // No guide URL is published in the server catalog yet
            // (ServerConfig has no such field), so this stays informational
            // text rather than a clickable external link — do not fabricate
            // a URL. Revisit once the guide is hosted and discoverable.
          ],
        ),
      ),
    );
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Besoin d'aide ?",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pour toute question sur votre compte, vos contrats ou le '
              "fonctionnement au quotidien, contactez l'administrateur de "
              'votre AMAP.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Si le problème touche au serveur, adressez-vous à '
              "l'administrateur de l'instance.",
            ),
          ],
        ),
      ),
    );
}

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Questions fréquentes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionPanelList.radio(
            elevation: 0,
            initialOpenPanelValue: null,
            children: [
              for (final entry in _kFaqEntries)
                ExpansionPanelRadio(
                  value: entry.question,
                  canTapOnHeader: true,
                  headerBuilder: (context, isExpanded) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(entry.question),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(entry.answer),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('À propos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final info = snapshot.data;
            final text = info == null
                ? 'Version…'
                : 'Version v${info.version} (build ${info.buildNumber})';
            return Text(text, style: Theme.of(context).textTheme.bodySmall);
          },
        ),
      ],
    );
}
