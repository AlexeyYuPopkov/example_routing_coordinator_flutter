import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/router/tab_router.dart';
import 'package:routing_coordinator_flutter/screens/post_details_screen.dart';
import 'package:routing_coordinator_flutter/screens/post_list_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_picker_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

/// Every transition of the feed tab, in one place.
///
/// One method per screen, and in it the screen together with everything it can
/// lead to. Read the `push` calls and you have read the tree: the list leads to
/// a post, a post to a profile or to the picker, a profile back to a list.
final class FeedTabRouter with TabRouter {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  const FeedTabRouter({required this.navigatorKey});

  @override
  Widget buildRoot(BuildContext context) => _postList();

  /// Also the entry point for the shell, which sends here the request that the
  /// contacts tab could not answer on its own. Nobody outside assembles a feed
  /// screen by hand.
  void openUserPosts(String userId) => push(_postList(authorId: userId));

  /// One screen, two uses: the root of the tab, and the posts of one author.
  Widget _postList({String? authorId}) => PostListScreen(
    authorId: authorId,
    onRoute: <T>(route) async {
      switch (route) {
        case OpenPostRoute(:final postId):
          push(_postDetails(postId));
          return null;
      }
    },
  );

  Widget _postDetails(String postId) => PostDetailsScreen(
    postId: postId,
    onRoute: <T>(route) async {
      switch (route) {
        case OpenAuthorRoute(:final userId):
          push(_userProfile(userId));
          return null;
        // The only request here that answers back. The screen awaits the
        // value; this is the code that decides where it comes from.
        case PickUserRoute():
          return push<T>(_userPicker());
      }
    },
  );

  /// Inside the feed the posts of an author belong to this same stack.
  /// The contacts tab answers the very same request differently.
  Widget _userProfile(String userId) => UserProfileScreen(
    userId: userId,
    onRoute: <T>(route) async {
      switch (route) {
        case OpenUserPostsRoute(:final userId):
          openUserPosts(userId);
          return null;
      }
    },
  );

  Widget _userPicker() => UserPickerScreen(
    onRoute: <T>(route) async {
      switch (route) {
        // Closing the picker is a decision, not a side effect of choosing,
        // and it is taken here rather than inside the screen.
        case UserPickedRoute(:final user):
          pop(user);
          return null;
      }
    },
  );
}
