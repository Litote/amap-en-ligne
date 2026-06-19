import 'dart:convert';
import 'dart:typed_data';

import 'package:amap_en_ligne/data/auth/jwt_claims.dart';
import 'package:amap_en_ligne/data/local/database_export_save.dart';
import 'package:amap_en_ligne/data/local/json_file_picker.dart';
import 'package:amap_en_ligne/data/local/local_database_export_service.dart';
import 'package:amap_en_ligne/data/network/admin_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:amap_en_ligne/domain/auth/auth_service.dart';
import 'package:amap_en_ligne/domain/auth/auth_state.dart';
import 'package:amap_en_ligne/domain/model/member.dart';
import 'package:amap_en_ligne/domain/model/notification.dart';
import 'package:amap_en_ligne/domain/model/notification_copy_override.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/common/alert_templates_bloc.dart';
import 'package:amap_en_ligne/presentation/common/edit_profile_dialog.dart';
import 'package:amap_en_ligne/presentation/common/user_preferences_bloc.dart';
import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:amap_en_ligne/presentation/sync/sync_bloc.dart';
import 'package:amap_en_ligne/presentation/sync/sync_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Preferences screen for the current user.
///
/// Mirrors `documentation/feature/fr/ui/common/screen-common-02-user-preferences.md`.
/// Two sections:
///   1. Profil utilisateur — read-only profile from JWT claims.
///   2. Notifications bénévolat — editable notification checkboxes.
///
/// The bloc is provided by the router via [BlocProvider<UserPreferencesBloc>].
const _kEditMyInfoLabel = 'MODIFIER MES INFORMATIONS';

class UserPreferencesScreen extends StatelessWidget {
  const UserPreferencesScreen({
    super.key,
    this.showAlertTemplates = false,
    this.backupOrganizationId,
  });

  /// When true (org admins only), an extra card lets the user customise the
  /// title/body of each alert category. Requires an [AlertTemplatesBloc] to be
  /// provided above this screen.
  final bool showAlertTemplates;

  /// Non-null for org admins: enables the "Sauvegarde & migration" card,
  /// scoped to this organization. Requires an [AdminApi] above this screen.
  final String? backupOrganizationId;

  static bool _profileSaveListenWhen(
    UserPreferencesState prev,
    UserPreferencesState curr,
  ) {
    if (curr is! UserPreferencesReady) return false;
    if (prev is! UserPreferencesReady) return false;
    return prev.profileSaveStatus != curr.profileSaveStatus;
  }

  static void _onProfileSaveStatus(
    BuildContext context,
    UserPreferencesState state,
  ) {
    if (state is! UserPreferencesReady) return;
    switch (state.profileSaveStatus) {
      case SaveStatus.success:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profil mis à jour')));
        context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
      case SaveStatus.failure:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.profileSaveErrorMessage ??
                  'Échec de la mise à jour du profil',
            ),
          ),
        );
      case SaveStatus.idle || SaveStatus.saving:
        break;
    }
  }

  static bool _saveListenWhen(
    UserPreferencesState previous,
    UserPreferencesState current,
  ) {
    if (current is! UserPreferencesReady) return false;
    if (previous is! UserPreferencesReady) return true;
    return previous.saveStatus != current.saveStatus;
  }

  static void _onSaveStatus(BuildContext context, UserPreferencesState state) {
    if (state is! UserPreferencesReady) return;
    switch (state.saveStatus) {
      case SaveStatus.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préférences enregistrées avec succès !'),
          ),
        );
        // Nudge sync so the optimistic write is flushed to the back.
        context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
      case SaveStatus.failure:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              state.saveErrorMessage ?? "Échec de l'enregistrement",
            ),
          ),
        );
      case SaveStatus.idle || SaveStatus.saving:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserPreferencesBloc, UserPreferencesState>(
      listenWhen: _profileSaveListenWhen,
      listener: _onProfileSaveStatus,
      child: BlocListener<UserPreferencesBloc, UserPreferencesState>(
        listenWhen: _saveListenWhen,
        listener: _onSaveStatus,
        child: BlocBuilder<UserPreferencesBloc, UserPreferencesState>(
          builder: (context, state) {
            return ConnectedScaffold(
              title: 'Préférences',
              body: switch (state) {
                UserPreferencesLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                UserPreferencesMissing() => const _MissingView(),
                UserPreferencesReady() => _ReadyView(
                  state: state,
                  showAlertTemplates: showAlertTemplates,
                  backupOrganizationId: backupOrganizationId,
                ),
              },
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Missing state
// ---------------------------------------------------------------------------

class _MissingView extends StatelessWidget {
  const _MissingView();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: _ProfilUtilisateurCard(),
    );
  }
}

// ---------------------------------------------------------------------------
// Ready state
// ---------------------------------------------------------------------------

class _ReadyView extends StatelessWidget {
  const _ReadyView({
    required this.state,
    this.showAlertTemplates = false,
    this.backupOrganizationId,
  });

  final UserPreferencesReady state;
  final bool showAlertTemplates;
  final String? backupOrganizationId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfilUtilisateurCard(readyState: state),
          const SizedBox(height: 16),
          // Members see the full bénévolat card (reminders + alerts + channels).
          // Owners and producers see only the notification-channel card.
          if (state.member != null)
            _NotificationsCard(state: state)
          else
            _ChannelsCard(state: state),
          if (showAlertTemplates) ...[
            const SizedBox(height: 16),
            const _AlertTemplatesCard(),
          ],
          if (backupOrganizationId != null) ...[
            const SizedBox(height: 16),
            _OrganizationBackupCard(organizationId: backupOrganizationId!),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: state.dirty && state.saveStatus != SaveStatus.saving
                  ? () => context.read<UserPreferencesBloc>().add(
                      const UserPreferencesEvent.saved(),
                    )
                  : null,
              child: const Text('ENREGISTRER LES MODIFICATIONS'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profil utilisateur card
// ---------------------------------------------------------------------------

class _ProfilUtilisateurCard extends StatelessWidget {
  const _ProfilUtilisateurCard({this.readyState});

  /// Non-null when the bloc is in the ready state. Used to enable the
  /// "MODIFIER MES INFORMATIONS" button for Owner and Producer roles.
  final UserPreferencesReady? readyState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profil utilisateur',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ..._buildProfileRows(context),
            const SizedBox(height: 8),
            _buildEditButton(context),
            const SizedBox(height: 8),
            _ExportDatabaseButton(readyState: readyState),
          ],
        ),
      ),
    );
  }

  /// For Owner, Producer, and Member the rows are seeded from the synced
  /// entity so they reflect the values the user just edited in the dialog.
  /// Missing values fall back to the JWT claims.
  List<Widget> _buildProfileRows(BuildContext context) {
    final ready = readyState;
    final owner = ready?.owner;
    if (owner != null) {
      return [
        _ProfileRow(
          label: 'Nom',
          value: '${owner.firstName} ${owner.lastName}'.trim(),
        ),
        _ProfileRow(label: 'Email', value: owner.email),
        _ProfileRow(label: 'Téléphone', value: owner.phone ?? '—'),
      ];
    }
    final producer = ready?.producerAccount;
    if (producer != null) {
      return [
        _ProfileRow(label: "Nom de l'entreprise", value: producer.name),
        _ProfileRow(
          label: 'Email de contact',
          value: producer.contactEmail ?? '—',
        ),
        _ProfileRow(label: 'Adresse', value: producer.address ?? '—'),
        _ProfileRow(label: 'Site web', value: producer.website ?? '—'),
      ];
    }
    final profile = _ProfileData.fromMember(
      ready?.member,
      fallback: _ProfileData.fromContext(context),
    );
    return [
      _ProfileRow(label: 'Nom', value: profile.name),
      _ProfileRow(label: 'Email', value: profile.email),
      _ProfileRow(label: 'Téléphone', value: profile.phone),
    ];
  }

  Widget _buildEditButton(BuildContext context) {
    final ready = readyState;

    if (ready?.owner != null) {
      return FilledButton(
        onPressed: () => _showOwnerDialog(context, ready!),
        child: const Text(_kEditMyInfoLabel),
      );
    }

    if (ready?.producerAccount != null) {
      return FilledButton(
        onPressed: () => _showProducerDialog(context, ready!),
        child: const Text(_kEditMyInfoLabel),
      );
    }

    if (ready?.member != null) {
      return FilledButton(
        onPressed: () => _showMemberDialog(context, ready!),
        child: const Text(_kEditMyInfoLabel),
      );
    }

    // Missing state — button stays disabled.
    return const Tooltip(
      message: 'À venir',
      child: FilledButton(
        // Disabled — profile editing needs synced member data first.
        onPressed: null,
        child: Text(_kEditMyInfoLabel),
      ),
    );
  }

  void _showOwnerDialog(BuildContext context, UserPreferencesReady ready) {
    final owner = ready.owner!;
    final bloc = context.read<UserPreferencesBloc>();
    showDialog<void>(
      context: context,
      builder: (_) => EditProfileDialog.forOwner(
        firstName: owner.firstName,
        lastName: owner.lastName,
        email: owner.email,
        phone: owner.phone,
        onSubmit: (fields) => bloc.add(
          UserPreferencesEvent.profileSaved(
            firstName: fields['firstName'],
            lastName: fields['lastName'],
            email: fields['email'],
            phone: fields['phone'],
          ),
        ),
      ),
    );
  }

  void _showProducerDialog(BuildContext context, UserPreferencesReady ready) {
    final producer = ready.producerAccount!;
    final bloc = context.read<UserPreferencesBloc>();
    showDialog<void>(
      context: context,
      builder: (_) => EditProfileDialog.forProducer(
        name: producer.name,
        contactEmail: producer.contactEmail,
        address: producer.address,
        website: producer.website,
        onSubmit: (fields) => bloc.add(
          UserPreferencesEvent.profileSaved(
            producerName: fields['name'],
            contactEmail: fields['contactEmail'],
            address: fields['address'],
            website: fields['website'],
          ),
        ),
      ),
    );
  }

  void _showMemberDialog(BuildContext context, UserPreferencesReady ready) {
    final profile = _ProfileData.fromMember(
      ready.member,
      fallback: _ProfileData.fromContext(context),
    );
    final bloc = context.read<UserPreferencesBloc>();
    showDialog<void>(
      context: context,
      builder: (_) => EditProfileDialog.forOwner(
        firstName: profile.firstName,
        lastName: profile.lastName,
        email: profile.email == '—' ? '' : profile.email,
        phone: profile.phoneOrNull,
        onSubmit: (fields) => bloc.add(
          UserPreferencesEvent.profileSaved(
            firstName: fields['firstName'],
            lastName: fields['lastName'],
            email: fields['email'],
            phone: fields['phone'],
          ),
        ),
      ),
    );
  }
}

class _ExportDatabaseButton extends StatefulWidget {
  const _ExportDatabaseButton({this.readyState});

  final UserPreferencesReady? readyState;

  @override
  State<_ExportDatabaseButton> createState() => _ExportDatabaseButtonState();
}

class _ExportDatabaseButtonState extends State<_ExportDatabaseButton> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('export_local_database_button'),
      onPressed: _exporting ? null : () => _export(context),
      style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
      icon: _exporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download_outlined),
      label: Text(_exporting ? 'EXPORT EN COURS…' : 'EXPORTER MES DONNÉES'),
    );
  }

  Future<void> _export(BuildContext context) async {
    setState(() => _exporting = true);
    try {
      final result = await context
          .read<LocalDatabaseExportService>()
          .exportCurrentUserDatabase(userId: _resolveUserId(context));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_successMessage(result))));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l'export des données locales.")),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  String _resolveUserId(BuildContext context) {
    final ready = widget.readyState;
    if (ready?.member != null) return ready!.member!.memberId;
    if (ready?.owner != null) return ready!.owner!.ownerId;
    if (ready?.producerAccount != null) {
      return ready!.producerAccount!.producerAccountId;
    }

    final authService = context.read<AuthService>();
    final currentState = authService.currentState;
    if (currentState is Authenticated) {
      try {
        final claims = JwtClaims.decode(currentState.accessToken);
        final sub = claims.string('sub');
        if (sub != null && sub.isNotEmpty) return sub;
      } catch (_) {}
      if (currentState.producerId.isNotEmpty) {
        return currentState.producerId;
      }
    }
    return 'user';
  }

  String _successMessage(DatabaseExportResult result) {
    if (result.downloadTriggered) {
      return 'Export ZIP téléchargé : ${result.filename}';
    }
    return 'Export ZIP enregistré : ${result.path ?? result.filename}';
  }
}

// ---------------------------------------------------------------------------
// Organization backup / migration card (org admins only)
// ---------------------------------------------------------------------------

/// Admin-only card to back up the organization to a native-JSON file and
/// restore it into a (newly-created, empty) target organization.
///
/// Export works on every platform (file download/save). Import reads a local
/// file and is **web-only** in V1 (no file-picker dependency on mobile yet);
/// the import button is hidden on non-web platforms.
class _OrganizationBackupCard extends StatefulWidget {
  const _OrganizationBackupCard({required this.organizationId});

  final String organizationId;

  @override
  State<_OrganizationBackupCard> createState() =>
      _OrganizationBackupCardState();
}

class _OrganizationBackupCardState extends State<_OrganizationBackupCard> {
  bool _exporting = false;
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sauvegarde & migration',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Exportez les données de votre AMAP dans un fichier, '
              'ou restaurez une sauvegarde dans une AMAP vide.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('export_organization_button'),
              onPressed: _exporting ? null : () => _export(context),
              style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
              icon: _exporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(_exporting ? 'EXPORT EN COURS…' : "EXPORTER L'AMAP"),
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('import_organization_button'),
                onPressed: _importing ? null : () => _import(context),
                style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                icon: _importing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_outlined),
                label: Text(
                  _importing ? 'IMPORT EN COURS…' : 'IMPORTER UNE SAUVEGARDE',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    setState(() => _exporting = true);
    try {
      final json = await context.read<AdminApi>().exportOrganization(
        widget.organizationId,
      );
      final bytes = Uint8List.fromList(utf8.encode(json));
      final result = await saveDatabaseExportFile(
        filename: _exportFilename(),
        bytes: bytes,
        mimeType: 'application/json',
      );
      if (!context.mounted) return;
      final where = result.downloadTriggered
          ? 'téléchargé : ${result.filename}'
          : 'enregistré : ${result.path ?? result.filename}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export $where')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de l'export de l'AMAP.")),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _import(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final adminApi = context.read<AdminApi>();
    final syncBloc = context.read<SyncBloc>();
    final picked = await pickJsonFile();
    if (picked == null) return;
    setState(() => _importing = true);
    try {
      final result = await adminApi.importOrganization(
        widget.organizationId,
        picked.content,
      );
      // Pull the freshly-restored data back into the local cache.
      syncBloc.add(const SyncEvent.mutationApplied());
      final members = result['members'] ?? 0;
      final warnings = (result['warnings'] as List?)?.cast<String>() ?? const [];
      if (warnings.isNotEmpty && context.mounted) {
        await _showImportWarnings(context, members, warnings);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('Import réussi ($members membres).')),
        );
      }
    } on DioException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(_importErrorMessage(e.response?.statusCode))),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Échec de l'import.")),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _showImportWarnings(
    BuildContext context,
    Object members,
    List<String> warnings,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import réussi avec avertissements'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$members membres importés.'),
              const SizedBox(height: 12),
              for (final warning in warnings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(warning)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _importErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 409:
        return "Import impossible : l'AMAP cible n'est pas vide.";
      case 403:
        return "Vous n'avez pas les droits pour importer dans cette AMAP.";
      case 400:
        return 'Fichier de sauvegarde invalide ou incompatible.';
      default:
        return "Échec de l'import.";
    }
  }

  String _exportFilename() {
    final ts = DateTime.now().toUtc();
    final month = ts.month.toString().padLeft(2, '0');
    final day = ts.day.toString().padLeft(2, '0');
    final hour = ts.hour.toString().padLeft(2, '0');
    final minute = ts.minute.toString().padLeft(2, '0');
    final safeOrg = widget.organizationId.replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    return 'amap_export_${safeOrg}_${ts.year}$month${day}T$hour${minute}Z.json';
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label : ',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Profile data decoded from the current session's JWT claims.
class _ProfileData {
  const _ProfileData({
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.email,
    required this.phone,
  });

  final String firstName;
  final String lastName;
  final String name;
  final String email;
  final String phone;
  String? get phoneOrNull => phone == '—' ? null : phone;

  static _ProfileData fromContext(BuildContext context) {
    final authService = context.read<AuthService>();
    final currentState = authService.currentState;
    if (currentState is! Authenticated) {
      return const _ProfileData(
        firstName: '',
        lastName: '',
        name: '—',
        email: '—',
        phone: '—',
      );
    }
    try {
      final claims = JwtClaims.decode(currentState.accessToken);
      final firstName = _extractFirstName(claims);
      final lastName = _extractLastName(claims);
      final name = _joinName(firstName, lastName);
      final email = _extractEmail(claims);
      final phone = _extractPhone(claims);
      return _ProfileData(
        firstName: firstName,
        lastName: lastName,
        name: name,
        email: email,
        phone: phone,
      );
    } catch (_) {
      return const _ProfileData(
        firstName: '',
        lastName: '',
        name: '—',
        email: '—',
        phone: '—',
      );
    }
  }

  static _ProfileData fromMember(
    Member? member, {
    required _ProfileData fallback,
  }) {
    if (member == null) return fallback;
    final firstName = member.firstName ?? fallback.firstName;
    final lastName = member.lastName ?? fallback.lastName;
    return _ProfileData(
      firstName: firstName,
      lastName: lastName,
      name: _joinName(firstName, lastName),
      email: member.email ?? fallback.email,
      phone: member.phone ?? fallback.phone,
    );
  }

  static String _extractFirstName(JwtClaims claims) {
    final goTrueFirst = claims.nestedString('user_metadata.first_name');
    if (goTrueFirst != null) {
      return goTrueFirst;
    }
    return claims.string('given_name') ?? '';
  }

  static String _extractLastName(JwtClaims claims) {
    final goTrueLast = claims.nestedString('user_metadata.last_name');
    if (goTrueLast != null) {
      return goTrueLast;
    }
    return claims.string('family_name') ?? '';
  }

  static String _joinName(String firstName, String lastName) {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? '—' : name;
  }

  static String _extractEmail(JwtClaims claims) {
    return claims.string('email') ??
        claims.nestedString('user_metadata.email') ??
        '—';
  }

  static String _extractPhone(JwtClaims claims) {
    return claims.nestedString('user_metadata.phone') ??
        claims.string('phone_number') ??
        '—';
  }
}

// ---------------------------------------------------------------------------
// Notifications card
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({required this.state});

  final UserPreferencesReady state;

  @override
  Widget build(BuildContext context) {
    final mp = state.memberPreferences;
    final up = state.userPreferences;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications bénévolat',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const _SectionLabel("Rappels d'inscription"),
            CheckboxListTile(
              value: mp.reminder24hEnabled,
              onChanged: (v) => context.read<UserPreferencesBloc>().add(
                UserPreferencesEvent.reminderToggled(
                  ReminderField.reminder24h,
                  v ?? mp.reminder24hEnabled,
                ),
              ),
              title: const Text('Rappel 24h avant le créneau'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: mp.reminder2hEnabled,
              onChanged: (v) => context.read<UserPreferencesBloc>().add(
                UserPreferencesEvent.reminderToggled(
                  ReminderField.reminder2h,
                  v ?? mp.reminder2hEnabled,
                ),
              ),
              title: const Text('Rappel 2h avant le créneau'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: mp.reminder30minEnabled,
              onChanged: (v) => context.read<UserPreferencesBloc>().add(
                UserPreferencesEvent.reminderToggled(
                  ReminderField.reminder30min,
                  v ?? mp.reminder30minEnabled,
                ),
              ),
              title: const Text('Rappel 30min avant le créneau'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const _SectionLabel("Alertes d'urgence"),
            CheckboxListTile(
              value: mp.urgentNeedAlertsEnabled,
              onChanged: (v) => context.read<UserPreferencesBloc>().add(
                UserPreferencesEvent.alertToggled(
                  AlertField.urgentNeed,
                  v ?? mp.urgentNeedAlertsEnabled,
                ),
              ),
              title: const Text('Notifier si besoin urgent de bénévoles'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: mp.incompleteSlotRemindersEnabled,
              onChanged: (v) => context.read<UserPreferencesBloc>().add(
                UserPreferencesEvent.alertToggled(
                  AlertField.incompleteSlot,
                  v ?? mp.incompleteSlotRemindersEnabled,
                ),
              ),
              title: const Text(
                'Rappels pour manque de volontaire(s) sur la livraison',
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: mp.planningChangesAlertsEnabled,
              onChanged: (v) => context.read<UserPreferencesBloc>().add(
                UserPreferencesEvent.alertToggled(
                  AlertField.planningChanges,
                  v ?? mp.planningChangesAlertsEnabled,
                ),
              ),
              title: const Text('Modifications de planning'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const _SectionLabel('Canaux de notification'),
            CheckboxListTile(
              value: up.pushNotificationsEnabled,
              onChanged: (v) => context.read<UserPreferencesBloc>().add(
                UserPreferencesEvent.channelToggled(
                  ChannelField.push,
                  v ?? up.pushNotificationsEnabled,
                ),
              ),
              title: const Text('Notifications push'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: up.emailNotificationsEnabled,
              onChanged: (v) => context.read<UserPreferencesBloc>().add(
                UserPreferencesEvent.channelToggled(
                  ChannelField.email,
                  v ?? up.emailNotificationsEnabled,
                ),
              ),
              title: const Text('Email'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Channels-only card — for Owner and Producer roles
// ---------------------------------------------------------------------------

/// Notification channel card shown to OWNER and PRODUCER users. Shows only
/// the two channel toggles (email / push) without the bénévolat
/// reminder and alert sections.
class _ChannelsCard extends StatelessWidget {
  const _ChannelsCard({required this.state});

  final UserPreferencesReady state;

  @override
  Widget build(BuildContext context) {
    final up = state.userPreferences;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Canaux de notification',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            CheckboxListTile(
              value: up.pushNotificationsEnabled,
              onChanged: (v) => context.read<UserPreferencesBloc>().add(
                UserPreferencesEvent.channelToggled(
                  ChannelField.push,
                  v ?? up.pushNotificationsEnabled,
                ),
              ),
              title: const Text('Notifications push'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: up.emailNotificationsEnabled,
              onChanged: (v) => context.read<UserPreferencesBloc>().add(
                UserPreferencesEvent.channelToggled(
                  ChannelField.email,
                  v ?? up.emailNotificationsEnabled,
                ),
              ),
              title: const Text('Email'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alert templates card — org admins only
// ---------------------------------------------------------------------------

/// Lets an org admin customise the title/body of each alert category for their
/// AMAP. Backed by [AlertTemplatesBloc]; edits are saved as
/// `Organization.notificationOverrides`.
class _AlertTemplatesCard extends StatefulWidget {
  const _AlertTemplatesCard();

  @override
  State<_AlertTemplatesCard> createState() => _AlertTemplatesCardState();
}

class _AlertTemplatesCardState extends State<_AlertTemplatesCard> {
  final Map<NotificationCategory, TextEditingController> _titleControllers = {};
  final Map<NotificationCategory, TextEditingController> _bodyControllers = {};
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    for (final category in kCustomisableAlertCategories) {
      _titleControllers[category] = TextEditingController();
      _bodyControllers[category] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _titleControllers.values) {
      c.dispose();
    }
    for (final c in _bodyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _seedFrom(Organization organization) {
    if (_seeded) return;
    organization.notificationOverrides.forEach((category, override) {
      _titleControllers[category]?.text = override.title ?? '';
      _bodyControllers[category]?.text = override.body ?? '';
    });
    _seeded = true;
  }

  void _save(BuildContext context) {
    final overrides = <NotificationCategory, NotificationCopyOverride>{};
    for (final category in kCustomisableAlertCategories) {
      overrides[category] = NotificationCopyOverride(
        title: _titleControllers[category]!.text,
        body: _bodyControllers[category]!.text,
      );
    }
    context.read<AlertTemplatesBloc>().add(
      AlertTemplatesEvent.saved(overrides),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AlertTemplatesBloc, AlertTemplatesState>(
      listenWhen: (prev, curr) =>
          curr is AlertTemplatesReady &&
          (prev is! AlertTemplatesReady || prev.saveStatus != curr.saveStatus),
      listener: (context, state) {
        if (state is! AlertTemplatesReady) return;
        switch (state.saveStatus) {
          case AlertTemplatesSaveStatus.success:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Messages d\'alerte enregistrés')),
            );
            context.read<SyncBloc>().add(const SyncEvent.mutationApplied());
          case AlertTemplatesSaveStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.saveErrorMessage ?? "Échec de l'enregistrement",
                ),
              ),
            );
          case AlertTemplatesSaveStatus.idle || AlertTemplatesSaveStatus.saving:
            break;
        }
      },
      builder: (context, state) {
        if (state is AlertTemplatesReady) {
          _seedFrom(state.organization);
        }
        final saving =
            state is AlertTemplatesReady &&
            state.saveStatus == AlertTemplatesSaveStatus.saving;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personnalisation des alertes',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Laissez un champ vide pour utiliser le message par défaut.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                for (final category in kCustomisableAlertCategories)
                  _AlertCategoryFields(
                    categoryKey: category.name,
                    label: alertCategoryLabel(category),
                    defaultTitle: alertCategoryDefaultTitle(category),
                    defaultBody: alertCategoryDefaultBody(category),
                    titleController: _titleControllers[category]!,
                    bodyController: _bodyControllers[category]!,
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('save_alert_templates_button'),
                    onPressed: state is AlertTemplatesReady && !saving
                        ? () => _save(context)
                        : null,
                    child: const Text('ENREGISTRER LES ALERTES'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlertCategoryFields extends StatelessWidget {
  const _AlertCategoryFields({
    required this.categoryKey,
    required this.label,
    required this.defaultTitle,
    required this.defaultBody,
    required this.titleController,
    required this.bodyController,
  });

  final String categoryKey;
  final String label;
  final String defaultTitle;
  final String defaultBody;
  final TextEditingController titleController;
  final TextEditingController bodyController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _SectionLabel(label)),
              TextButton.icon(
                key: Key('alert_reset_$categoryKey'),
                onPressed: () {
                  titleController.text = defaultTitle;
                  bodyController.text = defaultBody;
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Repartir de l\'alerte par défaut'),
              ),
            ],
          ),
          TextField(
            key: Key('alert_title_$categoryKey'),
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'Titre (optionnel)',
              hintText: defaultTitle,
              helperText: 'Par défaut : $defaultTitle',
              helperMaxLines: 2,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: Key('alert_body_$categoryKey'),
            controller: bodyController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Corps (optionnel)',
              hintText: defaultBody,
              helperText: 'Par défaut : $defaultBody',
              helperMaxLines: 3,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
