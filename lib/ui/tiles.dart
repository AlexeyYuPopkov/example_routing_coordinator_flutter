import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/domain/model/post.dart';
import 'package:routing_coordinator_flutter/domain/model/user.dart';

/// Presentational widgets shared by every screen.
///
/// They know how a row looks and nothing about where a tap leads: the tap is
/// handed back to the caller, which is the screen, which in turn hands it to
/// its coordinator. Navigation never reaches this file.
class AppAvatar extends StatelessWidget {
  final User user;
  final double radius;

  const AppAvatar({super.key, required this.user, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      child: Text(
        user.initials,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const UserTile({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AppAvatar(user: user),
      title: Text(user.name),
      subtitle: Text(user.bio),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class PostTile extends StatelessWidget {
  final Post post;
  final User author;
  final VoidCallback onTap;

  const PostTile({
    super.key,
    required this.post,
    required this.author,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AppAvatar(user: author),
      title: Text(post.title),
      subtitle: Text(author.name),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Shown by the two detail panes before anything is selected.
class EmptyStatePlaceholder extends StatelessWidget {
  final String message;

  const EmptyStatePlaceholder({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
