import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/router/tab_router.dart';
import 'package:routing_coordinator_flutter/screens/contacts_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

/// What the contacts tab cannot answer on its own.
///
/// The same pattern one level up. A screen is the expert on what its user can
/// request and not on what happens next, so it reports [UserProfileScreenRoute]
/// and stops. A tab router is the expert on its own stack and not on the app,
/// so a request that leaves that stack is reported in turn.
sealed class ContactsTabRoute<T> {
  const ContactsTabRoute();
}

/// The posts of a user, which this tab does not own.
///
/// Where they open, and whether the bottom bar moves for them, is none of its
/// business: [OpenUserPostsRoute] is the screen asking the tab, this is the tab
/// asking the shell.
final class UserPostsRoute extends ContactsTabRoute<Never> {
  final String userId;

  const UserPostsRoute(this.userId);
}

typedef OnContactsTabRoute = Future<T?> Function<T>(ContactsTabRoute<T> route);

/// Every transition of the contacts tab, in one place.
final class ContactsTabRouter with TabRouter {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  final OnContactsTabRoute onRoute;

  const ContactsTabRouter({required this.navigatorKey, required this.onRoute});

  @override
  Widget buildRoot(BuildContext context) => _contacts();

  Widget _contacts() => ContactsScreen(
    onRoute: <T>(route) async {
      switch (route) {
        case OpenUserProfileRoute(:final userId):
          push(_userProfile(userId));
          return null;
      }
    },
  );

  /// The same screen and the same request as in the feed tab, with a different
  /// answer: there the posts stay in the stack, here the request goes up.
  Widget _userProfile(String userId) => UserProfileScreen(
    userId: userId,
    onRoute: <T>(route) async {
      switch (route) {
        case OpenUserPostsRoute(:final userId):
          onRoute(UserPostsRoute(userId));
          return null;
      }
    },
  );
}
