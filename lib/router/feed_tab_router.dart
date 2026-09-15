import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/screens/post_details_screen.dart';
import 'package:routing_coordinator_flutter/screens/post_list_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

/// Every transition of the feed tab, in one place.
///
/// Read top to bottom it is the tree of what this tab can do: list, post,
/// profile, posts of that author. Screens report requests, this class answers
/// them, and nothing below knows that a [Navigator] exists.
final class FeedTabRouter {
  final GlobalKey<NavigatorState> navigatorKey;

  const FeedTabRouter({required this.navigatorKey});

  Widget buildRoot(BuildContext context) =>
      PostListScreen(onRoute: _onPostListScreenRoute);

  /// Also the entry point for the shell, which sends here the request that the
  /// contacts tab could not answer on its own. Nobody outside assembles a feed
  /// screen by hand.
  void openUserPosts(String userId) {
    final screen = PostListScreen(authorId: userId, onRoute: _onPostListScreenRoute);
    _push(screen);
  }

  void _onPostListScreenRoute(PostListScreenRoute route) {
    switch (route) {
      case OpenPostRoute(:final postId):
        final screen = PostDetailsScreen(
          postId: postId,
          onRoute: _onPostDetailsScreenRoute,
        );
        _push(screen);
    }
  }

  void _onPostDetailsScreenRoute(PostDetailsScreenRoute route) {
    switch (route) {
      case OpenAuthorRoute(:final userId):
        final screen = UserProfileScreen(
          userId: userId,
          onRoute: _onUserProfileScreenRoute,
        );
        _push(screen);
    }
  }

  /// Inside the feed the posts of an author belong to this same stack.
  /// The contacts tab answers the very same request differently.
  void _onUserProfileScreenRoute(UserProfileScreenRoute route) {
    switch (route) {
      case OpenUserPostsRoute(:final userId):
        openUserPosts(userId);
    }
  }

  void _push(Widget screen) => navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (context) => screen),
  );
}
