# Flutter tips. Routing. Coordinator

*Черновик. Код: [routing_coordinator_flutter](https://github.com/), ветки `part-1-imperative`, `part-2-gorouter`, `part-3-autoroute`.*

## Экран, который слишком много знает

Типичный экран списка постов выглядит так:

```dart
PostTile(
  post: post,
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => PostDetailsScreen(postId: post.id)),
  ),
)
```

Пока экран один, всё хорошо. Проблемы начинаются, когда тот же экран нужен во
втором месте — в другой вкладке, в онбординге, в режиме выбора. Оказывается,
что экран знает:

- какой экран открывается следующим;
- как он открывается — push, показ модалки, замена стека;
- в каком навигаторе это происходит;
- а иногда ещё и что делать с результатом.

Ни одно из этих знаний не про то, что экран показывает. Это знания о
приложении целиком, и живут они внутри виджета, который по-хорошему должен
уметь только нарисовать список и сообщить, что по элементу тапнули.

Стоимость становится видна на конкретном требовании. Возьмём его сразу.

## Приложение-пример

Две вкладки, у каждой свой `Navigator` и свой стек:

```
Feed     : список постов -> пост -> профиль автора -> посты автора -> пост ...
                              `-> выбрать пользователя, который вернётся ответом
Contacts : люди          -> профиль -> посты этого человека
```

Экран профиля — один и тот же класс в обеих вкладках. И вот требование,
ради которого всё затевается:

| Откуда открыт профиль | Что делает кнопка «Posts by this user» |
| --- | --- |
| Feed | Кладёт список постов в стек той же вкладки |
| Contacts | Переключает на вкладку Feed и открывает список там |

Один экран, одна кнопка, один запрос пользователя — и два разных смысла,
зависящих от того, где этот экран оказался. Если экран навигирует сам, ему
придётся спросить, в какой он вкладке, и написать `if`. Это ровно тот код,
который потом никто не может найти.

## Идея

Экран — эксперт в том, **что попросил пользователь**. Он не эксперт в том,
**что за этим следует**.

Поэтому экран сообщает о запросе и на этом останавливается. Решение принимает
тот, кто знает устройство приложения. Назовём его координатором.

```dart
FilledButton.tonal(
  onPressed: () => coordinator.onUserPostsRoute(context, userId: userId),
  child: Text('Posts by this user ($postCount)'),
)
```

Экран профиля никогда не узнает, в какой он вкладке. Он получает снаружи
разные реализации одного интерфейса — и это весь секрет.

Дальше — три способа сделать это на практике. Приложение во всех трёх
одинаковое, тест тоже (буквально, побайтово), меняется только слой роутинга.

---

## Часть 1. Императивная навигация

### Запрос как sealed-класс

Рядом с экраном объявляется то, что его пользователь может попросить:

```dart
sealed class PostDetailsScreenRoute<T> {
  const PostDetailsScreenRoute();
}

final class OpenAuthorRoute extends PostDetailsScreenRoute<Never> {
  final String userId;

  const OpenAuthorRoute(this.userId);
}

/// Запрос, который отвечает: даёт выбранного [User] или null.
final class PickUserRoute extends PostDetailsScreenRoute<User> {
  const PickUserRoute();
}

typedef OnPostDetailsScreenRoute =
    Future<T?> Function<T>(PostDetailsScreenRoute<T> route);
```

Параметр типа у `PostDetailsScreenRoute<T>` — это то, чем запрос отвечает.
`OpenAuthorRoute` не отвечает ничем и потому `Never`, `PickUserRoute` отвечает
пользователем. Один колбэк обслуживает всё семейство и при этом остаётся
типизированным.

Экран только сообщает:

```dart
UserTile(
  user: author,
  onTap: () => widget.onRoute(OpenAuthorRoute(author.id)),
)
```

А запрос с ответом выглядит как обычное ожидание значения:

```dart
Future<void> _share() async {
  final user = await widget.onRoute(const PickUserRoute());
  if (user == null || !mounted) return;
  setState(() => _sharedWith = user);
}
```

Обратите внимание, чего здесь нет. Экран не знает, появится ли пикер страницей,
шторкой или диалогом. Не знает, как ответ доедет обратно. Он просто ждёт
значение.

### Роутер вкладки

Переходы вкладки собраны в одном месте. Один метод на экран, и в нём —
экран вместе со всем, к чему он может привести:

```dart
final class FeedTabRouter with TabRouter {
  @override
  Widget buildRoot(BuildContext context) => _postList();

  Widget _postDetails(String postId) => PostDetailsScreen(
    postId: postId,
    onRoute: <T>(route) async {
      switch (route) {
        case OpenAuthorRoute(:final userId):
          push(_userProfile(userId));
          return null;
        // Единственный запрос, который отвечает. Экран ждёт значение,
        // а этот код решает, откуда оно возьмётся.
        case PickUserRoute():
          return push<T>(_userPicker());
      }
    },
  );
}
```

Прочитали `push`-вызовы — прочитали дерево навигации. `switch` по sealed-классу
исчерпывающий: добавили новый запрос — компилятор покажет все места, где его
забыли обработать.

Сам `TabRouter` — миксин, а не базовый класс:

```dart
mixin TabRouter {
  GlobalKey<NavigatorState> get navigatorKey;

  Widget buildRoot(BuildContext context);

  Future<T?> push<T>(Widget screen) async { ... }

  void pop<T>(T result) => navigatorKey.currentState?.pop(result);
}
```

Роутер вкладки — не «разновидность» чего-то, он просто владеет навигатором.
Свободный слот суперкласса оставляет дверь открытой.

### Тот же приём этажом выше

Вкладка контактов не может открыть посты у себя — они принадлежат другой
вкладке. И она поступает ровно так же, как экран: сообщает наверх и
останавливается.

```dart
sealed class ContactsTabRoute<T> {
  const ContactsTabRoute();
}

final class UserPostsRoute extends ContactsTabRoute<Never> {
  final String userId;

  const UserPostsRoute(this.userId);
}
```

> Экран — эксперт по запросам своего пользователя, но не по приложению.
> Роутер вкладки — эксперт по своему стеку, но тоже не по приложению.

Последним в цепочке стоит `AppRouter` — единственное место, которое знает обе
вкладки:

```dart
Future<T?> _onContactsTabRoute<T>(ContactsTabRoute<T> route) async {
  switch (route) {
    case UserPostsRoute(:final userId):
      switchTo(AppTab.feed);
      feedTabRouter.openUserPosts(userId);
      return null;
  }
}
```

Это цепочка ответственности: запрос поднимается ровно до того уровня, у
которого хватает контекста на ответ.

---

## Часть 2. go_router: координатор как интерфейс

Декларативный роутер переворачивает картину: есть дерево локаций, и переход —
это переход к локации. Приём остаётся тем же, меняется форма.

Вместо sealed-класса и колбэка — интерфейс:

```dart
abstract interface class PostListScreenCoordinator {
  void onPostRoute(BuildContext context, {required String postId});
}
```

Объявлен рядом с экраном: экран — эксперт в том, что можно попросить.
Реализован рядом с деревом маршрутов: оно — эксперт в том, что этот запрос
значит.

Для запроса с ответом интерфейс оказывается проще колбэка — это просто метод
с типом возвращаемого значения, без дженерика на всё семейство:

```dart
abstract interface class PostDetailsScreenCoordinator {
  void onAuthorRoute(BuildContext context, {required String userId});

  Future<User?> onPickUserRoute(BuildContext context);
}
```

### Одно требование, две реализации

Вот то самое место, ради которого писалась статья. Один интерфейс:

```dart
abstract interface class UserProfileScreenCoordinator {
  void onUserPostsRoute(BuildContext context, {required String userId});
}
```

Реализация для ленты — посты автора принадлежат этому же стеку:

```dart
final class FeedUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const FeedUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      GoRouter.of(context)
          .push(AppRouterPath.userPostsIn(AppRouterPath.feed, userId));
}
```

Реализация для контактов — `go` вместо `push`:

```dart
final class ContactsUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const ContactsUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      GoRouter.of(context)
          .go(AppRouterPath.userPostsIn(AppRouterPath.feed, userId));
}
```

Локация принадлежит другой ветке, поэтому оболочка сама переключит вкладку, а
стек контактов останется, где был. Разница между двумя требованиями — одно
слово в одном классе. Экран не изменился вообще.

### Дерево

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
      RootScreen(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [feedTabRoute]),
    StatefulShellBranch(routes: [contactsTabRoute]),
  ],
)
```

Каждая ветка — со своим стеком. Экран выбора пользователя при этом остаётся
обычной локацией, и на него так же можно прийти по диплинку:

```dart
GoRoute(
  path: AppRouterPath.userPicker,
  builder: (context, state) =>
      const UserPickerScreen(coordinator: UserPickerCoordinatorImpl()),
)
```

### Ответ

`push` у go_router — это future того, чем локацию закрыли, поэтому запрос с
ответом не требует ничего особенного:

```dart
@override
Future<User?> onPickUserRoute(BuildContext context) => GoRouter.of(context)
    .push<User>(AppRouterPath.userPickerIn(AppRouterPath.feed));
```

А закрытие пикера — это решение, а не побочный эффект выбора, и принимается
оно снаружи экрана:

```dart
final class UserPickerCoordinatorImpl implements UserPickerScreenCoordinator {
  const UserPickerCoordinatorImpl();

  @override
  void onUserPickedRoute(BuildContext context, {required User user}) =>
      GoRouter.of(context).pop(user);
}
```

Экран пикера сообщает, кого выбрали. Что это заканчивает экран — вывод
координатора.

---

## Часть 3. auto_route: то же самое с кодогенерацией

Третья ветка отличается от второй только слоем роутинга — экраны и их
контракты в ней те же самые, до буквы.

Главное изменение: пункт назначения — не строка, а сгенерированный объект,
поэтому забытый или опечатанный аргумент становится ошибкой компиляции:

```dart
@override
void onUserPostsRoute(BuildContext context, {required String userId}) =>
    AutoRouter.of(context).push(FeedUserPostsRoute(userId: userId));
```

Чтобы аннотации генератора не протекли в экраны, между ними и роутером стоит
тонкий слой страниц. Каждая страница связывает экран с координатором, который
ему полагается:

```dart
@RoutePage()
class FeedUserProfilePage extends StatelessWidget {
  final String userId;

  const FeedUserProfilePage({
    super.key,
    @PathParam('userId') required this.userId,
  });

  @override
  Widget build(BuildContext context) => UserProfileScreen(
    userId: userId,
    coordinator: const FeedUserProfileCoordinatorImpl(),
  );
}
```

Переход в чужую вкладку здесь выглядит иначе, чем в go_router: вложенный
стековый роутер не может пушить в соседнюю вкладку, поэтому навигируем корневой
роутер по пути, и auto_route сам активирует нужную вкладку:

```dart
@override
void onUserPostsRoute(BuildContext context, {required String userId}) =>
    AutoRouter.of(context)
        .root
        .navigatePath(AppRouterPath.feedUserPosts(userId));
```

Механика другая, требование то же, экран по-прежнему не при делах.

---

## Один тест на три ветки

Файл `test/app_navigation_test.dart` побайтово одинаков во всех трёх ветках.
Проверяется это в одну строку:

```
for b in part-1-imperative part-2-gorouter part-3-autoroute; do
  git show "${b}:test/app_navigation_test.dart" | shasum
done
```

Внутри — обычный сценарий, написанный от лица пользователя:

```dart
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

  // Список открылся во вкладке Feed, стека контактов на экране больше нет.
  expect(find.text('The first bug'), findsOneWidget);
  expect(find.text('Profile'), findsNothing);
});
```

Вывод, ради которого этот тест существует: три слоя роутинга взаимозаменяемы
снаружи. Выбор между ними — про форму кода, а не про то, что приложение умеет.

## Экран тестируется без роутера вообще

Побочный, но приятный эффект. Раз экран зависит от интерфейса, а не от
библиотеки, его контракт проверяется без всякой навигации:

```dart
final class _RecordingCoordinator implements UserProfileScreenCoordinator {
  final List<String> requests = <String>[];

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      requests.add(userId);
}

testWidgets('profile asks its coordinator and navigates nowhere itself', (
  tester,
) async {
  final coordinator = _RecordingCoordinator();

  // Никакого роутера: экран зависит от интерфейса, а не от go_router.
  await tester.pumpWidget(
    MaterialApp(home: UserProfileScreen(userId: 'u1', coordinator: coordinator)),
  );

  await tester.tap(find.byType(FilledButton));

  expect(coordinator.requests, ['u1']);
});
```

Ответ на запрос тоже подделывается тривиально — координатор-заглушка просто
возвращает пользователя, ничего не открывая.

## Как это разложено по файлам

Во всех трёх ветках роутинг лежит в одних и тех же трёх файлах:

```
lib/router/
  app_router.dart            всё дерево, единственное место, знающее обе вкладки
  feed_tab_router.dart       всё, что вкладка Feed показывает и умеет
  contacts_tab_router.dart   то же для Contacts
```

Меняется только содержимое файла вкладки:

| Ветка | Что внутри файла вкладки |
| --- | --- |
| `part-1-imperative` | Экраны вкладки и переход, к которому ведёт каждый запрос |
| `part-2-gorouter` | Маршруты вкладки и координаторы, отвечающие её экранам |
| `part-3-autoroute` | Страницы и маршруты вкладки и те же координаторы |

## Что это даёт

- Экран переиспользуется в другом месте без единой правки — меняется только
  переданная реализация.
- Требование «отсюда ведёт туда, а оттуда — в другое место» описано в одном
  месте и читается сверху вниз.
- Смена роутера не трогает экраны: между частями 2 и 3 они не изменились
  вообще.
- Экран тестируется без навигации, а навигация — одним сценарным тестом.

## Когда не нужно

Если экран ровно один и переход ровно один, интерфейс на него — лишний слой.
Приём окупается там, где экран живёт больше чем в одном контексте, или где
переход зависит от того, откуда пришли. Если этого нет — не усложняйте.

## Итого

Экран сообщает, что попросил пользователь. Кто-то другой решает, что это
значит. Всё остальное — детали конкретной библиотеки: sealed-класс и колбэк,
интерфейс и `push`/`go`, типизированный route-объект и генератор.

Приложение при этом одно и то же — и тест это доказывает.
