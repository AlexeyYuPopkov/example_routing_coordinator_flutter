part of 'app_router.dart';

/// The implementations live here, next to the route tree, because that tree is
/// what knows where a location leads. Screens keep the interfaces only.

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

final class ContactsCoordinatorImpl implements ContactsScreenCoordinator {
  const ContactsCoordinatorImpl();

  @override
  void onUserProfileRoute(BuildContext context, {required String userId}) =>
      GoRouter.of(
        context,
      ).push(AppRouterPath.userIn(AppRouterPath.contacts, userId));
}

/// The same screen and the same request as in [FeedUserProfileCoordinatorImpl],
/// with a different answer.
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
