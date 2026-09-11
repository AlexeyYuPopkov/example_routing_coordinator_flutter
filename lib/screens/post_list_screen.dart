import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/repository/app_repository.dart';
import 'package:routing_coordinator_flutter/ui/tiles.dart';

/// What this screen can ask the app to do.
///
/// Declared next to the screen, because the screen is the expert on what its
/// user can request. Implemented next to the route tree, which is the expert
/// on what such a request means.
abstract interface class PostListScreenCoordinator {
  void onPostRoute(BuildContext context, {required String postId});
}

/// Used twice: as the root of the feed tab, and filtered by author when opened
/// from a profile.
class PostListScreen extends StatelessWidget {
  /// When set, only the posts of that author are listed.
  final String? authorId;
  final PostListScreenCoordinator coordinator;

  const PostListScreen({
    super.key,
    this.authorId,
    required this.coordinator,
  });

  @override
  Widget build(BuildContext context) {
    const repository = AppRepository.instance;
    final author = authorId == null ? null : repository.userById(authorId!);
    final posts = author == null
        ? repository.posts
        : repository.postsByAuthor(author.id);

    return Scaffold(
      appBar: AppBar(title: Text(author == null ? 'Лента' : author.name)),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return PostTile(
            post: post,
            author: repository.userById(post.authorId),
            onTap: () => coordinator.onPostRoute(context, postId: post.id),
          );
        },
      ),
    );
  }
}
