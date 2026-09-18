import 'package:go_router/go_router.dart';
import 'package:routing_coordinator_flutter/router/app_router_path.dart';
import 'package:routing_coordinator_flutter/router/contacts_tab_router.dart';
import 'package:routing_coordinator_flutter/router/feed_tab_router.dart';
import 'package:routing_coordinator_flutter/router/root_screen.dart';

/// The tree of everything the app can show. Each tab keeps its own branch of
/// it, together with the answers to its screens, in a file of its own.
final class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: AppRouterPath.feed,
    debugLogDiagnostics: true,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RootScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [feedTabRoute]),
          StatefulShellBranch(routes: [contactsTabRoute]),
        ],
      ),
    ],
  );
}
