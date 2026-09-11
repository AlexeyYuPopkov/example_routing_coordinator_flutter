import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/ui/app_theme.dart';

/// The `main` branch carries only the shared parts: domain, data and the
/// presentational widgets. Each routing example lives on its own branch and
/// replaces this entry point:
///
///   git switch part-1-imperative
///   git switch part-2-gorouter
///   git switch part-3-autoroute
void main() => runApp(const BranchPlaceholderApp());

class BranchPlaceholderApp extends StatelessWidget {
  const BranchPlaceholderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildAppTheme(),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Примеры живут в ветках:\n\n'
              'part-1-imperative\n'
              'part-2-gorouter\n'
              'part-3-autoroute',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
