import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/model/user.dart';
import 'package:routing_coordinator_flutter/router/app_router.dart';
import 'package:routing_coordinator_flutter/router/app_router_path.dart';
import 'package:routing_coordinator_flutter/router/app_tabs.dart';
import 'package:routing_coordinator_flutter/screens/post_details_screen.dart';
import 'package:routing_coordinator_flutter/screens/post_list_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_picker_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

/// The whole feed tab: every page it can show, the tree they form, and the
/// answer to every request those screens can make.
///
/// The coordinators live next to the route tree because that tree is what
/// knows where a request leads. Screens keep the interfaces only, and the
/// pages below keep the `@RoutePage` annotation out of them.
///
/// The destination is a generated route object rather than a string, so a
/// missing or misspelled argument is a compile error.
AutoRoute get feedTabRoute => AutoRoute(
  path: AppRouterPath.feed,
  page: feedTab,
  children: [
    AutoRoute(path: AppRouterPath.initial, page: FeedRoute.page),
    AutoRoute(path: AppRouterPath.post, page: FeedPostDetailsRoute.page),
    AutoRoute(path: AppRouterPath.user, page: FeedUserProfileRoute.page),
    AutoRoute(path: AppRouterPath.userPosts, page: FeedUserPostsRoute.page),
    AutoRoute(path: AppRouterPath.userPicker, page: FeedUserPickerRoute.page),
  ],
);

@RoutePage()
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const PostListScreen(coordinator: FeedPostListCoordinatorImpl());
}

@RoutePage()
class FeedPostDetailsPage extends StatelessWidget {
  final String postId;

  const FeedPostDetailsPage({
    super.key,
    @PathParam('postId') required this.postId,
  });

  @override
  Widget build(BuildContext context) => PostDetailsScreen(
    postId: postId,
    coordinator: const FeedPostDetailsCoordinatorImpl(),
  );
}

/// The same screen as the tab root, filtered by author and with the very same
/// coordinator: a post opens the same way wherever the list came from.
@RoutePage()
class FeedUserPostsPage extends StatelessWidget {
  final String userId;

  const FeedUserPostsPage({
    super.key,
    @PathParam('userId') required this.userId,
  });

  @override
  Widget build(BuildContext context) => PostListScreen(
    authorId: userId,
    coordinator: const FeedPostListCoordinatorImpl(),
  );
}

@RoutePage()
class FeedUserProfilePage extends StatelessWidget {
  final String userId;

  const FeedUserProfilePage({
    super.key,
    @PathParam('userId') required this.userId,
  });

  @override
  Widget build(BuildContext context) => UserProfileScreen(
    userId: userId,
    coordinator: const FeedUserProfileCoordinatorImpl(),
  );
}

/// Opened to answer a question rather than to be browsed to, but it is
/// still an ordinary page, so a deep link lands on it too.
@RoutePage()
class FeedUserPickerPage extends StatelessWidget {
  const FeedUserPickerPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const UserPickerScreen(coordinator: UserPickerCoordinatorImpl());
}

final class FeedPostListCoordinatorImpl implements PostListScreenCoordinator {
  const FeedPostListCoordinatorImpl();

  @override
  void onPostRoute(BuildContext context, {required String postId}) =>
      AutoRouter.of(context).push(FeedPostDetailsRoute(postId: postId));
}

final class FeedPostDetailsCoordinatorImpl
    implements PostDetailsScreenCoordinator {
  const FeedPostDetailsCoordinatorImpl();

  @override
  void onAuthorRoute(BuildContext context, {required String userId}) =>
      AutoRouter.of(context).push(FeedUserProfileRoute(userId: userId));

  /// `push` is typed in what the pushed page is popped with, so a request
  /// that answers back needs nothing special here.
  @override
  Future<User?> onPickUserRoute(BuildContext context) =>
      AutoRouter.of(context).push<User>(const FeedUserPickerRoute());
}

/// Closing the picker is a decision, not a side effect of choosing, and it
/// is taken here rather than inside the screen.
final class UserPickerCoordinatorImpl implements UserPickerScreenCoordinator {
  const UserPickerCoordinatorImpl();

  @override
  void onUserPickedRoute(BuildContext context, {required User user}) =>
      AutoRouter.of(context).maybePop(user);
}

/// The profile inside the feed: the posts of an author belong to this same
/// stack, so they are pushed on top of it.
final class FeedUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const FeedUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      AutoRouter.of(context).push(FeedUserPostsRoute(userId: userId));
}
