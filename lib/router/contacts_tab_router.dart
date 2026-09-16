import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/router/app_router.dart';
import 'package:routing_coordinator_flutter/router/app_router_path.dart';
import 'package:routing_coordinator_flutter/router/app_tabs.dart';
import 'package:routing_coordinator_flutter/screens/contacts_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

/// The whole contacts tab: every page it can show, the tree they form, and the
/// answer to every request those screens can make.
AutoRoute get contactsTabRoute => AutoRoute(
  path: AppRouterPath.contacts,
  page: contactsTab,
  children: [
    AutoRoute(path: AppRouterPath.initial, page: ContactsRoute.page),
    AutoRoute(path: AppRouterPath.user, page: ContactsUserProfileRoute.page),
  ],
);

@RoutePage()
class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const ContactsScreen(coordinator: ContactsCoordinatorImpl());
}

/// The same profile screen as in the feed, with the other coordinator. This
/// pair of pages is the whole difference between the two tabs.
@RoutePage()
class ContactsUserProfilePage extends StatelessWidget {
  final String userId;

  const ContactsUserProfilePage({
    super.key,
    @PathParam('userId') required this.userId,
  });

  @override
  Widget build(BuildContext context) => UserProfileScreen(
    userId: userId,
    coordinator: const ContactsUserProfileCoordinatorImpl(),
  );
}

final class ContactsCoordinatorImpl implements ContactsScreenCoordinator {
  const ContactsCoordinatorImpl();

  @override
  void onUserProfileRoute(BuildContext context, {required String userId}) =>
      AutoRouter.of(context).push(ContactsUserProfileRoute(userId: userId));
}

/// The same screen and the same request as in the feed tab, with a different
/// answer.
///
/// The destination belongs to the other tab, which no nested stack router can
/// push into. Navigating the root router by path lets auto_route activate that
/// tab itself, and the contacts stack stays where it was.
final class ContactsUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const ContactsUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      AutoRouter.of(
        context,
      ).root.navigatePath(AppRouterPath.feedUserPosts(userId));
}
