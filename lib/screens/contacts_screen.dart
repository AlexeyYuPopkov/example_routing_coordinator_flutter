import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/repository/app_repository.dart';
import 'package:routing_coordinator_flutter/ui/tiles.dart';

sealed class ContactsScreenRoute<T> {
  const ContactsScreenRoute();
}

final class OpenUserProfileRoute extends ContactsScreenRoute<Never> {
  final String userId;

  const OpenUserProfileRoute(this.userId);
}

typedef OnContactsScreenRoute =
    Future<T?> Function<T>(ContactsScreenRoute<T> route);

class ContactsScreen extends StatelessWidget {
  final OnContactsScreenRoute onRoute;

  const ContactsScreen({super.key, required this.onRoute});

  @override
  Widget build(BuildContext context) {
    final users = AppRepository.instance.users;

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
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
