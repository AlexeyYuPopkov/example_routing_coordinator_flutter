import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/repository/app_repository.dart';
import 'package:routing_coordinator_flutter/ui/tiles.dart';

abstract interface class UserProfileScreenCoordinator {
  void onUserPostsRoute(BuildContext context, {required String userId});
}

/// Opened from both tabs. The request below means something different in each
/// of them, and the screen never learns which one it is in: it gets a
/// different implementation of the interface instead.
class UserProfileScreen extends StatelessWidget {
  final String userId;
  final UserProfileScreenCoordinator coordinator;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.coordinator,
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
              onPressed: () =>
                  coordinator.onUserPostsRoute(context, userId: userId),
              child: Text('Посты пользователя ($postCount)'),
            ),
          ],
        ),
      ),
    );
  }
}
