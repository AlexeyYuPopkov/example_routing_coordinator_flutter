import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/router/root_screen.dart';
import 'package:routing_coordinator_flutter/ui/app_theme.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Routing. Imperative',
      theme: buildAppTheme(),
      home: const RootScreen(),
    );
  }
}
