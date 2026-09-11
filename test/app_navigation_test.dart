import 'package:flutter_test/flutter_test.dart';
import 'package:routing_coordinator_flutter/main.dart';
import 'package:routing_coordinator_flutter/router/app_router.dart';

void main() {
  testWidgets('feed tab keeps the posts of an author in its own stack', (
    tester,
  ) async {
    await tester.pumpWidget(App(appRouter: AppRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Заметки к машине Бэббиджа'));
    await tester.pumpAndSettle();
    expect(find.text('Пост'), findsOneWidget);

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pumpAndSettle();
    expect(find.text('Профиль'), findsOneWidget);

    await tester.tap(find.textContaining('Посты пользователя'));
    await tester.pumpAndSettle();

    expect(find.text('Алгоритм как объект'), findsOneWidget);
  });

  testWidgets('the same request from contacts switches to the feed tab', (
    tester,
  ) async {
    await tester.pumpWidget(App(appRouter: AppRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Контакты'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grace Hopper'));
    await tester.pumpAndSettle();
    expect(find.text('Профиль'), findsOneWidget);

    await tester.tap(find.textContaining('Посты пользователя'));
    await tester.pumpAndSettle();

    // The list opened in the feed branch, so the contacts branch is offstage.
    expect(find.text('Первый баг'), findsOneWidget);
    expect(find.text('Профиль'), findsNothing);
  });
}
