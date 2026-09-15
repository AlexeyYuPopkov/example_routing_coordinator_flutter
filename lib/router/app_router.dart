import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/router/contacts_tab_router.dart';
import 'package:routing_coordinator_flutter/router/feed_tab_router.dart';

/// The two bottom bar destinations, each with its own [Navigator] and its own
/// back stack.
enum AppTab { feed, contacts }

/// The whole navigation of the app, and the only place that knows both tabs.
///
/// ```text
/// Feed      posts -> post -> profile -> posts by author -> post -> ...
///                      `-> pick a user, which answers back with one
///
/// Contacts  people -> profile -> the tab gives up and reports it
///                                  `-> the shell switches to Feed
///                                      and opens the posts there
/// ```
///
/// A plain object rather than widget state, so the top of the chain can be
/// read, and tested, without building anything.
final class AppRouter {
  final feedNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'feed');

  final contactsNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'contacts',
  );

  final currentTab = ValueNotifier(AppTab.feed);

  late final feedTabRouter = FeedTabRouter(navigatorKey: feedNavigatorKey);

  late final contactsTabRouter = ContactsTabRouter(
    navigatorKey: contactsNavigatorKey,
    onRoute: _onContactsTabRoute,
  );

  void switchTo(AppTab tab) => currentTab.value = tab;

  /// The last handler of the chain. Everything below reported its way up to
  /// here precisely because moving between tabs needs to know both of them.
  Future<T?> _onContactsTabRoute<T>(ContactsTabRoute<T> route) async {
    switch (route) {
      case UserPostsRoute(:final userId):
        switchTo(AppTab.feed);
        feedTabRouter.openUserPosts(userId);
        return null;
    }
  }
}
