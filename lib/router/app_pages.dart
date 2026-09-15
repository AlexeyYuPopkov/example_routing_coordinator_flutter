import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/router/app_router.dart';
import 'package:routing_coordinator_flutter/router/app_tabs.dart';
import 'package:routing_coordinator_flutter/screens/contacts_screen.dart';
import 'package:routing_coordinator_flutter/screens/post_details_screen.dart';
import 'package:routing_coordinator_flutter/screens/post_list_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_picker_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

/// The pages the generator knows about.
///
/// Each one pairs a screen with the coordinator it should get, which keeps the
/// `@RoutePage` annotation, and auto_route itself, out of the screens. The
/// screens of this branch are byte for byte the ones of `part-2-gorouter`.
@RoutePage()
class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: [feedTab(), contactsTab()],
      bottomNavigationBuilder: (context, tabsRouter) => NavigationBar(
        selectedIndex: tabsRouter.activeIndex,
        onDestinationSelected: tabsRouter.setActiveIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Contacts',
          ),
        ],
      ),
    );
  }
}

@RoutePage()
class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const PostListScreen(coordinator: FeedPostListCoordinatorImpl());
}

@RoutePage()
class FeedPostDetailsPage extends StatelessWidget {
  final String postId;

  const FeedPostDetailsPage({
    super.key,
    @PathParam('postId') required this.postId,
  });

  @override
  Widget build(BuildContext context) => PostDetailsScreen(
    postId: postId,
    coordinator: const FeedPostDetailsCoordinatorImpl(),
  );
}

/// The same screen as the tab root, filtered by author and with the very same
/// coordinator: a post opens the same way wherever the list came from.
@RoutePage()
class FeedUserPostsPage extends StatelessWidget {
  final String userId;

  const FeedUserPostsPage({
    super.key,
    @PathParam('userId') required this.userId,
  });

  @override
  Widget build(BuildContext context) => PostListScreen(
    authorId: userId,
    coordinator: const FeedPostListCoordinatorImpl(),
  );
}

@RoutePage()
class FeedUserProfilePage extends StatelessWidget {
  final String userId;

  const FeedUserProfilePage({
    super.key,
    @PathParam('userId') required this.userId,
  });

  @override
  Widget build(BuildContext context) => UserProfileScreen(
    userId: userId,
    coordinator: const FeedUserProfileCoordinatorImpl(),
  );
}

/// Opened to answer a question rather than to be browsed to, but it is
/// still an ordinary page, so a deep link lands on it too.
@RoutePage()
class FeedUserPickerPage extends StatelessWidget {
  const FeedUserPickerPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const UserPickerScreen(coordinator: UserPickerCoordinatorImpl());
}

@RoutePage()
class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const ContactsScreen(coordinator: ContactsCoordinatorImpl());
}

/// The same profile screen as in the feed, with the other coordinator. This
/// pair of pages is the whole difference between the two tabs.
@RoutePage()
class ContactsUserProfilePage extends StatelessWidget {
  final String userId;

  const ContactsUserProfilePage({
    super.key,
    @PathParam('userId') required this.userId,
  });

  @override
  Widget build(BuildContext context) => UserProfileScreen(
    userId: userId,
    coordinator: const ContactsUserProfileCoordinatorImpl(),
  );
}
