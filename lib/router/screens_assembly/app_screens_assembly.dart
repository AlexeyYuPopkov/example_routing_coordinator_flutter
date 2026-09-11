import 'package:flutter/widgets.dart';
import 'package:routing_coordinator_flutter/router/screens_assembly/screens_assembly.dart';
import 'package:routing_coordinator_flutter/screens/contacts_screen.dart';
import 'package:routing_coordinator_flutter/screens/post_details_screen.dart';
import 'package:routing_coordinator_flutter/screens/post_list_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

final class AppScreensAssembly implements ScreensAssembly {
  const AppScreensAssembly();

  @override
  Widget createPostListScreen({
    String? authorId,
    required PostListScreenCoordinator coordinator,
  }) => PostListScreen(authorId: authorId, coordinator: coordinator);

  @override
  Widget createPostDetailsScreen({
    required String postId,
    required PostDetailsScreenCoordinator coordinator,
  }) => PostDetailsScreen(postId: postId, coordinator: coordinator);

  @override
  Widget createContactsScreen({
    required ContactsScreenCoordinator coordinator,
  }) => ContactsScreen(coordinator: coordinator);

  @override
  Widget createUserProfileScreen({
    required String userId,
    required UserProfileScreenCoordinator coordinator,
  }) => UserProfileScreen(userId: userId, coordinator: coordinator);
}
