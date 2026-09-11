import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/router/app_router.dart';
import 'package:routing_coordinator_flutter/ui/app_theme.dart';

void main() => runApp(App(appRouter: AppRouter()));

class App extends StatelessWidget {
  final AppRouter appRouter;

  const App({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Routing. Coordinator. auto_route',
      theme: buildAppTheme(),
      routerConfig: appRouter.config(),
    );
  }
}
