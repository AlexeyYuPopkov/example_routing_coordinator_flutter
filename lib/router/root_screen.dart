import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/router/app_tabs.dart';
import 'package:routing_coordinator_flutter/router/contacts_tab_router.dart';
import 'package:routing_coordinator_flutter/router/feed_tab_router.dart';
import 'package:routing_coordinator_flutter/router/tab_navigator.dart';

/// The shell: a bottom bar over two independent navigators.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> implements TabSwitcher {
  final _feedNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'feed');
  final _contactsNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'contacts',
  );

  AppTab _currentTab = AppTab.feed;

  late final _feedTabRouter = FeedTabRouter(navigatorKey: _feedNavigatorKey);

  late final _contactsTabRouter = ContactsTabRouter(
    navigatorKey: _contactsNavigatorKey,
    tabSwitcher: this,
    feedTabRouter: _feedTabRouter,
  );

  @override
  void switchTo(AppTab tab) => setState(() => _currentTab = tab);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab.index,
        children: [
          TabNavigator(
            navigatorKey: _feedNavigatorKey,
            rootBuilder: _feedTabRouter.buildRoot,
          ),
          TabNavigator(
            navigatorKey: _contactsNavigatorKey,
            rootBuilder: _contactsTabRouter.buildRoot,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab.index,
        onDestinationSelected: (index) => switchTo(AppTab.values[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Лента',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Контакты',
          ),
        ],
      ),
    );
  }
}
