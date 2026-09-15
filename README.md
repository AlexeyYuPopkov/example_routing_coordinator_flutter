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
git diff part-2-gorouter..part-3-autoroute
```

shows the routing layer and nothing else: the screens and their contracts are
word for word the same in both branches.

## The demo app

A bottom bar with two tabs, each with its own `Navigator` and its own
master-detail stack.

```
Feed     : post list -> post -> author profile -> posts by author -> post ...
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

## Running it

```
git switch part-2-gorouter
flutter pub get
flutter run
```

Branch `part-3-autoroute` needs code generation first:

```
dart run build_runner build
```

## The `reference` folder

Excerpts from a production project, the source of these patterns. They are not
part of the build and are excluded from the analyzer.
