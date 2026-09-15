import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routing_coordinator_flutter/domain/model/user.dart';
import 'package:routing_coordinator_flutter/router/app_router_path.dart';
import 'package:routing_coordinator_flutter/router/root_screen.dart';
import 'package:routing_coordinator_flutter/screens/contacts_screen.dart';
import 'package:routing_coordinator_flutter/screens/post_details_screen.dart';
import 'package:routing_coordinator_flutter/screens/post_list_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_picker_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

part 'app_router_part.dart';

/// The tree of everything the app can show, and next to it, in the part file,
/// the answer to every request a screen can make.
final class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: AppRouterPath.feed,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RootScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [_feedRoute]),
          StatefulShellBranch(routes: [_contactsRoute]),
        ],
      ),
    ],
  );

  GoRoute get _feedRoute => GoRoute(
    path: AppRouterPath.feed,
    builder: (context, state) =>
        const PostListScreen(coordinator: FeedPostListCoordinatorImpl()),
    routes: [
      GoRoute(
        path: AppRouterPath.post,
        builder: (context, state) => PostDetailsScreen(
          postId: state.pathParameters[AppRouterParam.postId]!,
          coordinator: const FeedPostDetailsCoordinatorImpl(),
        ),
      ),
      GoRoute(
        path: AppRouterPath.user,
        builder: (context, state) => UserProfileScreen(
          userId: state.pathParameters[AppRouterParam.userId]!,
          coordinator: const FeedUserProfileCoordinatorImpl(),
        ),
      ),
      // Opened to answer a question rather than to be browsed to, but it
      // is still an ordinary location, so a deep link lands on it too.
      GoRoute(
        path: AppRouterPath.userPicker,
        builder: (context, state) =>
            const UserPickerScreen(coordinator: UserPickerCoordinatorImpl()),
      ),
      // The same screen as the branch root, with a filter and the very same
      // coordinator: a post opens the same way wherever the list came from.
      GoRoute(
        path: AppRouterPath.userPosts,
        builder: (context, state) => PostListScreen(
          authorId: state.pathParameters[AppRouterParam.userId]!,
          coordinator: const FeedPostListCoordinatorImpl(),
        ),
      ),
    ],
  );

  GoRoute get _contactsRoute => GoRoute(
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
}
