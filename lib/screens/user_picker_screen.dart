import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/model/user.dart';
import 'package:routing_coordinator_flutter/domain/repository/app_repository.dart';
import 'package:routing_coordinator_flutter/ui/tiles.dart';

/// Everything this screen can ask the app to do.
///
/// Note what is absent. The screen never pops itself, and never learns that it
/// was opened to answer a question. It reports who was picked, and whoever
/// opened it decides that this ends the screen.
sealed class UserPickerScreenRoute<T> {
  const UserPickerScreenRoute();
}

final class UserPickedRoute extends UserPickerScreenRoute<Never> {
  final User user;

  const UserPickedRoute(this.user);
}

typedef OnUserPickerScreenRoute =
    Future<T?> Function<T>(UserPickerScreenRoute<T> route);

class UserPickerScreen extends StatelessWidget {
  final OnUserPickerScreenRoute onRoute;

  const UserPickerScreen({super.key, required this.onRoute});

  @override
  Widget build(BuildContext context) {
    final users = AppRepository.instance.users;

    return Scaffold(
      appBar: AppBar(title: const Text('Pick a user')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return UserTile(
            user: user,
            onTap: () => onRoute(UserPickedRoute(user)),
          );
        },
      ),
    );
  }
}
