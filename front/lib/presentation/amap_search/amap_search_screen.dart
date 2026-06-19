import 'package:amap_en_ligne/data/network/public_api.dart';
import 'package:amap_en_ligne/domain/model/organization.dart';
import 'package:amap_en_ligne/presentation/amap_search/amap_search_bloc.dart';
import 'package:amap_en_ligne/presentation/amap_search/amap_search_event.dart';
import 'package:amap_en_ligne/presentation/amap_search/amap_search_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AmapSearchScreen extends StatelessWidget {
  const AmapSearchScreen({super.key, this.preselectedOrganizationId});

  final String? preselectedOrganizationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AmapSearchBloc(
        publicApi: context.read<PublicApi>(),
        preselectedOrganizationId: preselectedOrganizationId,
      )..add(const AmapSearchEvent.orgsLoadRequested()),
      child: const _AmapSearchView(),
    );
  }
}

class _AmapSearchView extends StatelessWidget {
  const _AmapSearchView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejoindre une AMAP'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: BlocBuilder<AmapSearchBloc, AmapSearchState>(
        builder: (context, state) => switch (state) {
          AmapSearchInitial() || AmapSearchLoadingOrgs() => const Center(
            child: LinearProgressIndicator(),
          ),
          AmapSearchOrgsLoaded(
            :final orgs,
            :final selectedOrg,
            :final searchQuery,
          ) =>
            selectedOrg != null
                ? _JoinFormView(org: selectedOrg, errorMessage: null)
                : _OrgPickerView(orgs: orgs, searchQuery: searchQuery),
          AmapSearchSubmitting(:final org) => _JoinFormView(
            org: org,
            errorMessage: null,
            isSubmitting: true,
          ),
          AmapSearchSuccess(:final organizationName) => _SuccessView(
            organizationName: organizationName,
          ),
          AmapSearchError(:final message, :final selectedOrg) =>
            selectedOrg != null
                ? _JoinFormView(org: selectedOrg, errorMessage: message)
                : _ErrorView(message: message),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Org picker
// ---------------------------------------------------------------------------

class _OrgPickerView extends StatefulWidget {
  const _OrgPickerView({required this.orgs, required this.searchQuery});

  final List<Organization> orgs;
  final String searchQuery;

  @override
  State<_OrgPickerView> createState() => _OrgPickerViewState();
}

class _OrgPickerViewState extends State<_OrgPickerView> {
  late final _searchController = TextEditingController(
    text: widget.searchQuery,
  );
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.searchQuery;
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.orgs
        .where((o) => o.name.toLowerCase().contains(_query))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Rechercher une AMAP',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        if (filtered.isEmpty)
          const Expanded(child: Center(child: Text('Aucune AMAP trouvée.')))
        else
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final org = filtered[index];
                return ListTile(
                  title: Text(org.name),
                  subtitle: Text(org.contactEmail),
                  onTap: () => context.read<AmapSearchBloc>().add(
                    AmapSearchEvent.orgSelected(org),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Join form
// ---------------------------------------------------------------------------

class _JoinFormView extends StatefulWidget {
  const _JoinFormView({
    required this.org,
    required this.errorMessage,
    this.isSubmitting = false,
  });

  final Organization org;
  final String? errorMessage;
  final bool isSubmitting;

  @override
  State<_JoinFormView> createState() => _JoinFormViewState();
}

class _JoinFormViewState extends State<_JoinFormView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AmapSearchBloc>().add(
      AmapSearchEvent.joinFormSubmitted(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
      ),
    );
  }

  void _clearSelection(BuildContext context) {
    context.read<AmapSearchBloc>().add(
      const AmapSearchEvent.orgsLoadRequested(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton.icon(
                  onPressed: widget.isSubmitting
                      ? null
                      : () => _clearSelection(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Choisir une autre AMAP'),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.org.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.org.contactEmail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('first_name'),
                  controller: _firstNameController,
                  enabled: !widget.isSubmitting,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requireNonEmpty,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('last_name'),
                  controller: _lastNameController,
                  enabled: !widget.isSubmitting,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    border: OutlineInputBorder(),
                  ),
                  validator: _requireNonEmpty,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('email'),
                  controller: _emailController,
                  enabled: !widget.isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateEmail,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (widget.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                if (widget.isSubmitting)
                  const LinearProgressIndicator()
                else
                  FilledButton(
                    key: const Key('submit'),
                    onPressed: _submit,
                    child: const Text("S'INSCRIRE"),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _requireNonEmpty(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requis.';
    return null;
  }

  static String? _validateEmail(String? v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return "L'email est requis.";
    if (!val.contains('@') || !val.contains('.')) {
      return 'Saisissez un email valide.';
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Success
// ---------------------------------------------------------------------------

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.organizationName});

  final String organizationName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Votre demande a été enregistrée',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Vous avez demandé à rejoindre $organizationName. '
                "L'équipe de l'AMAP vous contactera prochainement.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text("RETOUR À L'ACCUEIL"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error (no org selected)
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<AmapSearchBloc>().add(
              const AmapSearchEvent.orgsLoadRequested(),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
