import 'package:flutter_test/flutter_test.dart';
import 'package:routing_coordinator_flutter/main.dart';

void main() {
  testWidgets('feed tab keeps the posts of an author in its own stack', (
    tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.text('Notes on the Analytical Engine'));
    await tester.pumpAndSettle();
    expect(find.text('Post'), findsOneWidget);

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.textContaining('Posts by this user'));
    await tester.pumpAndSettle();

    expect(find.text('Ada Lovelace'), findsWidgets);
    expect(find.text('An algorithm is an object'), findsOneWidget);
  });

  testWidgets('the same request from contacts switches to the feed tab', (
    tester,
  ) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grace Hopper'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.textContaining('Posts by this user'));
    await tester.pumpAndSettle();

    // The list opened in the feed tab, so the contacts tab is no longer shown.
    expect(find.text('The first bug'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
  });
}
