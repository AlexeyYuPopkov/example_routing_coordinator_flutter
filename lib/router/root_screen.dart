import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/router/app_router.dart';
import 'package:routing_coordinator_flutter/router/tab_navigator.dart';

/// The shell: a bottom bar over two independent navigators.
///
/// It holds no navigation logic of its own. Which tab is current lives in
/// [AppRouter], and this widget only draws it.
class RootScreen extends StatelessWidget {
  final AppRouter appRouter;

  const RootScreen({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appRouter.currentTab,
      builder: (context, currentTab, child) => Scaffold(
        body: IndexedStack(
          index: currentTab.index,
          children: [
            TabNavigator(
              navigatorKey: appRouter.feedNavigatorKey,
              rootBuilder: appRouter.feedTabRouter.buildRoot,
            ),
            TabNavigator(
              navigatorKey: appRouter.contactsNavigatorKey,
              rootBuilder: appRouter.contactsTabRouter.buildRoot,
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentTab.index,
          onDestinationSelected: (index) =>
              appRouter.switchTo(AppTab.values[index]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article),
              label: 'Feed',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Contacts',
            ),
          ],
        ),
      ),
    );
  }
}
