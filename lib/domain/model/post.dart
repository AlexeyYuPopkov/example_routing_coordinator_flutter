/// A single feed entry, written by a [User].
final class Post {
  final String id;
  final String authorId;
  final String title;
  final String body;

  const Post({
    required this.id,
    required this.authorId,
    required this.title,
    required this.body,
  });
}
