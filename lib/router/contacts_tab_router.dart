import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/screens/contacts_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

/// What the contacts tab cannot answer on its own.
///
/// The same pattern one level up. A screen is the expert on what its user can
/// request and not on what happens next, so it reports [UserProfileScreenRoute]
/// and stops. A tab router is the expert on its own stack and not on the app,
/// so a request that leaves that stack is reported in turn.
sealed class ContactsTabRoute {
  const ContactsTabRoute();
}

/// The posts of a user, which this tab does not own.
///
/// Where they open, and whether the bottom bar moves for them, is none of its
/// business: [OpenUserPostsRoute] is the screen asking the tab, this is the tab
/// asking the shell.
final class UserPostsRoute extends ContactsTabRoute {
  final String userId;

  const UserPostsRoute(this.userId);
}

/// Every transition of the contacts tab, in one place.
final class ContactsTabRouter {
  final GlobalKey<NavigatorState> navigatorKey;
  final ValueChanged<ContactsTabRoute> onRoute;

  const ContactsTabRouter({required this.navigatorKey, required this.onRoute});

  Widget buildRoot(BuildContext context) =>
      ContactsScreen(onRoute: _onContactsScreenRoute);

  void _onContactsScreenRoute(ContactsScreenRoute route) {
    switch (route) {
      case OpenUserProfileRoute(:final userId):
        final screen = UserProfileScreen(
          userId: userId,
          onRoute: _onUserProfileScreenRoute,
        );
        _push(screen);
    }
  }

  /// The same screen and the same request as in the feed tab, with a different
  /// answer: there the posts stay in the stack, here the request goes up.
  void _onUserProfileScreenRoute(UserProfileScreenRoute route) {
    switch (route) {
      case OpenUserPostsRoute(:final userId):
        onRoute(UserPostsRoute(userId));
    }
  }

  void _push(Widget screen) => navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (context) => screen),
  );
}
