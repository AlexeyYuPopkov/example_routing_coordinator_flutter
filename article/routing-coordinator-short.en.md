# Flutter Navigation: A Screen Should Not Decide Where a Tap Leads

*The principle in short. The full version, with three complete implementations — `Navigator`, go_router and auto_route — is linked at the end.*

## The guidelines lead the wrong way

A standard example from the go_router documentation:

```dart
TextButton(
  onPressed: () => context.go('/users/123'),
)
```

auto_route goes further and adds the extensions `context.router.push(...)` and `context.pushRoute(...)`, which make such a call even shorter. Neither the Flutter documentation nor the guides of these packages mention that a transition defined inside widget code is an architectural problem. On the contrary, it is presented as the normal way.

This is not specific to Flutter. In iOS, the guidelines from Apple configure the next screen — and often create it — in the code of the previous one: this is true for storyboard segues, for `pushViewController`, and for the early `NavigationLink(destination:)`. For this reason the Coordinator pattern [\[1\]](#references) remains common practice there. Android came to the opposite conclusion from another direction: the official Jetpack Compose guide requires developers not to pass `navController` into a composable, but to pass callbacks instead, so that screens stay reusable and testable [\[2\]](#references).

## What it costs

A screen that knows where it leads pays for it four times:

- **Two responsibilities in one class.** The screen is now responsible for the user interface, for reactions to user actions, and for navigation, including the creation of other screens and passing dependencies to them.
- **Poor reusability.** A screen that decides where to go next is difficult to place into another context, where the transition must be different.
- **Tight coupling.** Every screen knows about the next screens, so a change in one of them requires changes in others.
- **Low testability.** The reaction of a screen to a user action cannot be checked without navigation: the screen requires a configured router, and the result of a tap is not the fact of a request, but a transition that has actually happened. A unit test turns into an integration test.

## The principle

The problem appears because the previous screen owns information about the next one. The implementation of the transition has to be moved out of the screen code — and the question is where to move it.

The answer is given by **Information Expert**, one of the GRASP principles described by Craig Larman [\[3\]](#references): a responsibility is assigned to the class that has the information necessary to fulfil it.

The screen does not have this information. Which tab it belongs to, which stack is below it, whether the next screen must be opened above the current one or the whole section must be switched — none of it is known inside the screen. It exists in the place where the application is assembled from screens.

So the screen declares an abstract contract for a transition and reports a user request through it:

```dart
FilledButton.tonal(
  onPressed: () => coordinator.onUserPostsRoute(context, userId: userId),
  child: Text('Posts by this user ($postCount)'),
)
```

The screen states what the user asked for. What this means is decided elsewhere — and the implementation of the contract belongs as close as possible to the place where the constructor of this screen was called.

## The case that makes it obvious

Take an application with two tabs — a feed and a list of contacts — and one profile screen used in both. The profile has a "Posts by this user" button. In the feed, the list of the author's posts is added to the stack of the current tab. In the contacts tab, the same button switches the application to the feed and opens the list there.

The screen is the same, the button is the same, the user request is the same, and the correct answer is different. Any decision taken inside the screen would require it to know which tab it was opened in — exactly the information it does not have. The place that does have it is the one that built this screen.

## The form of the contract

A callback and an abstract interface work equally well; the choice is a matter of syntax.

A callback reads well when the tree of transitions is assembled by hand, as with the built-in `Navigator`: the handler is written at the point where the screen is constructed, so the request and the answer to it are visible together. With go_router and auto_route the `GoRouter(routes: [...])` constructor already shows the tree of paths, and handlers written inside it would only clutter that picture; there an interface implementation kept next to the tree keeps both readable.

## It does not have to be adopted at once

This is the practical part. Transitions are moved out of screens one screen at a time, without changing the navigation library and without changing the rest of the application. Each step is complete in itself: the processed screen stops depending on where it leads and becomes suitable for reuse in another context, while the rest of the navigation continues to work as before. As a side effect, such a screen can be tested without a router, because a stub is passed to it instead of a real implementation.

For the same reason the approach applies to existing code, not only to a new project. And it does not depend on a specific library: the form of the contract and the mechanics of a transition are defined by the selected tool, but the distribution of responsibilities stays the same.

The approach is not new — in iOS it is known as the Coordinator pattern [\[1\]](#references), a similar approach for Flutter is described in [\[4\]](#references), and part of it is a port of a compact router for iOS [\[5\]](#references). What is worth repeating is the reason behind it: the screen is not the one who knows.

---

The full article shows the same navigation implemented three times — with the built-in `Navigator`, with go_router and with auto_route — with all the code: **[link to the full article]**. The source code of all three implementations is in the repository [\[6\]](#references).

## References

1. [Khanlou, "The Coordinator" (2015)](https://khanlou.com/2015/01/the-coordinator/) — the article that introduced the Coordinator pattern.

2. [Navigation with Compose](https://developer.android.com/develop/ui/compose/navigation) — the official Android guide: do not pass `navController` into a composable, pass callbacks instead.

3. Larman, *Applying UML and Patterns* (1997) — the book that describes the GRASP principles, including Information Expert.

4. [Shevchuk, "Navigation done right: a case for hierarchical routing with Flutter" (2020)](https://medium.com/flutter-community/navigation-done-right-a-case-for-hierarchical-routing-with-flutter-ca0aac1275ad) — a similar approach in Flutter: the decision about a transition is passed from a screen to its parent.

5. [Popkov, "iOS Navigation: A Compact Router Approach"](https://medium.com/@alexey.yu.popkov/ios-navigation-a-compact-router-approach-46cffa04a6ef) — a simplified version of the approach for iOS.

6. [example_routing_coordinator_flutter](https://github.com/AlexeyYuPopkov/example_routing_coordinator_flutter) — the repository with the code of all three implementations.
