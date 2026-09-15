import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/repository/app_repository.dart';
import 'package:routing_coordinator_flutter/ui/tiles.dart';

/// Everything this screen can ask the app to do.
///
/// Declared next to the screen, because the screen is the expert on what its
/// user can request. It is not the expert on what happens next, so the sealed
/// class carries a request and no navigation at all.
sealed class PostListScreenRoute {
  const PostListScreenRoute();
}

final class OpenPostRoute extends PostListScreenRoute {
  final String postId;

  const OpenPostRoute(this.postId);
}

/// Used twice: as the root of the feed tab, and filtered by author when opened
/// from a profile. The two call sites pass different [onRoute] callbacks.
class PostListScreen extends StatelessWidget {
  /// When set, only the posts of that author are listed.
  final String? authorId;
  final ValueChanged<PostListScreenRoute> onRoute;

  const PostListScreen({super.key, this.authorId, required this.onRoute});

  @override
  Widget build(BuildContext context) {
    const repository = AppRepository.instance;
    final author = authorId == null ? null : repository.userById(authorId!);
    final posts = author == null
        ? repository.posts
        : repository.postsByAuthor(author.id);

    return Scaffold(
      appBar: AppBar(title: Text(author == null ? 'Feed' : author.name)),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return PostTile(
            post: post,
            author: repository.userById(post.authorId),
            onTap: () => onRoute(OpenPostRoute(post.id)),
          );
        },
      ),
    );
  }
}
