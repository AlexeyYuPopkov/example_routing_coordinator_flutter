import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/repository/app_repository.dart';
import 'package:routing_coordinator_flutter/ui/tiles.dart';

sealed class UserProfileRoute {
  const UserProfileRoute();
}

final class OpenUserPostsRoute extends UserProfileRoute {
  final String userId;

  const OpenUserPostsRoute(this.userId);
}

/// Opened from both tabs, and the request below means something different in
/// each of them. The screen stays unaware of that: it reports the request and
/// the tab that owns the stack decides.
class UserProfileScreen extends StatelessWidget {
  final String userId;
  final ValueChanged<UserProfileRoute> onRoute;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.onRoute,
  });

  @override
  Widget build(BuildContext context) {
    const repository = AppRepository.instance;
    final user = repository.userById(userId);
    final postCount = repository.postsByAuthor(userId).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: AppAvatar(user: user, radius: 44)),
            const SizedBox(height: 16),
            Text(
              user.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(user.bio, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton.tonal(
              onPressed: () => onRoute(OpenUserPostsRoute(userId)),
              child: Text('Посты пользователя ($postCount)'),
            ),
          ],
        ),
      ),
    );
  }
}
