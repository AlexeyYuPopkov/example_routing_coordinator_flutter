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

class _RootScreenState extends State<RootScreen> {
  final _feedNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'feed');
  final _contactsNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'contacts',
  );

  AppTab _currentTab = AppTab.feed;

  late final _feedTabRouter = FeedTabRouter(navigatorKey: _feedNavigatorKey);

  late final _contactsTabRouter = ContactsTabRouter(
    navigatorKey: _contactsNavigatorKey,
    onRoute: _onContactsTabRoute,
  );

  /// The last handler of the chain, and the only one that knows both tabs
  /// exist, which is exactly what moving between them requires.
  void _onContactsTabRoute(ContactsTabRoute route) {
    switch (route) {
      case UserPostsRoute(:final userId):
        _switchTo(AppTab.feed);
        _feedTabRouter.openUserPosts(userId);
    }
  }

  void _switchTo(AppTab tab) => setState(() => _currentTab = tab);

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
        onDestinationSelected: (index) => _switchTo(AppTab.values[index]),
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
    );
  }
}
