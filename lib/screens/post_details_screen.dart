import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/repository/app_repository.dart';
import 'package:routing_coordinator_flutter/ui/tiles.dart';

abstract interface class PostDetailsScreenCoordinator {
  void onAuthorRoute(BuildContext context, {required String userId});
}

class PostDetailsScreen extends StatelessWidget {
  final String postId;
  final PostDetailsScreenCoordinator coordinator;

  const PostDetailsScreen({
    super.key,
    required this.postId,
    required this.coordinator,
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
            onTap: () => coordinator.onAuthorRoute(context, userId: author.id),
          ),
        ],
      ),
    );
  }
}
