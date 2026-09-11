/// Paths of the app, in one place.
///
/// auto_route navigates by typed route objects most of the time. A path is
/// still needed when the destination lives in another tab, and for deep links.
final class AppRouterPath {
  const AppRouterPath();

  static const String root = '/';
  static const String feed = 'feed';
  static const String contacts = 'contacts';

  static const String initial = '';
  static const String post = 'post/:postId';
  static const String user = 'user/:userId';
  static const String userPosts = 'user/:userId/posts';

  static String feedUserPosts(String userId) => '/feed/user/$userId/posts';
}
