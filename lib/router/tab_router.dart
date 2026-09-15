import 'package:flutter/material.dart';

/// What every tab router can do with its own stack.
///
/// A mixin rather than a base class on purpose. A tab router is not a kind of
/// anything, it just happens to own a navigator, and leaving the single
/// superclass slot free keeps the door open for composing several such
/// fragments into one router later.
mixin TabRouter {
  GlobalKey<NavigatorState> get navigatorKey;

  /// The screen this tab opens on.
  Widget buildRoot(BuildContext context);

  /// Pushes [screen] and, for a screen opened to answer something, gives back
  /// what it was popped with.
  Future<T?> push<T>(Widget screen) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return null;
    return navigator.push<T>(MaterialPageRoute(builder: (context) => screen));
  }

  /// Closes the topmost screen of this tab, handing [result] to whoever opened
  /// it. The screen being closed does not take part in this.
  void pop<T>(T result) => navigatorKey.currentState?.pop(result);
}
