import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/model/user.dart';
import 'package:routing_coordinator_flutter/domain/repository/app_repository.dart';
import 'package:routing_coordinator_flutter/ui/tiles.dart';

sealed class PostDetailsScreenRoute<T> {
  const PostDetailsScreenRoute();
}

final class OpenAuthorRoute extends PostDetailsScreenRoute<Never> {
  final String userId;

  const OpenAuthorRoute(this.userId);
}

/// A request that answers back: it gives the chosen [User], or null when the
/// user picked nobody. The type argument of the case is what makes the result
/// typed, so one callback still serves the whole family.
final class PickUserRoute extends PostDetailsScreenRoute<User> {
  const PickUserRoute();
}

typedef OnPostDetailsScreenRoute =
    Future<T?> Function<T>(PostDetailsScreenRoute<T> route);

class PostDetailsScreen extends StatefulWidget {
  final String postId;
  final OnPostDetailsScreenRoute onRoute;

  const PostDetailsScreen({
    super.key,
    required this.postId,
    required this.onRoute,
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
    final user = await widget.onRoute(const PickUserRoute());
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
            onTap: () => widget.onRoute(OpenAuthorRoute(author.id)),
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
