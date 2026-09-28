import 'package:amap_en_ligne/data/server/server_presets.dart';
import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/domain/server/server_discovery_document.dart';

/// Returns the list of server configurations available for selection.
typedef ServerCatalog = List<ServerConfig> Function();

/// Current production bootstrap: a static in-binary list.
///
/// This keeps runtime behavior stable today while giving the app a seam that
/// can later be backed by cached discovery documents or a fetched directory.
ServerCatalog staticServerCatalog([List<ServerConfig>? configs]) =>
    () => configs ?? serverPresets;

/// Future-facing adapter turning per-instance discovery documents into UI
/// selection options.
ServerCatalog discoveryDocumentServerCatalog(
  List<ServerDiscoveryDocument> documents,
) =>
    () => documents.map((document) => document.toServerConfig()).toList();
