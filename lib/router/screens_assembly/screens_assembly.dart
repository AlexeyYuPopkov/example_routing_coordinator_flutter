import 'package:flutter/widgets.dart';
import 'package:routing_coordinator_flutter/screens/contacts_screen.dart';
import 'package:routing_coordinator_flutter/screens/post_details_screen.dart';
import 'package:routing_coordinator_flutter/screens/post_list_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_picker_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

/// Keeps the route tree free of concrete screen constructors.
///
/// The router asks for a screen and supplies the coordinator; how the screen
/// is built, and with which dependencies, is decided here. In a test the whole
/// assembly can be replaced by stubs.
abstract interface class ScreensAssembly {
  Widget createPostListScreen({
    String? authorId,
    required PostListScreenCoordinator coordinator,
  });

  Widget createPostDetailsScreen({
    required String postId,
    required PostDetailsScreenCoordinator coordinator,
  });

  Widget createContactsScreen({required ContactsScreenCoordinator coordinator});

  Widget createUserPickerScreen({
    required UserPickerScreenCoordinator coordinator,
  });

  Widget createUserProfileScreen({
    required String userId,
    required UserProfileScreenCoordinator coordinator,
  });
}
