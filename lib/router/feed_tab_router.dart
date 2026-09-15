import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:routing_coordinator_flutter/domain/model/user.dart';
import 'package:routing_coordinator_flutter/router/app_router_path.dart';
import 'package:routing_coordinator_flutter/screens/post_details_screen.dart';
import 'package:routing_coordinator_flutter/screens/post_list_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_picker_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

/// Every location of the feed tab, and below it the answer to every request
/// its screens can make.
///
/// The coordinators live here, next to the route tree, because that tree is
/// what knows where a location leads. Screens keep the interfaces only.
GoRoute get feedTabRoute => GoRoute(
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

final class FeedPostListCoordinatorImpl implements PostListScreenCoordinator {
  const FeedPostListCoordinatorImpl();

  @override
  void onPostRoute(BuildContext context, {required String postId}) =>
      GoRouter.of(
        context,
      ).push(AppRouterPath.postIn(AppRouterPath.feed, postId));
}

final class FeedPostDetailsCoordinatorImpl
    implements PostDetailsScreenCoordinator {
  const FeedPostDetailsCoordinatorImpl();

  @override
  void onAuthorRoute(BuildContext context, {required String userId}) =>
      GoRouter.of(
        context,
      ).push(AppRouterPath.userIn(AppRouterPath.feed, userId));

  /// `push` is a future of whatever the pushed location is popped with,
  /// so a request that answers back needs nothing special here.
  @override
  Future<User?> onPickUserRoute(BuildContext context) => GoRouter.of(
    context,
  ).push<User>(AppRouterPath.userPickerIn(AppRouterPath.feed));
}

/// Closing the picker is a decision, not a side effect of choosing, and it
/// is taken here rather than inside the screen.
final class UserPickerCoordinatorImpl implements UserPickerScreenCoordinator {
  const UserPickerCoordinatorImpl();

  @override
  void onUserPickedRoute(BuildContext context, {required User user}) =>
      GoRouter.of(context).pop(user);
}

/// The profile inside the feed: the posts of an author belong to this same
/// stack, so they are pushed on top of it.
final class FeedUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const FeedUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      GoRouter.of(
        context,
      ).push(AppRouterPath.userPostsIn(AppRouterPath.feed, userId));
}
