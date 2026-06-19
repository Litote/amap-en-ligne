import 'package:amap_en_ligne/presentation/nav/connected_scaffold.dart';
import 'package:flutter/material.dart';

/// A generic placeholder screen used for routes that are not yet implemented.
///
/// Displays a centered message indicating the feature is coming soon.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ConnectedScaffold(
      title: title,
      body: Center(child: Text('🚧 $title — à venir')),
    );
  }
}
