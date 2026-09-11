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
      PostListScreen(onRoute: _onPostListRoute);

  /// Also the entry point for the contacts tab, so that nobody outside has to
  /// assemble a feed screen by hand.
  void openUserPosts(String userId) =>
      _push(PostListScreen(authorId: userId, onRoute: _onPostListRoute));

  void _onPostListRoute(PostListRoute route) {
    switch (route) {
      case OpenPostRoute(:final postId):
        _push(PostDetailsScreen(postId: postId, onRoute: _onPostDetailsRoute));
    }
  }

  void _onPostDetailsRoute(PostDetailsRoute route) {
    switch (route) {
      case OpenAuthorRoute(:final userId):
        _push(UserProfileScreen(userId: userId, onRoute: _onUserProfileRoute));
    }
  }

  /// Inside the feed the posts of an author belong to this same stack.
  /// The contacts tab answers the very same request differently.
  void _onUserProfileRoute(UserProfileRoute route) {
    switch (route) {
      case OpenUserPostsRoute(:final userId):
        openUserPosts(userId);
    }
  }

  void _push(Widget screen) => navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (context) => screen),
  );
}
