import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

/// A coordinator that only remembers what it was asked for.
final class _RecordingCoordinator implements UserProfileScreenCoordinator {
  final List<String> requests = <String>[];

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      requests.add(userId);
}

void main() {
  testWidgets('profile asks its coordinator and navigates nowhere itself', (
    tester,
  ) async {
    final coordinator = _RecordingCoordinator();

    // No router at all: the screen depends on an interface, not on go_router.
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(userId: 'u1', coordinator: coordinator),
      ),
    );

    await tester.tap(find.byType(FilledButton));

    expect(coordinator.requests, ['u1']);
  });
}
