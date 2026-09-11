import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/router/app_tabs.dart';
import 'package:routing_coordinator_flutter/router/feed_tab_router.dart';
import 'package:routing_coordinator_flutter/screens/contacts_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

/// Every transition of the contacts tab, in one place.
final class ContactsTabRouter {
  final GlobalKey<NavigatorState> navigatorKey;
  final TabSwitcher tabSwitcher;
  final FeedTabRouter feedTabRouter;

  const ContactsTabRouter({
    required this.navigatorKey,
    required this.tabSwitcher,
    required this.feedTabRouter,
  });

  Widget buildRoot(BuildContext context) =>
      ContactsScreen(onRoute: _onContactsRoute);

  void _onContactsRoute(ContactsRoute route) {
    switch (route) {
      case OpenUserProfileRoute(:final userId):
        _push(UserProfileScreen(userId: userId, onRoute: _onUserProfileRoute));
    }
  }

  /// The same screen and the same request as in the feed tab, with a different
  /// answer: posts live in the feed, so the bottom bar switches and the list
  /// opens over there.
  void _onUserProfileRoute(UserProfileRoute route) {
    switch (route) {
      case OpenUserPostsRoute(:final userId):
        tabSwitcher.switchTo(AppTab.feed);
        feedTabRouter.openUserPosts(userId);
    }
  }

  void _push(Widget screen) => navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (context) => screen),
  );
}
