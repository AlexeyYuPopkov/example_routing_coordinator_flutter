import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/router/app_pages.dart';
import 'package:routing_coordinator_flutter/router/app_router_path.dart';
import 'package:routing_coordinator_flutter/router/app_tabs.dart';
import 'package:routing_coordinator_flutter/screens/contacts_screen.dart';
import 'package:routing_coordinator_flutter/screens/post_details_screen.dart';
import 'package:routing_coordinator_flutter/screens/post_list_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

part 'app_router.gr.dart';
part 'app_router_part.dart';

/// The tree of everything the app can show, and next to it, in the part file,
/// the answer to every request a screen can make.
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      path: AppRouterPath.root,
      page: RootRoute.page,
      initial: true,
      children: [
        AutoRoute(
          path: AppRouterPath.feed,
          page: feedTab,
          children: [
            AutoRoute(path: AppRouterPath.initial, page: FeedRoute.page),
            AutoRoute(
              path: AppRouterPath.post,
              page: FeedPostDetailsRoute.page,
            ),
            AutoRoute(
              path: AppRouterPath.user,
              page: FeedUserProfileRoute.page,
            ),
            AutoRoute(
              path: AppRouterPath.userPosts,
              page: FeedUserPostsRoute.page,
            ),
          ],
        ),
        AutoRoute(
          path: AppRouterPath.contacts,
          page: contactsTab,
          children: [
            AutoRoute(path: AppRouterPath.initial, page: ContactsRoute.page),
            AutoRoute(
              path: AppRouterPath.user,
              page: ContactsUserProfileRoute.page,
            ),
          ],
        ),
      ],
    ),
  ];
}
