import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routing_coordinator_flutter/domain/model/user.dart';
import 'package:routing_coordinator_flutter/screens/post_details_screen.dart';
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
        home: UserProfileScreen(
          userId: 'u1',
          onRoute: <T>(route) async {
            requests.add(route);
            return null;
          },
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));

    expect(requests, [isA<OpenUserPostsRoute>()]);
  });

  testWidgets(
    'post details takes the answer from whoever handled its request',
    (tester) async {
      const picked = User(id: 'u4', name: 'Barbara Liskov', bio: 'Abstraction');

      // Nothing is pushed and nothing is popped. The screen only needs someone
      // to answer, and the answer arrives as an ordinary return value.
      await tester.pumpWidget(
        MaterialApp(
          home: PostDetailsScreen(
            postId: 'p2',
            onRoute: <T>(route) async => switch (route) {
              PickUserRoute() => picked as T,
              OpenAuthorRoute() => null,
            },
          ),
        ),
      );

      await tester.tap(find.text('Share with...'));
      await tester.pumpAndSettle();

      expect(find.text('Shared with Barbara Liskov'), findsOneWidget);
    },
  );
}
