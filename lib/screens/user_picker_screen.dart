import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/model/user.dart';
import 'package:routing_coordinator_flutter/domain/repository/app_repository.dart';
import 'package:routing_coordinator_flutter/ui/tiles.dart';

/// Note what is absent. The screen never pops itself, and never learns that it
/// was opened to answer a question. It reports who was picked, and whoever
/// opened it decides that this ends the screen.
abstract interface class UserPickerScreenCoordinator {
  void onUserPickedRoute(BuildContext context, {required User user});
}

class UserPickerScreen extends StatelessWidget {
  final UserPickerScreenCoordinator coordinator;

  const UserPickerScreen({super.key, required this.coordinator});

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
            onTap: () => coordinator.onUserPickedRoute(context, user: user),
          );
        },
      ),
    );
  }
}
