import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:routing_coordinator_flutter/router/app_router_path.dart';
import 'package:routing_coordinator_flutter/router/contacts_tab_router.dart';
import 'package:routing_coordinator_flutter/router/feed_tab_router.dart';
import 'package:routing_coordinator_flutter/router/root_page.dart';

part 'app_router.gr.dart';

/// The tree of everything the app can show. Each tab keeps its own branch of
/// it, together with its pages and the answers to their requests, in a file of
/// its own.
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      path: AppRouterPath.root,
      page: RootRoute.page,
      initial: true,
      children: [feedTabRoute, contactsTabRoute],
    ),
  ];
}

