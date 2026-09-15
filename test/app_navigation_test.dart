import 'package:flutter_test/flutter_test.dart';
import 'package:routing_coordinator_flutter/main.dart';
import 'package:routing_coordinator_flutter/router/app_router.dart';

/// This file is byte for byte the same on every part branch.
///
/// The three routing layers are interchangeable from the outside: the app
/// behaves identically, whichever one is wired in.
void main() {
  testWidgets('feed tab keeps the posts of an author in its own stack', (
    tester,
  ) async {
    await tester.pumpWidget(App(appRouter: AppRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notes on the Analytical Engine'));
    await tester.pumpAndSettle();
    expect(find.text('Post'), findsOneWidget);

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.textContaining('Posts by this user'));
    await tester.pumpAndSettle();

    expect(find.text('An algorithm is an object'), findsOneWidget);
  });

  testWidgets('the same request from contacts switches to the feed tab', (
    tester,
  ) async {
    await tester.pumpWidget(App(appRouter: AppRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grace Hopper'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.textContaining('Posts by this user'));
    await tester.pumpAndSettle();

    // The list opened in the feed tab, so the contacts stack is gone from view.
    expect(find.text('The first bug'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
  });

  testWidgets('the picker hands its answer back to the screen that asked', (
    tester,
  ) async {
    await tester.pumpWidget(App(appRouter: AppRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('The first bug'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share with...'));
    await tester.pumpAndSettle();
    expect(find.text('Pick a user'), findsOneWidget);

    await tester.tap(find.text('Barbara Liskov'));
    await tester.pumpAndSettle();

    expect(find.text('Shared with Barbara Liskov'), findsOneWidget);
  });
}
