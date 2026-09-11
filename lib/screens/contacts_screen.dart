import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/repository/app_repository.dart';
import 'package:routing_coordinator_flutter/ui/tiles.dart';

sealed class ContactsRoute {
  const ContactsRoute();
}

final class OpenUserProfileRoute extends ContactsRoute {
  final String userId;

  const OpenUserProfileRoute(this.userId);
}

class ContactsScreen extends StatelessWidget {
  final ValueChanged<ContactsRoute> onRoute;

  const ContactsScreen({super.key, required this.onRoute});

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
            onTap: () => onRoute(OpenUserProfileRoute(user.id)),
          );
        },
      ),
    );
  }
}
