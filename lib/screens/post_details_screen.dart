import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/repository/app_repository.dart';
import 'package:routing_coordinator_flutter/ui/tiles.dart';

sealed class PostDetailsScreenRoute {
  const PostDetailsScreenRoute();
}

final class OpenAuthorRoute extends PostDetailsScreenRoute {
  final String userId;

  const OpenAuthorRoute(this.userId);
}

class PostDetailsScreen extends StatelessWidget {
  final String postId;
  final ValueChanged<PostDetailsScreenRoute> onRoute;

  const PostDetailsScreen({
    super.key,
    required this.postId,
    required this.onRoute,
  });

  @override
  Widget build(BuildContext context) {
    const repository = AppRepository.instance;
    final post = repository.postById(postId);
    final author = repository.userById(post.authorId);

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(post.body),
              ],
            ),
          ),
          const Divider(),
          UserTile(
            user: author,
            onTap: () => onRoute(OpenAuthorRoute(author.id)),
          ),
        ],
      ),
    );
  }
}
