import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routing_coordinator_flutter/router/app_router_path.dart';
import 'package:routing_coordinator_flutter/screens/contacts_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

/// Every location of the contacts tab, and below it the answer to every
/// request its screens can make.
GoRoute get contactsTabRoute => GoRoute(
  path: AppRouterPath.contacts,
  builder: (context, state) =>
      const ContactsScreen(coordinator: ContactsCoordinatorImpl()),
  routes: [
    // The same profile screen as in the feed, with the other coordinator.
    GoRoute(
      path: AppRouterPath.user,
      builder: (context, state) => UserProfileScreen(
        userId: state.pathParameters[AppRouterParam.userId]!,
        coordinator: const ContactsUserProfileCoordinatorImpl(),
      ),
    ),
  ],
);

final class ContactsCoordinatorImpl implements ContactsScreenCoordinator {
  const ContactsCoordinatorImpl();

  @override
  void onUserProfileRoute(BuildContext context, {required String userId}) =>
      GoRouter.of(
        context,
      ).push(AppRouterPath.userIn(AppRouterPath.contacts, userId));
}

/// The same screen and the same request as in the feed tab, with a different
/// answer.
///
/// `go` instead of `push`: the location belongs to the other branch, so the
/// shell switches the tab for us, and the contacts stack stays where it was.
final class ContactsUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const ContactsUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      GoRouter.of(
        context,
      ).go(AppRouterPath.userPostsIn(AppRouterPath.feed, userId));
}
