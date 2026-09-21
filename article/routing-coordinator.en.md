# Flutter Navigation: Moving Transitions Out of Screens

## Introduction

I have worked in mobile development for more than ten years: first with iOS, then with Flutter. During all this time I have met the same problem. Navigation APIs are designed in such a way that following the common guidelines leads to poor architectural decisions.

In iOS, the guidelines from Apple configure the next screen — and often create it — in the code of the previous one. This is true for every navigation method. For example, with storyboard segues the next screen is configured in `prepare(for:sender:)` of the source view controller. With programmatic navigation, `pushViewController` also takes a ready instance, and this instance is usually created in the code of the previous screen.

Early SwiftUI repeated the same scheme: `NavigationLink(destination:)` builds the next screen directly at the place of the tap. iOS 16 introduced `NavigationStack`, where the destination is declared separately from the link, and the stack path can be stored outside the view. However, the guidelines still do not say that the decision about a transition is not the responsibility of the screen. For this reason the Coordinator pattern [\[1\]](#references), [\[2\]](#references), or its simplified version [\[3\]](#references), remains common practice in iOS.

Android came to the same conclusion from another direction. The official Jetpack Compose guide requires developers not to pass `navController` into a composable, but to pass callbacks instead. This keeps screens reusable and testable [\[4\]](#references).

In Flutter the situation is more complex because of the web. Paths were added to transitions — the text that a user sees in the address bar. The built-in API (Navigator 2.0) is verbose, so developers rarely use it directly, mostly in simple cases. Third-party packages are more common; go_router and auto_route are the most popular ones. However, nothing changes with them. Neither the Flutter documentation nor the guides of these packages mention that defining a transition inside widget code is an architectural problem. On the contrary, it is presented as the normal way. A standard example from the go_router documentation looks like this:

```dart
TextButton(
  onPressed: () => context.go('/users/123'),
)
```

auto_route goes further and adds the extensions `context.router.push(...)` and `context.pushRoute(...)`, which make calls to navigation from a widget even more convenient.

This leads to the following problems:

- **Complexity and a violation of SRP.** The screen is now responsible not only for the user interface and for reactions to user actions, but also for navigation, including the creation of other screens and passing dependencies to them. Two responsibilities are placed in one class, and the screen is no longer easy to read.

- **Poor reusability.** A screen that decides where to go next is difficult to place into another context, where the transition must be different.

- **Tight coupling.** Every screen knows about the next screens. The architecture becomes fragile: a change in one screen requires changes in others.

- **Low testability.** It is not possible to check the reaction of a screen to a user action without navigation. The screen requires a configured router, and the result of a tap is not the fact of a request, but a transition that has actually happened. A unit test of a screen turns into an integration test.

## Solution

The problem appears because the previous screen owns information about the next one. The most obvious solution is to **move the implementation of the transition out of the screen code**.

The next question is: where should it be moved? The answer is given by the **Information Expert** pattern: a responsibility is assigned to the object that has the information required to fulfil it.

<details>
<summary>More about the pattern</summary>

Information Expert is one of the GRASP principles (General Responsibility Assignment Software Patterns), described by Craig Larman in the book "Applying UML and Patterns" (1997). The principle answers the question of which object should receive a responsibility, and it is formulated as follows: assign a responsibility to the class that has the information necessary to fulfil it.

</details>

The screen does not have the information about where a tap leads: which tab the screen belongs to, which stack is below it, whether the next screen must be opened above the current one or the section must be switched. This information exists in the place where the application is assembled from screens. The screen itself only declares an abstract interface for such a transition. A typical transition then looks like this:

```dart
FilledButton.tonal(
  onPressed: () => coordinator.onUserPostsRoute(context, userId: userId),
  child: Text('Posts by this user ($postCount)'),
)
```

The implementation of this interface should be kept as close as possible to the place where transitions are configured. In other words, it should be kept where the constructor of the current screen was called.

The approach is not new. In iOS it is known as the Coordinator pattern [\[1\]](#references), [\[2\]](#references), and a similar approach for Flutter is described in [\[6\]](#references). One point is more important: **it does not have to be adopted at once**. Transitions can be moved out of screens one screen at a time, without changing the navigation library and without changing the rest of the application. For this reason the approach can be applied not only to a new project, but also to existing code. Each processed screen immediately stops depending on where it leads, and the rest of the navigation continues to work as before.

This article therefore has two goals.

The first goal is to show the approach, and its variations, that follows the Information Expert principle and moves a transition out of widget code to the place where all the required information is available.

The second goal, which is equally important, is to obtain a place in the code that describes the navigation in a reasonably clear way.

## What is implemented

The article consists of three parts. Each part contains the same implementation of a typical navigation structure of a mobile application: two tabs with their own stacks, and a shared screen that behaves differently in each tab. Part 1 uses the imperative approach without any third-party packages. Parts 2 and 3 implement the same behaviour with go_router and auto_route.

Each part shows the same approach, but the form differs. In part 1 the transition is moved out of the screen with a callback; in parts 2 and 3 an abstract interface is used. The reason for this difference is that in part 1 a callback looks clearer in terms of syntax.

## Example application

The source code is available in the repository [\[5\]](#references). Each implementation is placed in a separate branch: `part-1-imperative`, `part-2-gorouter`, `part-3-autoroute`. The `main` branch contains the shared part — models, repository and presentation widgets — without navigation. The application is identical in all branches; only the navigation layer differs.

In all three branches the navigation is placed in the same files:

```
lib/router/
  app_router.dart            the tree of the application; the only place
                             that knows about both tabs
  feed_tab_router.dart       transitions of the Feed tab and answers to
                             requests of its screens
  contacts_tab_router.dart   the same for the Contacts tab
```

The application has two tabs, and each tab has its own `Navigator` and its own stack:

![Screen structure and transitions](https://habrastorage.org/getpro/habr/upload_files/f7b/d50/64b/f7bd5064b0a7eb437d447c8a42e73841.png)

Navigation requirements:

- `UserProfileScreen` is used in both tabs;
- `PostListScreen` is used twice: as the root of the Feed tab, and as the list of posts of a selected author;
- `UserPickerScreen` is opened to return a result — the selected user — to the screen that started the request;
- the behaviour of the "Posts by this user" button on the profile screen depends on the tab in which this screen is opened. In the Feed tab the list of posts is added to the stack of the current tab. In the Contacts tab the application switches to the Feed tab and opens the list there.

The last requirement defines the structure of the navigation: the same screen handles the same user request in two different ways, depending on the context in which it was opened.

---

## Part 1. Imperative navigation

This implementation uses no third-party packages: only `Navigator` and `GlobalKey`. The contract of a transition is expressed by a callback instead of an abstract interface, for reasons of syntax. The handler is written exactly where the screen is created, so the transition and its destination are visible in one place, without a separate implementation class.

The four files below are listed in the order in which a developer reads them after opening the project.

### main.dart

```dart
void main() => runApp(App(appRouter: AppRouter()));

class App extends StatelessWidget {
  final AppRouter appRouter;

  const App({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      ...
      home: RootScreen(appRouter: appRouter),
    );
  }
}
```

`AppRouter` is a plain object. It is created before the widget tree is built and is passed to the root screen.

### root_screen.dart

The root screen is responsible for one level of navigation: switching between tabs. It does not know which screens are placed inside the tabs. The content of each tab is built by the corresponding tab router, which is passed through `rootBuilder`.

<details>
<summary>Listing: root_screen.dart</summary>

```dart
class RootScreen extends StatelessWidget {
  final AppRouter appRouter;

  const RootScreen({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appRouter.currentTab,
      builder: (context, currentTab, child) => Scaffold(
        body: IndexedStack(
          index: currentTab.index,
          children: [
            TabNavigator(
              navigatorKey: appRouter.feedNavigatorKey,
              rootBuilder: appRouter.feedTabRouter.buildRoot,
            ),
            TabNavigator(
              navigatorKey: appRouter.contactsNavigatorKey,
              rootBuilder: appRouter.contactsTabRouter.buildRoot,
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentTab.index,
          onDestinationSelected: (index) =>
              appRouter.switchTo(AppTab.values[index]),
          destinations: const [...],
        ),
      ),
    );
  }
}
```

</details>

### app_router.dart

```dart
enum AppTab { feed, contacts }

final class AppRouter {
  final feedNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'feed');

  final contactsNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'contacts',
  );

  final currentTab = ValueNotifier(AppTab.feed);

  late final feedTabRouter = FeedTabRouter(navigatorKey: feedNavigatorKey);

  late final contactsTabRouter = ContactsTabRouter(
    navigatorKey: contactsNavigatorKey,
    onRoute: _onContactsTabRoute,
  );

  void switchTo(AppTab tab) => currentTab.value = tab;

  /// The last handler in the chain. A transition between tabs requires
  /// knowledge of both tabs, so it is handled here.
  Future<T?> _onContactsTabRoute<T>(ContactsTabRoute<T> route) async {
    switch (route) {
      case UserPostsRoute(:final userId):
        switchTo(AppTab.feed);
        feedTabRouter.openUserPosts(userId);
        return null;
    }
  }
}
```

This is the only place that knows about both tabs. The Contacts tab cannot open the posts of an author inside itself, because these posts belong to another tab. The tab passes the request here, and here the application switches the tab and opens the list in the feed.

### feed_tab_router.dart

```dart
final class FeedTabRouter with TabRouter {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  const FeedTabRouter({required this.navigatorKey});

  @override
  Widget buildRoot(BuildContext context) => _postList();

  /// Entry point for a request that comes from the Contacts tab.
  void openUserPosts(String userId) => push(_postList(authorId: userId));

  Widget _postList({String? authorId}) => PostListScreen(
    authorId: authorId,
    onRoute: <T>(route) async {
      switch (route) {
        case OpenPostRoute(:final postId):
          push(_postDetails(postId));
          return null;
      }
    },
  );

  Widget _postDetails(String postId) => PostDetailsScreen(
    postId: postId,
    onRoute: <T>(route) async {
      switch (route) {
        case OpenAuthorRoute(:final userId):
          push(_userProfile(userId));
          return null;
        case PickUserRoute():
          return push<T>(_userPicker());
      }
    },
  );

  Widget _userProfile(String userId) => UserProfileScreen(
    userId: userId,
    onRoute: <T>(route) async {
      switch (route) {
        case OpenUserPostsRoute(:final userId):
          openUserPosts(userId);
          return null;
      }
    },
  );

  Widget _userPicker() => UserPickerScreen(
    onRoute: <T>(route) async {
      switch (route) {
        case UserPickedRoute(:final user):
          pop(user);
          return null;
      }
    },
  );
}
```

The file contains all transitions of the tab: one method per screen, and inside the method all directions to which this screen leads. The post list opens a post, a post opens the author profile or the user picker, and the profile opens the list of posts of the author.

### contacts_tab_router.dart

The Contacts tab is built in the same way, but it cannot handle one of the requests, because the posts of an author belong to another tab. For this reason the tab declares its own set of requests and passes such a request to the level above — to the object that knows about both tabs.

```dart
sealed class ContactsTabRoute<T> {
  const ContactsTabRoute();
}

final class UserPostsRoute extends ContactsTabRoute<Never> {
  final String userId;

  const UserPostsRoute(this.userId);
}

typedef OnContactsTabRoute = Future<T?> Function<T>(ContactsTabRoute<T> route);

final class ContactsTabRouter with TabRouter {
  ...

  final OnContactsTabRoute onRoute;

  @override
  Widget buildRoot(BuildContext context) => _contacts();

  Widget _contacts() => ContactsScreen(...);

  /// The same screen and the same request as in the Feed tab, but the answer
  /// is different: there the posts stay in the stack, here the request is
  /// passed to the level above.
  Widget _userProfile(String userId) => UserProfileScreen(
    userId: userId,
    onRoute: <T>(route) async {
      switch (route) {
        case OpenUserPostsRoute(:final userId):
          onRoute(UserPostsRoute(userId));
          return null;
      }
    },
  );
}
```

The profile screen here is the same class as in the feed, and it sends the same request. Only the answer is different, and this answer is located in the file of the tab, next to its other transitions.

### Reading order

The navigation is read from top to bottom through the files, and each level shows exactly the layer for which this level is responsible:

- `main.dart` — the application and the root screen;
- `root_screen.dart` — two tabs and switching between them;
- `app_router.dart` — both tabs and transitions between them;
- `feed_tab_router.dart`, `contacts_tab_router.dart` — all screens of a tab and transitions inside it.

If a level does not have the required information, it does not handle the request but passes it to the level above. A screen reports a request to the tab router, and the tab router reports it to `AppRouter` if the request goes outside its stack. One file is enough to understand the navigation of a tab; four files, read one after another, are enough to understand the navigation of the application.

---

## Part 2. go_router

This library provides a tree of locations, and a transition is a move to a location. The approach is the same, but the form of the contract is different: instead of a callback the screen takes an abstract interface. The visible tree of transitions, which the imperative approach had to assemble by hand, is here provided by the `GoRouter(routes: [...])` constructor itself, and `onRoute` handlers with their `switch` written inside it would only clutter that picture. Nothing, however, prevents using callbacks here as well, exactly as in part 1.

The order of the files is the same.

### main.dart

The only difference from part 1 is one line: `routerConfig` is passed instead of `home`.

<details>
<summary>Listing: main.dart</summary>

```dart
void main() => runApp(App(appRouter: AppRouter()));

class App extends StatelessWidget {
  final AppRouter appRouter;

  const App({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      ...
      routerConfig: appRouter.router,
    );
  }
}
```

</details>

### root_screen.dart

```dart
class RootScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const RootScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [...],
      ),
    );
  }
}
```

The root screen is responsible for switching between tabs and does not know what is inside them.

### app_router.dart

```dart
final class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: AppRouterPath.feed,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RootScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [feedTabRoute]),
          StatefulShellBranch(routes: [contactsTabRoute]),
        ],
      ),
    ],
  );
}
```

There are two branches, and each branch has its own stack. A transition between tabs requires no separate handling: the location belongs to another branch, and the shell switches the tab itself.

### feed_tab_router.dart

```dart
GoRoute get feedTabRoute => GoRoute(
  path: AppRouterPath.feed,
  builder: (context, state) =>
      const PostListScreen(coordinator: FeedPostListCoordinatorImpl()),
  routes: [
    GoRoute(
      path: AppRouterPath.post,
      builder: (context, state) => PostDetailsScreen(
        postId: state.pathParameters[AppRouterParam.postId]!,
        coordinator: const FeedPostDetailsCoordinatorImpl(),
      ),
    ),
    GoRoute(
      path: AppRouterPath.user,
      builder: (context, state) => UserProfileScreen(
        userId: state.pathParameters[AppRouterParam.userId]!,
        coordinator: const FeedUserProfileCoordinatorImpl(),
      ),
    ),
    GoRoute(
      path: AppRouterPath.userPicker,
      builder: (context, state) =>
          const UserPickerScreen(coordinator: UserPickerCoordinatorImpl()),
    ),
    GoRoute(
      path: AppRouterPath.userPosts,
      builder: (context, state) => PostListScreen(
        authorId: state.pathParameters[AppRouterParam.userId]!,
        coordinator: const FeedPostListCoordinatorImpl(),
      ),
    ),
  ],
);

final class FeedPostListCoordinatorImpl implements PostListScreenCoordinator {
  const FeedPostListCoordinatorImpl();

  @override
  void onPostRoute(BuildContext context, {required String postId}) =>
      GoRouter.of(context)
          .push(AppRouterPath.postIn(AppRouterPath.feed, postId));
}

final class FeedPostDetailsCoordinatorImpl
    implements PostDetailsScreenCoordinator {
  ...

  @override
  Future<User?> onPickUserRoute(BuildContext context) => GoRouter.of(context)
      .push<User>(AppRouterPath.userPickerIn(AppRouterPath.feed));
}

/// In the feed the posts of an author stay in the same stack — `push`.
final class FeedUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const FeedUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      GoRouter.of(context)
          .push(AppRouterPath.userPostsIn(AppRouterPath.feed, userId));
}

...
```

The file of a tab has two levels: the tree of locations above, and the implementations of the interfaces of its screens below.

### contacts_tab_router.dart

The file of the Contacts tab is built in exactly the same way, and it fits on one screen:

```dart
GoRoute get contactsTabRoute => GoRoute(
  path: AppRouterPath.contacts,
  builder: (context, state) =>
      const ContactsScreen(coordinator: ContactsCoordinatorImpl()),
  routes: [
    // The same profile screen as in the feed, with another implementation.
    GoRoute(
      path: AppRouterPath.user,
      builder: (context, state) => UserProfileScreen(
        userId: state.pathParameters[AppRouterParam.userId]!,
        coordinator: const ContactsUserProfileCoordinatorImpl(),
      ),
    ),
  ],
);

final class ContactsCoordinatorImpl implements ContactsScreenCoordinator {
  const ContactsCoordinatorImpl();

  @override
  void onUserProfileRoute(BuildContext context, {required String userId}) =>
      GoRouter.of(context)
          .push(AppRouterPath.userIn(AppRouterPath.contacts, userId));
}

/// The same screen and the same request as in the Feed tab, but the answer is
/// different. `go` instead of `push`: the location belongs to another branch,
/// so the shell switches the tab itself, and the Contacts stack stays as it
/// was.
final class ContactsUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const ContactsUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      GoRouter.of(context)
          .go(AppRouterPath.userPostsIn(AppRouterPath.feed, userId));
}
```

The two tab files are built in the same way, the profile screen in them is the same class, and the whole difference between the requirements is one word in one implementation: `push` in the feed and `go` in the contacts.

### Reading order

The reading order is preserved, and each level shows its own layer:

- `main.dart` — the application and the router configuration;
- `root_screen.dart` — two tabs and switching between them;
- `app_router.dart` — both branches of the tree;
- `feed_tab_router.dart`, `contacts_tab_router.dart` — all locations of a tab and the answers to the requests of its screens.

The difference from part 1 is that a request does not have to be passed to a higher level: a transition to another tab is an ordinary location, and the difference between the tabs is expressed by one word in one implementation.

---

## Part 3. auto_route

The screens and their contracts are exactly the same as in part 2. There are two differences: the destination is a generated object instead of a string, and a layer of pages appears between a screen and the router. This layer keeps the annotations of the generator outside the screens.

The order of the files is the same.

### main.dart

The difference from part 2 is that the router configuration is taken from the generated `config()`.

<details>
<summary>Listing: main.dart</summary>

```dart
void main() => runApp(App(appRouter: AppRouter()));

class App extends StatelessWidget {
  final AppRouter appRouter;

  const App({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      ...
      routerConfig: appRouter.config(),
    );
  }
}
```

</details>

### root_page.dart

The root screen is built from the tabs with `AutoTabsScaffold`.

<details>
<summary>Listing: root_page.dart</summary>

```dart
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
        destinations: const [...],
      ),
    );
  }
}
```

</details>

The tabs themselves are empty nested routers, so they need no widgets of their own:

```dart
// app_tabs.dart
const feedTab = EmptyShellRoute('FeedTab');
const contactsTab = EmptyShellRoute('ContactsTab');
```

### app_router.dart

```dart
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
```

### feed_tab_router.dart

```dart
AutoRoute get feedTabRoute => AutoRoute(
  path: AppRouterPath.feed,
  page: feedTab,
  children: [
    AutoRoute(path: AppRouterPath.initial, page: FeedRoute.page),
    AutoRoute(path: AppRouterPath.post, page: FeedPostDetailsRoute.page),
    AutoRoute(path: AppRouterPath.user, page: FeedUserProfileRoute.page),
    AutoRoute(path: AppRouterPath.userPosts, page: FeedUserPostsRoute.page),
    AutoRoute(path: AppRouterPath.userPicker, page: FeedUserPickerRoute.page),
  ],
);

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

...

final class FeedUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const FeedUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      AutoRouter.of(context).push(FeedUserPostsRoute(userId: userId));
}

...
```

There are three levels here: the tree of locations, the pages, and the implementations of the interfaces. A page connects a screen with the implementation that this screen must receive in this tab.

A transition to another tab requires a separate decision. A nested stack router cannot add a screen to a neighbouring tab, so the root router is used, and auto_route activates the required tab itself.

```dart
// contacts_tab_router.dart
final class ContactsUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const ContactsUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      AutoRouter.of(context)
          .root
          .navigatePath(AppRouterPath.feedUserPosts(userId));
}
```

### Reading order

The reading order has not changed:

- `main.dart` — the application and the router configuration;
- `root_page.dart` — two tabs and switching between them;
- `app_router.dart` — the whole tree;
- `feed_tab_router.dart` — the locations of a tab, its pages and the answers to the requests of its screens.

Code generation adds a layer of pages, but it changes neither the reading order nor the distribution of responsibilities between the levels.

---

## Applicability

The approach does not depend on a specific library. A screen reports a user request; the decision is made by the object that has the information required for this decision. The form of the contract — a callback or an abstract interface — and the mechanics of a transition are defined by the selected tool, but the distribution of responsibilities stays the same. This article shows three implementations: with the built-in `Navigator`, with go_router and with auto_route. The same approach can be applied to any other library.

This leads to a practical property: the approach is suitable for gradual refactoring. Transitions are moved out of screens one screen at a time, without a change of the navigation library and without changes in the rest of the application. Each step is complete in itself: a screen stops depending on where it leads and becomes suitable for reuse in another context. As a side effect, such a screen can be tested without a router, because a stub is passed to it instead of a real implementation of the transition.

## References

1. [Khanlou, "The Coordinator" (2015)](https://khanlou.com/2015/01/the-coordinator/) — the article that introduced the Coordinator pattern.

2. [Hudson, "How to use the coordinator pattern in iOS apps"](https://www.hackingwithswift.com/articles/71/how-to-use-the-coordinator-pattern-in-ios-apps) — a detailed description of the Coordinator in practice.

3. [Popkov, "iOS Navigation: A Compact Router Approach"](https://medium.com/@alexey.yu.popkov/ios-navigation-a-compact-router-approach-46cffa04a6ef) — a simplified version of the approach for iOS. Part 1 of this article is its port to Flutter.

4. [Navigation with Compose](https://developer.android.com/develop/ui/compose/navigation) — the official Android guide: do not pass `navController` into a composable, pass callbacks instead.

5. [example_routing_coordinator_flutter](https://github.com/AlexeyYuPopkov/example_routing_coordinator_flutter) — the repository with the code of all three implementations.

6. [Shevchuk, "Navigation done right: a case for hierarchical routing with Flutter" (2020)](https://medium.com/flutter-community/navigation-done-right-a-case-for-hierarchical-routing-with-flutter-ca0aac1275ad) — a similar approach in Flutter: the decision about a transition is passed from a screen to its parent.