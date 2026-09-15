import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/model/user.dart';
import 'package:routing_coordinator_flutter/domain/repository/app_repository.dart';
import 'package:routing_coordinator_flutter/ui/tiles.dart';

abstract interface class PostDetailsScreenCoordinator {
  void onAuthorRoute(BuildContext context, {required String userId});

  /// Answers with the chosen user, or null when nobody was chosen.
  ///
  /// A request that answers back is just a method with a return type. This is
  /// where an interface is plainly easier than a single callback serving a
  /// whole family of requests, which has to make the result type generic to
  /// get the same thing.
  Future<User?> onPickUserRoute(BuildContext context);
}

class PostDetailsScreen extends StatefulWidget {
  final String postId;
  final PostDetailsScreenCoordinator coordinator;

  const PostDetailsScreen({
    super.key,
    required this.postId,
    required this.coordinator,
  });

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  User? _sharedWith;

  /// Asks for a user and waits for the answer.
  ///
  /// Which screen appears, and whether it is a page, a sheet or a dialog, is
  /// not this screen's business. Neither is how the answer travels back.
  Future<void> _share() async {
    final user = await widget.coordinator.onPickUserRoute(context);
    if (user == null || !mounted) return;
    setState(() => _sharedWith = user);
  }

  @override
  Widget build(BuildContext context) {
    const repository = AppRepository.instance;
    final post = repository.postById(widget.postId);
    final author = repository.userById(post.authorId);
    final sharedWith = _sharedWith;

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
            onTap: () =>
                widget.coordinator.onAuthorRoute(context, userId: author.id),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.tonal(
                  onPressed: _share,
                  child: const Text('Share with...'),
                ),
                if (sharedWith != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Shared with ${sharedWith.name}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
