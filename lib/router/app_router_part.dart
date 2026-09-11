part of 'app_router.dart';

/// The implementations live here, next to the route tree, because that tree is
/// what knows where a request leads. Screens keep the interfaces only.
///
/// The destination is a generated route object rather than a string, so a
/// missing or misspelled argument is a compile error.

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

final class ContactsCoordinatorImpl implements ContactsScreenCoordinator {
  const ContactsCoordinatorImpl();

  @override
  void onUserProfileRoute(BuildContext context, {required String userId}) =>
      AutoRouter.of(context).push(ContactsUserProfileRoute(userId: userId));
}

/// The same screen and the same request as in [FeedUserProfileCoordinatorImpl],
/// with a different answer.
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
