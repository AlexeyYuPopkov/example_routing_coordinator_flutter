import 'package:flutter/material.dart';

/// One bottom bar tab: a nested [Navigator] with its own back stack.
///
/// [NavigatorPopHandler] routes the system back gesture into that nested
/// navigator while it still has something to pop.
class TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final WidgetBuilder rootBuilder;

  const TabNavigator({
    super.key,
    required this.navigatorKey,
    required this.rootBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler(
      onPopWithResult: (_) => navigatorKey.currentState?.pop(),
      child: Navigator(
        key: navigatorKey,
        onGenerateRoute: (settings) =>
            MaterialPageRoute(builder: rootBuilder, settings: settings),
      ),
    );
  }
}
