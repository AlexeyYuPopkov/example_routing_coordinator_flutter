/// The two bottom bar destinations, each with its own [Navigator] and its own
/// back stack.
enum AppTab { feed, contacts }

/// Implemented by the shell that owns the bottom bar.
///
/// A route handler of one tab uses it when a transition has to continue in
/// another tab.
abstract interface class TabSwitcher {
  void switchTo(AppTab tab);
}
