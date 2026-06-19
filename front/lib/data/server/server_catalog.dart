import 'package:amap_en_ligne/data/server/server_presets.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/domain/server/server_discovery_document.dart';

abstract interface class ServerCatalog {
  List<ServerConfig> listSelectionOptions();
}

/// Current production bootstrap: a static in-binary list.
///
/// This keeps runtime behavior stable today while giving the app a seam that
/// can later be backed by cached discovery documents or a fetched directory.
final class StaticServerCatalog implements ServerCatalog {
  StaticServerCatalog({List<ServerConfig>? configs})
    : configs = configs ?? serverPresets;

  final List<ServerConfig> configs;

  @override
  List<ServerConfig> listSelectionOptions() => configs;
}

/// Future-facing adapter turning per-instance discovery documents into UI
/// selection options.
final class DiscoveryDocumentServerCatalog implements ServerCatalog {
  const DiscoveryDocumentServerCatalog({required this.documents});

  final List<ServerDiscoveryDocument> documents;

  @override
  List<ServerConfig> listSelectionOptions() =>
      documents.map((document) => document.toServerConfig()).toList();
}
