# Flutter tips. Routing. Coordinator

*Черновик. Код: [routing_coordinator_flutter](https://github.com/), ветки `part-1-imperative`, `part-2-gorouter`, `part-3-autoroute`.*

## Введение

Я занимаюсь мобильной разработкой больше десяти лет: сначала iOS, потом Flutter. И всё это время сталкиваюсь с одной и той же проблемой — API навигации устроены так, что следование общепринятым гайдлайнам подталкивает к решениям, которые потом дорого обходятся.

В iOS удобнее всего начать со storyboard segues. Следующий экран создаёт storyboard, но настраивать его предлагается в `prepare(for:sender:)` — то есть в коде предыдущего экрана, который обязан знать тип следующего и уметь передать ему зависимости. Насколько это неудобно, Apple признала сама: в iOS 13 появился `IBSegueAction`, чтобы конфигурировать экран при создании, а не после.

Но дело не в segues. Откажитесь от storyboard совсем, и ничего не изменится: `pushViewController` принимает готовый контроллер, поэтому создавать и настраивать следующий экран всё равно приходится на предыдущем.

```swift
let vc = PostDetailsViewController()
vc.postId = post.id
navigationController?.pushViewController(vc, animated: true)
```

Дело в форме API: чтобы перейти, нужно держать в руках следующий экран — со всеми его зависимостями. Ранний SwiftUI повторил это буквально, `NavigationLink(destination: PostDetailsView(postId: post.id))` строит следующий экран прямо в месте нажатия. С приходом `NavigationStack` механика стала лучше: пункт назначения объявляется отдельно от ссылки — `NavigationLink(value:)` отправляет значение, `navigationDestination(for:)` решает, что показать, а путь стека можно держать вне вью и менять программно. Всё для разделения есть. Не изменилось другое: нигде не сказано, что решение о переходе — не дело экрана. Поэтому в iOS общепринятой практикой остаётся паттерн Координатор [1, 2] или его упрощённая версия [3]. (О том, каким Apple видит MVC и почему разработчики в шутку расшифровывают его как Massive View Controller, — как-нибудь в другой раз.)

В Android пришли к тому же с другой стороны: официальный гайд по Jetpack Compose прямо требует не передавать `navController` внутрь composable, а прокидывать колбэки — чтобы экраны оставались переиспользуемыми и тестируемыми [4].

Во Flutter ситуацию усложняет web: к переходам добавились пути — то, что видно в адресной строке. Штатный API (Navigator 2.0) получился громоздким, и напрямую его используют редко, в основном в простых случаях. Чаще берут сторонние пакеты — популярнее всего go_router и auto_route. Но с ними ничего не меняется, и вот что показательно: ни документация Flutter, ни гайдлайны самих пакетов нигде не отмечают, что задавать переход в коде виджета — архитектурная проблема. Наоборот, это подаётся как норма. В документации go_router штатный пример выглядит так:

```dart
TextButton(
  onPressed: () => context.go('/users/123'),
)
```

auto_route идёт дальше и специально добавляет расширения `context.router.push(...)` и `context.pushRoute(...)` — чтобы вызывать навигацию прямо из виджета было удобнее. А кое-где встречается и прямое создание следующего экрана в коде предыдущего.

Чем это чревато:

- **Сложность и нарушение SRP.** Экран отвечает уже не только за интерфейс и реакцию на действия пользователя, но и за навигацию — включая создание других экранов и раздачу им зависимостей. Две ответственности в одном месте, и экран перестаёт читаться с одного взгляда.

- **Плохое переиспользование.** Экран, который сам решает, куда идти дальше, трудно вставить в другой контекст, где переход должен быть другим.

- **Жёсткая связность.** Каждый экран знает про следующие. Архитектура становится хрупкой: правка в одном экране тянет за собой правки в других.

Цель этой статьи двойная.

Первая — показать приём (и его вариации), который по принципу «информационного эксперта» выносит переход из кода виджетов туда, где для решения есть вся информация, и тем самым снимает все три проблемы.

Вторая, не менее важная, — попробовать получить место в коде, которое более-менее наглядно описывает навигацию. 

## Что сделано

Статья состоит из трёх частей, в каждой из которых, абсолютно идентично, реализована наиболее типичная часть навигации в мобильном приложении: две вкладки со своими стеками и общий экран, который в каждой вкладке ведёт себя по-своему. В первой части — императивный подход, без использования каких-либо сторонних пакетов. Во второй и третьей — всё то же самое, но с использованием go_router и auto_route соответственно. В каждой части показан, по сути, один и тот же приём, только в части 1 и в частях 2, 3 он реализован немного по-разному. В части 1 навигация из кода экрана вынесена при помощи колбэков, а в частях 2 и 3 — при помощи абстрактных интерфейсов. Различная реализация обусловлена тем, что для части 1 использование колбэков, на мой взгляд, выглядит синтаксически нагляднее.


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

Это «информационный эксперт» (Information Expert) — один из принципов GRASP,
сформулированных Крэгом Ларманом: ответственность отдают тому, у кого есть
информация, необходимая для её исполнения. Информации о том, куда ведёт
нажатие — в какой вкладке мы находимся, какой стек под нами, показать экран
поверх или переключить раздел, — у экрана нет. Она есть у того, кто собрал
приложение из экранов. Значит, и решение за ним.

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

Ниже — три реализации этого приёма.

---

## Часть 1. Императивная навигация

### Контракт экрана

Рядом с экраном объявляется перечень запросов — то, что пользователь может
попросить, — и колбэк, через который запрос уходит наружу:

```dart
sealed class PostDetailsScreenRoute<T> {
  const PostDetailsScreenRoute();
}

final class OpenAuthorRoute extends PostDetailsScreenRoute<Never> {
  final String userId;

  const OpenAuthorRoute(this.userId);
}

/// Запрос с ответом: даёт выбранного пользователя или null.
final class PickUserRoute extends PostDetailsScreenRoute<User> {
  const PickUserRoute();
}

typedef OnPostDetailsScreenRoute =
    Future<T?> Function<T>(PostDetailsScreenRoute<T> route);
```

Параметр типа `T` — это тип ответа. `OpenAuthorRoute` ответа не даёт, поэтому
`Never`; `PickUserRoute` отвечает `User`. Один колбэк обслуживает всё семейство
запросов и остаётся типизированным.

Внутри экрана переход без ответа и запрос с ответом выглядят одинаково просто:

```dart
// Переход
onTap: () => widget.onRoute(OpenAuthorRoute(author.id)),

// Запрос с ответом — обычное ожидание значения
final user = await widget.onRoute(const PickUserRoute());
```

Экран не знает, каким будет следующий экран, как он откроется — страницей,
шторкой или диалогом — и каким образом вернётся ответ.

### Роутер вкладки — карта переходов

Это ключевой файл. Метод на экран, внутри метода — все переходы, к которым
экран ведёт. Файл читается сверху вниз как карта вкладки:

```dart
final class FeedTabRouter with TabRouter {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  const FeedTabRouter({required this.navigatorKey});

  @override
  Widget buildRoot(BuildContext context) => _postList();

  /// Точка входа для оболочки: запрос, который не смогла обслужить
  /// вкладка контактов.
  void openUserPosts(String userId) => push(_postList(authorId: userId));

  /// Один экран, два применения: корень вкладки и посты одного автора.
  Widget _postList({String? authorId}) => PostListScreen(
    authorId: authorId,
    onRoute: <T>(route) async {
      switch (route) {
        case OpenPostRoute(:final postId):
          push(_postDetails(postId));
          return null;
      }
    },
  );

  Widget _postDetails(String postId) => PostDetailsScreen(
    postId: postId,
    onRoute: <T>(route) async {
      switch (route) {
        case OpenAuthorRoute(:final userId):
          push(_userProfile(userId));
          return null;
        case PickUserRoute():
          return push<T>(_userPicker());
      }
    },
  );

  /// В ленте посты автора остаются в этом же стеке.
  /// Вкладка контактов отвечает на этот же запрос иначе.
  Widget _userProfile(String userId) => UserProfileScreen(
    userId: userId,
    onRoute: <T>(route) async {
      switch (route) {
        case OpenUserPostsRoute(:final userId):
          openUserPosts(userId);
          return null;
      }
    },
  );

  Widget _userPicker() => UserPickerScreen(
    onRoute: <T>(route) async {
      switch (route) {
        case UserPickedRoute(:final user):
          pop(user);
          return null;
      }
    },
  );
}
```

Чтобы узнать, куда ведёт любой экран вкладки, достаточно найти его метод:
список постов открывает пост, пост — профиль автора или экран выбора
пользователя, профиль — список постов автора. Вся навигация вкладки видна
целиком, без перехода по файлам экранов.

`switch` по sealed-классу исчерпывающий: при добавлении нового запроса
компилятор укажет все места, где он не обработан.

Базовые операции вынесены в миксин `TabRouter`:

```dart
mixin TabRouter {
  GlobalKey<NavigatorState> get navigatorKey;

  Widget buildRoot(BuildContext context);

  Future<T?> push<T>(Widget screen) async { ... }

  void pop<T>(T result) => navigatorKey.currentState?.pop(result);
}
```

Миксин, а не базовый класс: роутер вкладки не является частным случаем чего-то,
он лишь владеет навигатором, и слот суперкласса остаётся свободным.

### Тот же приём уровнем выше

Вкладка контактов не может открыть посты у себя — они принадлежат другой
вкладке. Она поступает так же, как экран: объявляет запрос и передаёт его выше.

```dart
sealed class ContactsTabRoute<T> {
  const ContactsTabRoute();
}

final class UserPostsRoute extends ContactsTabRoute<Never> {
  final String userId;

  const UserPostsRoute(this.userId);
}
```

Экран — эксперт по запросам своего пользователя, но не по приложению. Роутер
вкладки — эксперт по своему стеку, но тоже не по приложению. Последним в
цепочке стоит `AppRouter` — единственное место, которое знает обе вкладки:

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

Запрос поднимается ровно до того уровня, на котором для ответа достаточно
информации.

---

## Часть 2. go_router: координатор как интерфейс

Декларативный роутер меняет картину: есть дерево локаций, и переход — это
переход к локации. Приём тот же, меняется форма контракта.

### Контракт экрана

Вместо sealed-класса и колбэка — интерфейс, объявленный рядом с экраном:

```dart
abstract interface class PostListScreenCoordinator {
  void onPostRoute(BuildContext context, {required String postId});
}
```

Запрос с ответом — метод с типом возвращаемого значения, без обобщения по
всему семейству:

```dart
abstract interface class PostDetailsScreenCoordinator {
  void onAuthorRoute(BuildContext context, {required String userId});

  Future<User?> onPickUserRoute(BuildContext context);
}
```

### Роутер вкладки — карта переходов

Файл вкладки устроен в два яруса: сверху дерево локаций, снизу ответы на
запросы её экранов. Дерево читается как карта, реализации — как список
переходов, к которым эта карта ведёт.

```dart
GoRoute get feedTabRoute => GoRoute(
  path: AppRouterPath.feed,
  builder: (context, state) =>
      const PostListScreen(coordinator: FeedPostListCoordinatorImpl()),
  routes: [
    GoRoute(
      path: AppRouterPath.post,
      builder: (context, state) => PostDetailsScreen(
        postId: state.pathParameters[AppRouterParam.postId]!,
        coordinator: const FeedPostDetailsCoordinatorImpl(),
      ),
    ),
    GoRoute(
      path: AppRouterPath.user,
      builder: (context, state) => UserProfileScreen(
        userId: state.pathParameters[AppRouterParam.userId]!,
        coordinator: const FeedUserProfileCoordinatorImpl(),
      ),
    ),
    // Открывается, чтобы ответить на запрос, но остаётся обычной
    // локацией — на неё можно прийти и по диплинку.
    GoRoute(
      path: AppRouterPath.userPicker,
      builder: (context, state) =>
          const UserPickerScreen(coordinator: UserPickerCoordinatorImpl()),
    ),
    // Тот же экран, что и в корне вкладки, с фильтром по автору
    // и тем же координатором.
    GoRoute(
      path: AppRouterPath.userPosts,
      builder: (context, state) => PostListScreen(
        authorId: state.pathParameters[AppRouterParam.userId]!,
        coordinator: const FeedPostListCoordinatorImpl(),
      ),
    ),
  ],
);

final class FeedPostListCoordinatorImpl implements PostListScreenCoordinator {
  const FeedPostListCoordinatorImpl();

  @override
  void onPostRoute(BuildContext context, {required String postId}) =>
      GoRouter.of(context)
          .push(AppRouterPath.postIn(AppRouterPath.feed, postId));
}

final class FeedPostDetailsCoordinatorImpl
    implements PostDetailsScreenCoordinator {
  const FeedPostDetailsCoordinatorImpl();

  @override
  void onAuthorRoute(BuildContext context, {required String userId}) =>
      GoRouter.of(context)
          .push(AppRouterPath.userIn(AppRouterPath.feed, userId));

  /// `push` возвращает future того, чем локацию закрыли, поэтому запрос
  /// с ответом не требует ничего дополнительного.
  @override
  Future<User?> onPickUserRoute(BuildContext context) => GoRouter.of(context)
      .push<User>(AppRouterPath.userPickerIn(AppRouterPath.feed));
}

/// Закрытие экрана выбора — решение координатора, а не следствие выбора.
final class UserPickerCoordinatorImpl implements UserPickerScreenCoordinator {
  const UserPickerCoordinatorImpl();

  @override
  void onUserPickedRoute(BuildContext context, {required User user}) =>
      GoRouter.of(context).pop(user);
}
```

Дерево локаций и ответы на запросы лежат рядом, поэтому по одному файлу видно
и что вкладка показывает, и что происходит при каждом нажатии.

Сами вкладки объявлены в корневом файле:

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

### Одно требование, две реализации

Экран профиля один, интерфейс один:

```dart
abstract interface class UserProfileScreenCoordinator {
  void onUserPostsRoute(BuildContext context, {required String userId});
}
```

В файле вкладки Feed посты автора остаются в том же стеке — `push`:

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

В файле вкладки Contacts — `go`:

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

Локация принадлежит другой ветке, поэтому оболочка переключает вкладку сама, а
стек контактов остаётся на месте. Разница между двумя требованиями — одно слово
в одном классе; экран не изменился.

---

## Часть 3. auto_route: то же самое с кодогенерацией

Третья ветка отличается от второй только слоем роутинга: экраны и их контракты
в ней те же самые, до буквы.

Отличий два. Пункт назначения — не строка, а сгенерированный объект, поэтому
пропущенный или опечатанный аргумент становится ошибкой компиляции. И между
экраном и роутером появляется слой страниц: он удерживает аннотации генератора
вне экранов.

### Роутер вкладки — карта переходов

Файл вкладки устроен в три яруса: дерево локаций, страницы, ответы на запросы.

```dart
AutoRoute get feedTabRoute => AutoRoute(
  path: AppRouterPath.feed,
  page: feedTab,
  children: [
    AutoRoute(path: AppRouterPath.initial, page: FeedRoute.page),
    AutoRoute(path: AppRouterPath.post, page: FeedPostDetailsRoute.page),
    AutoRoute(path: AppRouterPath.user, page: FeedUserProfileRoute.page),
    AutoRoute(path: AppRouterPath.userPosts, page: FeedUserPostsRoute.page),
    AutoRoute(path: AppRouterPath.userPicker, page: FeedUserPickerRoute.page),
  ],
);

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

final class FeedUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const FeedUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      AutoRouter.of(context).push(FeedUserPostsRoute(userId: userId));
}
```

Верхний ярус — карта вкладки: пять локаций, каждая ссылается на
сгенерированный объект страницы. Средний — страницы: каждая связывает экран с
координатором, который ему полагается. Нижний — координаторы, отвечающие на
запросы экранов. Порядок чтения тот же, что в части 2, добавился только слой
страниц.

Запрос с ответом устроен так же, как в go_router, — `push` типизирован тем,
чем экран будет закрыт:

```dart
@override
Future<User?> onPickUserRoute(BuildContext context) =>
    AutoRouter.of(context).push<User>(const FeedUserPickerRoute());
```

### Переход в другую вкладку

Вложенный стековый роутер не может добавить экран в соседнюю вкладку. Поэтому
координатор вкладки Contacts навигирует корневой роутер по пути, а auto_route
активирует нужную вкладку сам:

```dart
final class ContactsUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const ContactsUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      AutoRouter.of(context)
          .root
          .navigatePath(AppRouterPath.feedUserPosts(userId));
}
```

Механика другая, требование то же, экран не изменился.

---

## Один тест на три ветки

Файл `test/app_navigation_test.dart` побайтово одинаков во всех трёх ветках:

```
for b in part-1-imperative part-2-gorouter part-3-autoroute; do
  git show "${b}:test/app_navigation_test.dart" | shasum
done
```

Внутри — сценарий от лица пользователя, проверяющий требование из таблицы выше:

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

Три слоя роутинга взаимозаменяемы снаружи: выбор между ними определяет форму
кода, а не поведение приложения.

## Экран тестируется без роутера

Экран зависит от контракта, а не от библиотеки навигации, поэтому проверяется
без роутера вообще:

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

  await tester.pumpWidget(
    MaterialApp(home: UserProfileScreen(userId: 'u1', coordinator: coordinator)),
  );

  await tester.tap(find.byType(FilledButton));

  expect(coordinator.requests, ['u1']);
});
```

Запрос с ответом подделывается так же: координатор-заглушка возвращает
пользователя, ничего не открывая.

## Как это разложено по файлам

Во всех трёх ветках роутинг лежит в одних и тех же трёх файлах:

```
lib/router/
  app_router.dart            дерево приложения; единственное место, знающее обе вкладки
  feed_tab_router.dart       карта вкладки Feed и ответы на запросы её экранов
  contacts_tab_router.dart   то же для Contacts
```

Меняется только содержимое файла вкладки:

| Ветка | Что внутри файла вкладки |
| --- | --- |
| `part-1-imperative` | Экраны вкладки и переходы, к которым ведёт каждый запрос |
| `part-2-gorouter` | Дерево локаций вкладки и координаторы её экранов |
| `part-3-autoroute` | Дерево локаций, страницы и те же координаторы |

Это и есть вторая цель из введения: чтобы понять навигацию вкладки, достаточно
открыть один файл.

## Что это даёт

- Экран переиспользуется в другом контексте без правок: меняется только
  переданная ему реализация.
- Навигация вкладки описана в одном месте и читается сверху вниз.
- Смена роутера не затрагивает экраны: между частями 2 и 3 они не изменились.
- Экран тестируется без навигации, навигация — одним сценарным тестом.

## Когда не нужно

Если экран один и переход из него один, отдельный контракт — лишний слой.
Приём окупается там, где экран используется более чем в одном контексте или
где переход зависит от того, откуда экран открыт.

## Итого

Экран сообщает, что попросил пользователь. Решение принимает тот, у кого есть
информация для этого решения. Форма контракта — колбэк или интерфейс — и
механика перехода зависят от выбранной библиотеки; приём от этого не меняется.

## Ссылки

1. [Khanlou, «The Coordinator» (2015)](https://khanlou.com/2015/01/the-coordinator/) — статья, с которой пошёл паттерн Координатор.

2. [Hudson, «How to use the coordinator pattern in iOS apps»](https://www.hackingwithswift.com/articles/71/how-to-use-the-coordinator-pattern-in-ios-apps) — подробный разбор Координатора на практике.

3. [Попков, «iOS Navigation: A Compact Router Approach»](https://medium.com/@alexey.yu.popkov/ios-navigation-a-compact-router-approach-46cffa04a6ef) — упрощённая версия приёма, с которой начался этот подход. Часть 1 ниже — его перенос на Flutter.

4. [Navigation with Compose](https://developer.android.com/develop/ui/compose/navigation) — официальный гайд Android: не передавать `navController` внутрь composable, а прокидывать колбэки.

Дополнительно:

- [Shevchuk, «Navigation done right: a case for hierarchical routing with Flutter» (2020)](https://medium.com/flutter-community/navigation-done-right-a-case-for-hierarchical-routing-with-flutter-ca0aac1275ad) — ближайший аналог во Flutter: решение о переходе поднимается от экрана к родителю.

- [flow_builder](https://github.com/felangel/flow_builder) — другая механика того же разделения: экран меняет состояние потока, стек перестраивается сам.

- [Code with Andrea, «Bottom Navigation Bar with Stateful Nested Routes»](https://codewithandrea.com/articles/flutter-bottom-navigation-bar-nested-routes-gorouter/) — механика `StatefulShellRoute`, на которой построена часть 2.