import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/repository/app_repository.dart';
import 'package:routing_coordinator_flutter/ui/tiles.dart';

abstract interface class ContactsScreenCoordinator {
  void onUserProfileRoute(BuildContext context, {required String userId});
}

class ContactsScreen extends StatelessWidget {
  final ContactsScreenCoordinator coordinator;

  const ContactsScreen({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) {
    final users = AppRepository.instance.users;

    return Scaffold(
      appBar: AppBar(title: const Text('Контакты')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return UserTile(
            user: user,
            onTap: () =>
                coordinator.onUserProfileRoute(context, userId: user.id),
          );
        },
      ),
    );
  }
}
