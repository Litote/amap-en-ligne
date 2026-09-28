import 'package:amap_en_ligne/domain/server/server_config.dart';
import 'package:amap_en_ligne/presentation/common/open_url_stub.dart'
    if (dart.library.js_interop) 'package:amap_en_ligne/presentation/common/open_url_web.dart'
    if (dart.library.io) 'package:amap_en_ligne/presentation/common/open_url_native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// URL of the terms of service:
/// - [termsUrl] configured → that URL.
/// - Web, no URL → `/cgu.html` at the root of [pageUrl]'s site (bundled static
///   file). Resolved from the root, not relative to the page: on a nested route
///   such as `/register/producer` a relative `cgu.html` would point to
///   `/register/cgu.html`, which does not exist.
/// - Mobile, no URL → `cgu.html` next to [backendUrl].
@visibleForTesting
String resolveTermsUrl({
  String? termsUrl,
  required bool isWeb,
  required Uri pageUrl,
  required String backendUrl,
}) =>
    termsUrl ??
    (isWeb
        ? pageUrl.resolve('/cgu.html').toString()
        : Uri.parse(backendUrl).resolve('cgu.html').toString());

/// A checkbox tile that renders the terms-of-service acceptance row.
///
/// "conditions d'utilisation" is always a tappable link, to [resolveTermsUrl].
///
/// URL opening uses [dart:js_interop] on web (bypasses the plugin system,
/// works in both JS and WASM builds) and [url_launcher] on native.
class TermsCheckboxTile extends StatefulWidget {
  const TermsCheckboxTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  State<TermsCheckboxTile> createState() => _TermsCheckboxTileState();
}

class _TermsCheckboxTileState extends State<TermsCheckboxTile> {
  late final TapGestureRecognizer _tapRecognizer;
  late final FocusNode _checkboxFocusNode;

  @override
  void initState() {
    super.initState();
    _tapRecognizer = TapGestureRecognizer();
    // Skip traversal so the InkWell wrapper is the keyboard target for the tile.
    _checkboxFocusNode = FocusNode(skipTraversal: true);
  }

  @override
  void dispose() {
    _tapRecognizer.dispose();
    _checkboxFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<ServerConfig>();
    final effectiveUrl = resolveTermsUrl(
      termsUrl: config.termsUrl,
      isWeb: kIsWeb,
      pageUrl: Uri.base,
      backendUrl: config.backendUrl,
    );

    _tapRecognizer.onTap = () => openUrl(effectiveUrl);

    final colorScheme = Theme.of(context).colorScheme;
    final defaultStyle = DefaultTextStyle.of(context).style;

    // InkWell makes the whole tile keyboard-activatable (Space/Enter) and
    // also lets users toggle by clicking anywhere on the label text.
    // The TapGestureRecognizer on the link TextSpan wins the gesture arena
    // for its own hit region, so clicking the link still opens the URL.
    return InkWell(
      onTap: () => widget.onChanged(!widget.value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: widget.value,
            onChanged: widget.onChanged,
            focusNode: _checkboxFocusNode,
            // Screen readers name the checkbox by what it accepts…
            semanticLabel: "J'accepte les conditions d'utilisation du service",
          ),
          Expanded(
            // …and reach the terms as their own link (a TextSpan recognizer
            // is not exposed to the accessibility tree).
            child: Semantics(
              link: true,
              // Without the URL, the web renders the link as plain text.
              linkUrl: Uri.parse(effectiveUrl),
              label: "Lire les conditions d'utilisation",
              onTap: () => openUrl(effectiveUrl),
              excludeSemantics: true,
              child: RichText(
                text: TextSpan(
                  style: defaultStyle,
                  children: [
                    const TextSpan(text: "J'accepte les "),
                    TextSpan(
                      text: "conditions d'utilisation",
                      style: TextStyle(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: _tapRecognizer,
                    ),
                    const TextSpan(text: ' du service'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
