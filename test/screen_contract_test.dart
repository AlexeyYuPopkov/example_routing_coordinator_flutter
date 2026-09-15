import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

void main() {
  testWidgets('profile reports a request and navigates nowhere itself', (
    tester,
  ) async {
    final requests = <UserProfileScreenRoute>[];

    // No Navigator, no router, no app shell: the screen has no dependency on
    // any of them, which is the whole point of the callback.
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(userId: 'u1', onRoute: requests.add),
      ),
    );

    await tester.tap(find.byType(FilledButton));

    expect(requests, [isA<OpenUserPostsRoute>()]);
    expect((requests.single as OpenUserPostsRoute).userId, 'u1');
  });
}
