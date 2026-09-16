# Routing. Coordinator

Demo project for the article "Flutter tips. Routing. Coordinator", about
moving transitions between screens out of the screens themselves.

## Branches

| Branch | What it shows |
| --- | --- |
| `main` | The shared base: domain, data, presentational widgets. No routing. |
| `part-1-imperative` | Imperative routing. A screen is given a callback whose parameter is a sealed class of transitions. |
| `part-2-gorouter` | Declarative routing on go_router, plus the coordinator pattern. |
| `part-3-autoroute` | The same on auto_route. Branched off `part-2-gorouter`. |

Branching `part-3-autoroute` off `part-2-gorouter` is deliberate. The command

```
git diff part-2-gorouter..part-3-autoroute -- lib ':!*.gr.dart'
```

shows the routing layer and nothing else: the screens and their contracts are
word for word the same in both branches. The pathspec leaves out the generated
`app_router.gr.dart`, which would otherwise bury the diff.

## The demo app

A bottom bar with two tabs, each with its own `Navigator` and its own
master-detail stack.

```
Feed     : post list -> post -> author profile -> posts by author -> post ...
                          `-> pick a user, which answers back with one
Contacts : people    -> profile -> posts by that person
```

The profile screen is shared by both tabs and behaves differently in each.

| Where the profile was opened | What "Posts by this user" does |
| --- | --- |
| Feed | Pushes the list onto the stack of the same tab |
| Contacts | Switches to the Feed tab and opens the list there |

The screen is the same one either way. What differs is the implementation it
is handed from the outside: a coordinator in parts 2 and 3, a callback in
part 1. That is the whole point of the article, in the least code it takes.

In part 1 the same pattern appears twice. A screen reports what its user asked
for and stops, because it is not the expert on what happens next. A tab router
answers everything that belongs to its own stack, and reports the rest to the
shell, which is the only place that knows both tabs exist.

## Returning a result

The post screen asks for a user and waits for the answer. The picker never pops
itself: it reports who was picked, and the router decides that this ends the
screen. Each branch carries the answer back its own way.

| Branch | How the answer travels |
| --- | --- |
| `part-1-imperative` | A route case is generic in what it produces, so one callback still serves the whole family and stays typed |
| `part-2-gorouter` | A coordinator method with its own return type, over `push<User>` |
| `part-3-autoroute` | The same method, over a typed route object |

## The same three files on every branch

Whichever library is underneath, the routing lives in the same three files:

```
lib/router/
  app_router.dart            the whole tree, the only place that knows both tabs
  feed_tab_router.dart       everything the feed tab can show and do
  contacts_tab_router.dart   the same for contacts
```

What sits inside a tab file is what changes from branch to branch, and that
difference is the article:

| Branch | Inside a tab file |
| --- | --- |
| `part-1-imperative` | The screens of the tab, and the transition each request leads to |
| `part-2-gorouter` | The routes of the tab, and the coordinators that answer its screens |
| `part-3-autoroute` | The pages and routes of the tab, and the same coordinators |

The rest of `lib/router` is whatever the approach needs of its own: the shell
screen, the `Navigator` plumbing in part 1, the paths in parts 2 and 3, and the
generated `app_router.gr.dart` in part 3.

## The same test on all three branches

`test/app_navigation_test.dart` is byte for byte identical on every part
branch. Check it yourself:

```
for b in part-1-imperative part-2-gorouter part-3-autoroute; do
  git show "$b:test/app_navigation_test.dart" | shasum
done
```

The three routing layers are interchangeable from the outside. The choice
between them is about the shape of the code, not about what the app can do.

## Running it

```
git switch part-2-gorouter
flutter pub get
flutter run
```

`app_router.gr.dart` is committed, so `part-3-autoroute` runs the same way.
Regenerate it after changing anything the generator reads:

```
dart run build_runner build
```

## The `reference` folder

Excerpts from a production project, the source of these patterns. They are not
part of the build and are excluded from the analyzer.
