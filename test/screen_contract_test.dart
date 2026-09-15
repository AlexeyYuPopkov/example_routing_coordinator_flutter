import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routing_coordinator_flutter/domain/model/user.dart';
import 'package:routing_coordinator_flutter/screens/post_details_screen.dart';
import 'package:routing_coordinator_flutter/screens/user_profile_screen.dart';

/// A coordinator that only remembers what it was asked for.
final class _RecordingCoordinator implements UserProfileScreenCoordinator {
  final List<String> requests = <String>[];

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      requests.add(userId);
}

/// A coordinator that answers without going anywhere.
final class _StubPostDetailsCoordinator
    implements PostDetailsScreenCoordinator {
  final User picked;

  const _StubPostDetailsCoordinator(this.picked);

  @override
  void onAuthorRoute(BuildContext context, {required String userId}) {}

  @override
  Future<User?> onPickUserRoute(BuildContext context) async => picked;
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

  testWidgets(
    'post details takes the answer from whoever handled its request',
    (tester) async {
      const picked = User(id: 'u4', name: 'Barbara Liskov', bio: 'Abstraction');

      // Nothing is pushed and nothing is popped. The screen only needs someone
      // to answer, and the answer arrives as an ordinary return value.
      await tester.pumpWidget(
        const MaterialApp(
          home: PostDetailsScreen(
            postId: 'p2',
            coordinator: _StubPostDetailsCoordinator(picked),
          ),
        ),
      );

      await tester.tap(find.text('Share with...'));
      await tester.pumpAndSettle();

      expect(find.text('Shared with Barbara Liskov'), findsOneWidget);
    },
  );
}
