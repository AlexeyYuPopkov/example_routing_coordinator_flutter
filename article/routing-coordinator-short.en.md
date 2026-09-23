# Flutter Navigation Is an Information Expert Problem

*This article is about the principle. The code of the sample application that illustrates it — the same navigation implemented with `Navigator`, with go_router and with auto_route — is examined in a separate article, linked at the end.*

## The guidelines lead the wrong way

A standard example from the go_router documentation:

**Listing 1.** A transition defined inside widget code.

```dart
TextButton(
  onPressed: () => context.go('/users/123'),
)
```

auto_route goes further and adds the extensions `context.router.push(...)` and `context.pushRoute(...)`, which make such a call even shorter. Neither the Flutter documentation nor the guides of these packages mention that a transition defined inside widget code is an architectural problem. On the contrary, it is presented as the normal way.

This is not specific to Flutter. In iOS, the guidelines from Apple configure the next screen — and often create it — in the code of the previous one: this is true for storyboard segues, for `pushViewController`, and for the early `NavigationLink(destination:)`. For this reason the Coordinator pattern [\[1\]](#references), [\[2\]](#references) remains common practice there. Android came to the opposite conclusion from another direction: the official Jetpack Compose guide requires developers not to pass `navController` into a composable, but to pass callbacks instead, so that screens stay reusable and testable [\[3\]](#references).

## The resulting design errors

A screen that knows where it leads introduces four errors at once:

- **Two responsibilities in one class.** The screen is now responsible for the user interface, for reactions to user actions, and for navigation, including the creation of other screens and passing dependencies to them.
- **Poor reusability.** A screen that decides where to go next is difficult to place into another context, where the transition must be different.
- **Tight coupling.** Every screen knows about the next screens, so a change in one of them requires changes in others.
- **Low testability.** The reaction of a screen to a user action cannot be checked without navigation: the screen requires a configured router, and the result of a tap is not the fact of a request, but a transition that has actually happened. A unit test turns into an integration test.

## The principle

The problem appears because the previous screen owns information about the next one. The implementation of the transition has to be moved out of the screen code — and the question is where to move it.

The answer is given by **Information Expert**, one of the GRASP principles described by Craig Larman [\[4\]](#references): a responsibility is assigned to the class that has the information necessary to fulfil it.

This information is not the screen's own. Which tab it belongs to, which stack is below it, whether the next screen must be opened above the current one or the whole section must be switched — none of this is decided by the screen. It is decided in the place where the application is assembled from screens.

So the screen declares an abstract contract for a transition and reports a user request through it. Nothing beyond this contract is known to the screen:

**Listing 2.** The screen depends on a contract, not on a destination.

```dart
abstract interface class UserListScreenCoordinator {
  Future<T?> onUserRoute<T extends Object?>(
    BuildContext context, {
    required String userId,
  });
}

final class UserListScreen extends StatelessWidget {
  const UserListScreen({
    super.key,
    required this.users,
    required this.coordinator,
  });

  final List<User> users;
  final UserListScreenCoordinator coordinator;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      for (final user in users)
        ListTile(
          title: Text(user.name),
          onTap: () => coordinator.onUserRoute(context, userId: user.id),
        ),
    ],
  );
}
```

The handler now reports what the user did, and not where the application should go. The name of the method says the same thing: `onUserRoute` is a request about a user, not a command to open a route.

Suppose this list is used twice. It is the root of the contacts tab, and it is also the list of followers opened from the profile of the current user. A tap means the same thing in both places — show me this user — and it has to lead to different places: in the contacts tab the profile belongs to the stack of that tab, and among the followers it belongs to the profile stack, so that going back returns to the list of followers and not to the contacts.

The screen, the list and the user request are identical. The answers are not, and each of them is written where the screen is constructed:

**Listing 3.** Two implementations of the same contract, each next to the place where the screen is built.

```dart
final class ContactsUserListCoordinator implements UserListScreenCoordinator {
  const ContactsUserListCoordinator();

  @override
  Future<T?> onUserRoute<T extends Object?>(
    BuildContext context, {
    required String userId,
  }) => context.push<T>('/contacts/users/$userId');
}

final class FollowersUserListCoordinator implements UserListScreenCoordinator {
  const FollowersUserListCoordinator();

  @override
  Future<T?> onUserRoute<T extends Object?>(
    BuildContext context, {
    required String userId,
  }) => context.push<T>('/profile/followers/$userId');
}
```

Neither destination can be chosen inside the screen — not because the information is out of reach there, but because reaching for it is the error itself. A widget can always ask `GoRouter.of(context)`, or its auto_route counterpart, where it currently is. Having asked, the screen would then have to enumerate the places it can be opened from, that is, to know the structure of the whole application; every new place of use would mean editing the screen again, and the coupling that was just removed would be back. The information is available to the screen, but it is not the screen's own.

The choice of the implementation is made at the only point that knows the context — where the screen is constructed. This point is not a property of go_router:

**Listing 4.** The same choice, expressed with three different tools.

```dart
// go_router
GoRoute(
  path: '/contacts/users',
  builder: (context, state) => UserListScreen(
    users: allUsers,
    coordinator: const ContactsUserListCoordinator(),
  ),
)

// auto_route: the same choice is made in the page that wraps the screen
@RoutePage()
final class ContactsUserListPage extends StatelessWidget {
  const ContactsUserListPage({super.key});
  @override
  Widget build(BuildContext context) => UserListScreen(
        users: allUsers,
        coordinator: const ContactsUserListCoordinator(),
      );
}

// the built-in Navigator: the same choice is made where the route is created
MaterialPageRoute(
  builder: (_) => UserListScreen(
    users: allUsers,
    coordinator: const ContactsUserListCoordinator(),
  ),
)
```

Nothing has been added to the application. The call that stood inside the widget in Listing 1 is still a single `context.push`, and it has only moved to the object that has the right to make this decision.

### Where the implementation belongs

The implementation of the contract belongs where the screen is created, not where the screen is declared. The object that creates the screen is the one that knows the context — the tab, the stack, the flow the screen was opened in — and keeping the implementation there puts the request and the answer to it in one place. Keeping it next to the screen would only return the same knowledge to the screen through a longer path.

In practice this means a different place for every tool, and the same rule in each of them. With the built-in `Navigator`, the implementation goes where the route is created — into the object that owns the stack. With go_router, it goes next to the `GoRoute` whose `builder` passes it to the screen. With auto_route, it goes into the page that wraps the screen, because that page is where the screen is finally assembled and where the generated route leads.

The principle itself is indifferent to this choice. Only the address of "the place where the screen is constructed" changes from tool to tool; which object is allowed to decide does not.

### A callback instead of an interface

An abstract interface is not the only possible form of the contract. The screen can take a callback instead — `Future<T?> Function<T extends Object?>(BuildContext context, String userId) onUserRoute` — and the handler is then written directly at the point where the screen is constructed. A callback reads well when the tree of transitions is assembled by hand; an interface reads better when the library already shows that tree, as the `GoRouter(routes: [...])` constructor does. The choice is a matter of syntax, not of responsibility.

## It does not have to be adopted at once

This is the practical part. Transitions are moved out of screens one screen at a time, without changing the navigation library and without changes in the rest of the application. Each step is complete in itself: the processed screen stops depending on where it leads and becomes suitable for reuse in another context, while the rest of the navigation continues to work as before. As a side effect, such a screen can be tested without a router, because a stub is passed to it instead of a real implementation.

For the same reason the approach applies to existing code, not only to a new project. And it does not depend on a specific library: the form of the contract and the mechanics of a transition are defined by the selected tool, but the distribution of responsibilities stays the same.

The approach is not new. In iOS it is known as the Coordinator pattern [\[1\]](#references), [\[2\]](#references), and a simplified version of it is described in [\[5\]](#references); for Flutter a similar approach is described in [\[6\]](#references). What is worth repeating is the reason behind it: the screen is not the one who knows.

---

This article describes a principle, and the listings above are the shortest way to state it, not a recommended layout of files. One possible illustration of it is a sample application with two tabs, their own stacks and one profile screen that behaves differently in each tab: its navigation is implemented three times — with the built-in `Navigator`, with go_router and with auto_route. The code is in the repository [\[7\]](#references), and a separate article examines it in detail: **[link to the article about the example]**.

## References

1. [Khanlou, "The Coordinator" (2015)](https://khanlou.com/2015/01/the-coordinator/) — the article that introduced the Coordinator pattern.

2. [Hudson, "How to use the coordinator pattern in iOS apps"](https://www.hackingwithswift.com/articles/71/how-to-use-the-coordinator-pattern-in-ios-apps) — a detailed description of the Coordinator in practice.

3. [Navigation with Compose](https://developer.android.com/develop/ui/compose/navigation) — the official Android guide: do not pass `navController` into a composable, pass callbacks instead.

4. Larman, *Applying UML and Patterns* (1997) — the book that describes the GRASP principles, including Information Expert.

5. [Popkov, "iOS Navigation: A Compact Router Approach"](https://medium.com/@alexey.yu.popkov/ios-navigation-a-compact-router-approach-46cffa04a6ef) — a simplified version of the Coordinator approach for iOS.

6. [Shevchuk, "Navigation done right: a case for hierarchical routing with Flutter" (2020)](https://medium.com/flutter-community/navigation-done-right-a-case-for-hierarchical-routing-with-flutter-ca0aac1275ad) — a similar approach in Flutter: the decision about a transition is passed from a screen to its parent.

7. [example_routing_coordinator_flutter](https://github.com/AlexeyYuPopkov/example_routing_coordinator_flutter) — one possible illustration of the approach: a sample application whose navigation is implemented three ways.
