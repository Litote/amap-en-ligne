import 'package:amap_en_ligne/domain/auth/role.dart';
import 'package:amap_en_ligne/presentation/owner/users/user_row.dart';
import 'package:flutter/material.dart';

/// Dialog for modifying the AMAP roles of one membership.
///
/// Edits the shared member profile, the membership roles for one AMAP, and the
/// current account status when the status transition is supported locally.
class MembershipEditResult {
  const MembershipEditResult({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.status,
    required this.roles,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final UserDisplayStatus status;
  final Set<Role> roles;
}

class ModifyMembershipDialog extends StatefulWidget {
  const ModifyMembershipDialog({
    super.key,
    required this.userRow,
    required this.membership,
    required this.isLastAdmin,
    required this.canEditAdminRole,
  });

  final UserRow userRow;
  final UserMembership membership;
  final bool isLastAdmin;
  final bool canEditAdminRole;

  @override
  State<ModifyMembershipDialog> createState() => _ModifyMembershipDialogState();
}

class _ModifyMembershipDialogState extends State<ModifyMembershipDialog> {
  late bool _admin;
  late bool _coordinator;
  late bool _volunteer;
  late UserDisplayStatus _status;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _admin = widget.membership.roles.contains(Role.admin);
    _coordinator = widget.membership.roles.contains(Role.coordinator);
    _volunteer = widget.membership.roles.contains(Role.volunteer);
    _status = widget.userRow.displayStatus;
    _firstNameController = TextEditingController(
      text: widget.userRow.firstName,
    );
    _lastNameController = TextEditingController(text: widget.userRow.lastName);
    _emailController = TextEditingController(text: widget.userRow.email);
    _phoneController = TextEditingController(text: widget.userRow.phone ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _atLeastOneSelected => _admin || _coordinator || _volunteer;
  bool get _canEditStatus =>
      widget.userRow.displayStatus != UserDisplayStatus.pendingInvitation;

  Set<Role> get _selectedRoles {
    final roles = <Role>{};
    if (_admin) roles.add(Role.admin);
    if (_coordinator) roles.add(Role.coordinator);
    if (_volunteer) roles.add(Role.volunteer);
    return roles;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Modifier l\'utilisateur — ${widget.membership.organizationName}',
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Utilisateur : ${widget.userRow.displayName}'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('first_name_field'),
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('last_name_field'),
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('email_field'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('phone_field'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<UserDisplayStatus>(
              key: const Key('status_dropdown'),
              initialValue: _status,
              decoration: InputDecoration(
                labelText: 'Statut',
                border: const OutlineInputBorder(),
                helperText: _canEditStatus
                    ? null
                    : 'Le statut d\'invitation est synchronisé automatiquement.',
              ),
              items: [
                const DropdownMenuItem(
                  value: UserDisplayStatus.active,
                  child: Text('Actif'),
                ),
                const DropdownMenuItem(
                  value: UserDisplayStatus.suspended,
                  child: Text('Suspendu'),
                ),
                if (!_canEditStatus)
                  const DropdownMenuItem(
                    value: UserDisplayStatus.pendingInvitation,
                    child: Text('Invitation en attente'),
                  ),
              ],
              onChanged: _canEditStatus
                  ? (value) {
                      if (value == null) return;
                      setState(() => _status = value);
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            const Text(
              'Rôles dans l\'AMAP (au moins un, jusqu\'à 3)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const Key('admin_checkbox'),
              title: const Text('Admin'),
              value: _admin,
              onChanged: widget.canEditAdminRole
                  ? (value) => setState(() => _admin = value ?? false)
                  : null,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              key: const Key('coordinator_checkbox'),
              title: const Text('Coordinateur'),
              value: _coordinator,
              onChanged: (v) => setState(() => _coordinator = v ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              key: const Key('volunteer_checkbox'),
              title: const Text('Amapien'),
              value: _volunteer,
              onChanged: (v) => setState(() => _volunteer = v ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            const Text(
              'Au moins un rôle doit être sélectionné.\n'
              'L\'AMAP doit conserver au moins un Admin.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancel_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ANNULER'),
        ),
        FilledButton(
          key: const Key('save_button'),
          onPressed: _atLeastOneSelected
              ? () {
                  Navigator.of(context).pop(
                    MembershipEditResult(
                      firstName: _firstNameController.text.trim(),
                      lastName: _lastNameController.text.trim(),
                      email: _emailController.text.trim(),
                      phone: _phoneController.text.trim(),
                      status: _status,
                      roles: _selectedRoles,
                    ),
                  );
                }
              : null,
          child: const Text('SAUVEGARDER'),
        ),
      ],
    );
  }
}
