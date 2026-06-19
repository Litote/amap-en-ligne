import 'package:amap_en_ligne/domain/server/auth_provider.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:flutter/material.dart';

/// First-launch picker that selects the back the app will talk to. The
/// list currently comes from a bootstrap catalog provided by the app shell.
/// Users cannot type arbitrary URLs today; federated discovery is prepared
/// as a separate bootstrap flow.
///
/// `onSelected` is fired with the chosen preset. Persistence is the
/// caller's responsibility.
class ServerSelectionScreen extends StatelessWidget {
  const ServerSelectionScreen({
    super.key,
    required this.presets,
    required this.onSelected,
  });

  final List<ServerConfig> presets;
  final ValueChanged<ServerConfig> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choisissez votre serveur')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: presets.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final preset = presets[index];
          return ListTile(
            key: Key('server_preset_${preset.id}'),
            leading: Icon(_iconFor(preset.provider)),
            title: Text(preset.name),
            subtitle: Text(preset.backendUrl),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onSelected(preset),
          );
        },
      ),
    );
  }

  static IconData _iconFor(AuthProvider provider) => switch (provider) {
    AuthProvider.cognito => Icons.cloud,
    AuthProvider.gotrue => Icons.dns,
  };
}
