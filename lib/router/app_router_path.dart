/// Locations of the app, in one place.
///
/// The `*In` helpers build a concrete location inside a given tab. The same
/// screen can live in more than one tab, so the branch is a parameter rather
/// than a part of the constant.
final class AppRouterPath {
  const AppRouterPath();

  static const String feed = '/feed';
  static const String contacts = '/contacts';

  static const String post = 'post/:postId';
  static const String user = 'user/:userId';
  static const String userPosts = 'user/:userId/posts';

  static String postIn(String branch, String postId) => '$branch/post/$postId';

  static String userIn(String branch, String userId) => '$branch/user/$userId';

  static String userPostsIn(String branch, String userId) =>
      '$branch/user/$userId/posts';
}

final class AppRouterParam {
  const AppRouterParam();

  static const String postId = 'postId';
  static const String userId = 'userId';
}
