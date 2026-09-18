# Навигация во Flutter: выносим переходы из экранов

## Введение

Я занимаюсь мобильной разработкой больше десяти лет: сначала iOS, потом Flutter. И всё это время сталкиваюсь с одной и той же проблемой — API навигации устроены так, что следование общепринятым гайдлайнам подталкивает к архитектурно неправильным решениям.

Что касается iOS, в гайдлайнах Apple, независимо от конкретного способа навигации, конфигурация (а часто и инициализация) последующего экрана выполняется в коде предыдущего. Например, при использовании storyboard segues экран настраивается в `prepare(for:sender:)` исходного контроллера. При программной навигации `pushViewController` также принимает уже готовый экземпляр, созданный, как правило, в коде предыдущего экрана.

Ранний SwiftUI воспроизвёл ту же схему: `NavigationLink(destination:)` строит следующий экран непосредственно в месте нажатия. В iOS 16 появился `NavigationStack`, где пункт назначения объявляется отдельно от ссылки, а путь стека может храниться вне представления, — однако и здесь гайдлайны не указывают, что решение о переходе не относится к зоне ответственности экрана. Поэтому в iOS общепринятой практикой остаётся паттерн Координатор [[1]](#ref1), [[2]](#ref2) или его упрощённая версия [[3]](#ref3).

В Android пришли к тому же с другой стороны: официальный гайд по Jetpack Compose прямо требует не передавать `navController` внутрь composable, а прокидывать колбэки — чтобы экраны оставались переиспользуемыми и тестируемыми [[4]](#ref4).

Во Flutter ситуацию усложняет web: к переходам добавились пути — то, что видно в адресной строке. Штатный API (Navigator 2.0) получился громоздким, и напрямую его используют редко, в основном в простых случаях. Чаще берут сторонние пакеты — популярнее всего go_router и auto_route. Но при их использовании также ничего не меняется: ни документация Flutter, ни гайдлайны самих пакетов нигде не отмечают, что задавать переход в коде виджета — архитектурная проблема. Наоборот, это подаётся как норма. В документации go_router штатный пример выглядит так:

```dart
TextButton(
  onPressed: () => context.go('/users/123'),
)
```

auto_route идёт дальше и специально добавляет расширения `context.router.push(...)` и `context.pushRoute(...)` — чтобы вызывать навигацию прямо из виджета было удобнее. А кое-где встречается и прямое создание следующего экрана в коде предыдущего.

Это приводит к следующим проблемам:

- **Сложность и нарушение SRP.** Экран отвечает уже не только за интерфейс и реакцию на действия пользователя, но и за навигацию — включая создание других экранов и раздачу им зависимостей. Две ответственности в одном месте, и экран перестаёт читаться с одного взгляда.

- **Плохое переиспользование.** Экран, который сам решает, куда идти дальше, трудно вставить в другой контекст, где переход должен быть другим.

- **Жёсткая связность.** Каждый экран знает про следующие. Архитектура становится хрупкой: правка в одном экране тянет за собой правки в других.

- **Тестируемость.** Проверить, что экран корректно реагирует на действие пользователя, невозможно в отрыве от навигации: для запуска экрана требуется сконфигурированный роутер, а результатом нажатия оказывается не факт запроса, а фактически выполненный переход. Модульный тест экрана превращается в интеграционный.

## Решение

Проблема возникает вследствие того, что предыдущий экран владеет информацией о
последующем. Наиболее очевидное решение — **вынести реализацию перехода из кода
экрана**.

Сразу возникает вопрос: куда её вынести? Ответ даёт паттерн **«информационный
эксперт»** (*Information Expert*) — ответственность назначается тому, кто
обладает информацией, необходимой для её исполнения.

<details>
<summary>Подробнее о паттерне</summary>

«Информационный эксперт» — один из принципов GRASP (General Responsibility
Assignment Software Patterns), сформулированных Крэгом Ларманом в книге
«Applying UML and Patterns» (1997). Принцип отвечает на вопрос, какому объекту
назначить ответственность, и формулируется так: назначай ответственность
классу, который обладает информацией, необходимой для её выполнения.

</details></br>

Информации о том, куда ведёт нажатие — в какой вкладке находится экран, какой
стек под ним, открыть следующий экран поверх или переключить раздел, — у экрана
нет. Она есть там, где приложение собирается из экранов. Сам же экран пусть
включает абстрактный интерфейс такого перехода. Тогда типичный переход выглядит
следующим образом:

```dart
FilledButton.tonal(
  onPressed: () => coordinator.onUserPostsRoute(context, userId: userId),
  child: Text('Posts by this user ($postCount)'),
)
```

Реализацию этого интерфейса следует держать как можно ближе к месту, где
конфигурируются переходы. Иначе говоря — там, откуда так или иначе был вызван
конструктор текущего экрана.

Приём не нов: в iOS он известен как паттерн Координатор [[1]](#ref1),
[[2]](#ref2), во Flutter близкий по смыслу подход описан в [[6]](#ref6). Существенно другое — **внедрять его
целиком не требуется**. Переходы выносятся из экранов по одному экрану за раз,
без смены библиотеки навигации и без изменения остальной части приложения.
Поэтому подход применим не только к новому проекту, но и к существующему коду:
каждый обработанный экран сразу перестаёт зависеть от того, куда он ведёт, и
остальная навигация при этом продолжает работать как прежде.

Таким образом, цель этой статьи двойная.

Первая — показать приём (и его вариации), который по принципу «информационного эксперта» выносит переход из кода виджетов туда, где для решения есть вся информация.

Вторая, не менее важная, — попробовать получить место в коде, которое более-менее наглядно описывает навигацию. 

## Что сделано

Статья состоит из трёх частей, в каждой из которых, абсолютно идентично, реализована наиболее типичная часть навигации в мобильном приложении: две вкладки со своими стеками и общий экран, который в каждой вкладке ведёт себя по-своему. В первой части — императивный подход, без использования каких-либо сторонних пакетов. Во второй и третьей — всё то же самое, но с использованием go_router и auto_route соответственно. В каждой части показан, по сути, один и тот же приём, только в части 1 и в частях 2, 3 он реализован немного по-разному. В части 1 навигация из кода экрана вынесена при помощи колбэков, а в частях 2 и 3 — при помощи абстрактных интерфейсов. Различная реализация обусловлена тем, что для части 1 использование колбэков, на мой взгляд, выглядит синтаксически нагляднее.


## Приложение-пример

Код примера находится в репозитории [[5]](#ref5). Каждая реализация вынесена в отдельную
ветку: `part-1-imperative`, `part-2-gorouter`, `part-3-autoroute`. Ветка `main`
содержит общую часть — модели, репозиторий и презентационные виджеты — без
навигации. Приложение во всех ветках одинаковое, различается только слой
навигации.

Во всех трёх ветках навигация размещена в одних и тех же файлах:

```
lib/router/
  app_router.dart            дерево приложения; единственное место,
                             которому известны обе вкладки
  feed_tab_router.dart       переходы вкладки Feed и ответы на запросы
                             её экранов
  contacts_tab_router.dart   то же для вкладки Contacts
```

Приложение состоит из двух вкладок, у каждой свой `Navigator` и свой стек:

```
Full paths for routes:
  └─ (ShellRoute)
    ├─/feed (PostListScreen)
    │ ├─/feed/post/:postId (PostDetailsScreen)
    │ ├─/feed/user/:userId (UserProfileScreen)
    │ ├─/feed/pick_user (UserPickerScreen)
    │ └─/feed/user/:userId/posts (PostListScreen)
    └─/contacts (ContactsScreen)
      └─/contacts/user/:userId (UserProfileScreen)
```

Здесь приведено дерево маршрутов из ветки `part-2-gorouter`; пути относятся к
go_router, состав экранов во всех трёх ветках одинаков.

Требования к навигации:

- `UserProfileScreen` используется в обеих вкладках;
- `PostListScreen` используется дважды: как корень вкладки Feed и как список
  постов выбранного автора;
- `UserPickerScreen` открывается для получения результата — выбранного
  пользователя — и возвращает его экрану, инициировавшему запрос;
- поведение кнопки «Posts by this user» на экране профиля зависит от вкладки,
  из которой этот экран открыт:

| Вкладка | Результат нажатия |
| --- | --- |
| Feed | Список постов автора добавляется в стек текущей вкладки |
| Contacts | Приложение переключается на вкладку Feed и открывает список там |

Последнее требование и определяет устройство навигации: один и тот же экран
обрабатывает один и тот же запрос пользователя двумя разными способами в
зависимости от контекста, в котором он открыт.

---

## Часть 1. Императивная навигация

Реализация не использует сторонних пакетов: только `Navigator` и `GlobalKey`.
Интерфейс перехода здесь выражен не абстрактным интерфейсом, а колбэком — по
синтаксическим соображениям. Обработчик пишется непосредственно в том месте,
где собирается экран, поэтому переход и его назначение видны в одной точке, без
отдельного класса-реализации и перехода к его объявлению.

Ниже приведены четыре файла в том порядке, в каком их читает разработчик,
открывший проект.

### main.dart

```dart
void main() => runApp(App(appRouter: AppRouter()));

class App extends StatelessWidget {
  final AppRouter appRouter;

  const App({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      ...
      home: RootScreen(appRouter: appRouter),
    );
  }
}
```

`AppRouter` — обычный объект, создаётся до построения дерева виджетов и
передаётся в корневой экран.

### root_screen.dart

Корневой экран отвечает за один уровень навигации — переключение вкладок. Он не
знает, какие экраны находятся внутри вкладок: содержимое каждой строит
соответствующий роутер вкладки, переданный через `rootBuilder`.

<details>
<summary>Листинг root_screen.dart</summary>

```dart
class RootScreen extends StatelessWidget {
  final AppRouter appRouter;

  const RootScreen({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appRouter.currentTab,
      builder: (context, currentTab, child) => Scaffold(
        body: IndexedStack(
          index: currentTab.index,
          children: [
            TabNavigator(
              navigatorKey: appRouter.feedNavigatorKey,
              rootBuilder: appRouter.feedTabRouter.buildRoot,
            ),
            TabNavigator(
              navigatorKey: appRouter.contactsNavigatorKey,
              rootBuilder: appRouter.contactsTabRouter.buildRoot,
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentTab.index,
          onDestinationSelected: (index) =>
              appRouter.switchTo(AppTab.values[index]),
          destinations: const [...],
        ),
      ),
    );
  }
}
```

</details></br>

### app_router.dart

```dart
enum AppTab { feed, contacts }

final class AppRouter {
  final feedNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'feed');

  final contactsNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'contacts',
  );

  final currentTab = ValueNotifier(AppTab.feed);

  late final feedTabRouter = FeedTabRouter(navigatorKey: feedNavigatorKey);

  late final contactsTabRouter = ContactsTabRouter(
    navigatorKey: contactsNavigatorKey,
    onRoute: _onContactsTabRoute,
  );

  void switchTo(AppTab tab) => currentTab.value = tab;

  /// Последний обработчик цепочки: переход между вкладками требует знания
  /// обеих, поэтому обрабатывается здесь.
  Future<T?> _onContactsTabRoute<T>(ContactsTabRoute<T> route) async {
    switch (route) {
      case UserPostsRoute(:final userId):
        switchTo(AppTab.feed);
        feedTabRouter.openUserPosts(userId);
        return null;
    }
  }
}
```

Это единственное место, которому известны обе вкладки. Вкладка контактов не
может открыть посты автора у себя — они принадлежат другой вкладке, — поэтому
передаёт запрос сюда, а здесь выполняется переключение вкладки и открытие
списка в ленте.

### feed_tab_router.dart

```dart
final class FeedTabRouter with TabRouter {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  const FeedTabRouter({required this.navigatorKey});

  @override
  Widget buildRoot(BuildContext context) => _postList();

  /// Точка входа для запроса, пришедшего от вкладки контактов.
  void openUserPosts(String userId) => push(_postList(authorId: userId));

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

Файл содержит все переходы вкладки: метод на экран, внутри метода — все
направления, к которым этот экран ведёт. Список постов открывает пост, пост —
профиль автора или экран выбора пользователя, профиль — список постов автора.

### contacts_tab_router.dart

Вкладка контактов устроена так же, но один из запросов она обслужить не может:
посты автора принадлежат другой вкладке. Поэтому она объявляет собственный
перечень запросов и передаёт такой запрос выше — тому, кто знает обе вкладки.

```dart
sealed class ContactsTabRoute<T> {
  const ContactsTabRoute();
}

final class UserPostsRoute extends ContactsTabRoute<Never> {
  final String userId;

  const UserPostsRoute(this.userId);
}

typedef OnContactsTabRoute = Future<T?> Function<T>(ContactsTabRoute<T> route);

final class ContactsTabRouter with TabRouter {
  ...

  final OnContactsTabRoute onRoute;

  @override
  Widget buildRoot(BuildContext context) => _contacts();

  Widget _contacts() => ContactsScreen(...);

  /// Тот же экран и тот же запрос, что и во вкладке ленты, но ответ другой:
  /// там посты остаются в стеке, здесь запрос уходит выше.
  Widget _userProfile(String userId) => UserProfileScreen(
    userId: userId,
    onRoute: <T>(route) async {
      switch (route) {
        case OpenUserPostsRoute(:final userId):
          onRoute(UserPostsRoute(userId));
          return null;
      }
    },
  );
}
```

Экран профиля здесь тот же самый, что и в ленте, и запрос от него приходит тот
же. Различается только ответ, и находится он в файле вкладки — рядом с
остальными её переходами.

### Порядок чтения

Навигация читается сверху вниз по файлам, и на каждом уровне видно ровно тот
слой, за который этот уровень отвечает:

- `main.dart` — приложение и корневой экран;
- `root_screen.dart` — две вкладки и переключение между ними;
- `app_router.dart` — обе вкладки целиком и переходы между ними;
- `feed_tab_router.dart`, `contacts_tab_router.dart` — все экраны вкладки и
  переходы внутри неё.

То, что уровню неизвестно, он не обрабатывает, а делегирует выше: экран
сообщает о запросе роутеру вкладки, роутер вкладки — `AppRouter`, если запрос
выходит за пределы её стека. Чтобы понять навигацию вкладки, достаточно одного
файла; чтобы понять навигацию приложения — четырёх, читаемых подряд.

---

## Часть 2. go_router

Здесь есть дерево локаций, и переход — это переход к локации. Приём тот же,
меняется форма контракта: вместо колбэка экран принимает абстрактный интерфейс.
Колбэк здесь не даёт синтаксического выигрыша: обработчик всё равно не пишется
в месте объявления локации, поскольку построение экрана и реакция на нажатие
разнесены по разным местам дерева.

Порядок файлов тот же.

### main.dart

Отличается от части 1 одной строкой: вместо `home` передаётся `routerConfig`.

<details>
<summary>Листинг main.dart</summary>

```dart
void main() => runApp(App(appRouter: AppRouter()));

class App extends StatelessWidget {
  final AppRouter appRouter;

  const App({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      ...
      routerConfig: appRouter.router,
    );
  }
}
```

</details></br>

### root_screen.dart

```dart
class RootScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const RootScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [...],
      ),
    );
  }
}
```

Корневой экран отвечает за переключение вкладок и не знает, что внутри них.

### app_router.dart

```dart
final class AppRouter {
  late final GoRouter router = GoRouter(
    initialLocation: AppRouterPath.feed,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RootScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [feedTabRoute]),
          StatefulShellBranch(routes: [contactsTabRoute]),
        ],
      ),
    ],
  );
}
```

Две ветки, у каждой свой стек. Переход между вкладками отдельной обработки не
требует: локация принадлежит другой ветке, и оболочка переключает вкладку сама.

### feed_tab_router.dart

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
    GoRoute(
      path: AppRouterPath.userPicker,
      builder: (context, state) =>
          const UserPickerScreen(coordinator: UserPickerCoordinatorImpl()),
    ),
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
  ...

  @override
  Future<User?> onPickUserRoute(BuildContext context) => GoRouter.of(context)
      .push<User>(AppRouterPath.userPickerIn(AppRouterPath.feed));
}

/// В ленте посты автора остаются в том же стеке — `push`.
final class FeedUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const FeedUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      GoRouter.of(context)
          .push(AppRouterPath.userPostsIn(AppRouterPath.feed, userId));
}

...
```

Файл вкладки состоит из двух ярусов: сверху дерево локаций, снизу реализации
интерфейсов её экранов.

### contacts_tab_router.dart

Файл вкладки контактов устроен точно так же и целиком помещается на экран:

```dart
GoRoute get contactsTabRoute => GoRoute(
  path: AppRouterPath.contacts,
  builder: (context, state) =>
      const ContactsScreen(coordinator: ContactsCoordinatorImpl()),
  routes: [
    // Тот же экран профиля, что и в ленте, с другой реализацией.
    GoRoute(
      path: AppRouterPath.user,
      builder: (context, state) => UserProfileScreen(
        userId: state.pathParameters[AppRouterParam.userId]!,
        coordinator: const ContactsUserProfileCoordinatorImpl(),
      ),
    ),
  ],
);

final class ContactsCoordinatorImpl implements ContactsScreenCoordinator {
  const ContactsCoordinatorImpl();

  @override
  void onUserProfileRoute(BuildContext context, {required String userId}) =>
      GoRouter.of(context)
          .push(AppRouterPath.userIn(AppRouterPath.contacts, userId));
}

/// Тот же экран и тот же запрос, что и во вкладке ленты, но ответ другой.
/// `go` вместо `push`: локация принадлежит другой ветке, поэтому оболочка
/// переключает вкладку сама, а стек контактов остаётся на месте.
final class ContactsUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const ContactsUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      GoRouter.of(context)
          .go(AppRouterPath.userPostsIn(AppRouterPath.feed, userId));
}
```

Два файла вкладок устроены одинаково, экран профиля в них один и тот же, а всё
различие требований — одно слово в одной реализации: `push` в ленте, `go` в
контактах.

### Порядок чтения

Порядок чтения сохраняется, и на каждом уровне видно ровно свой слой:

- `main.dart` — приложение и конфигурация роутера;
- `root_screen.dart` — две вкладки и переключение между ними;
- `app_router.dart` — обе ветки дерева;
- `feed_tab_router.dart`, `contacts_tab_router.dart` — все локации вкладки и
  ответы на запросы её экранов.

Разница с частью 1 в том, что делегировать запрос вверх не требуется: переход в
чужую вкладку — это обычная локация, и различие между вкладками выражается
одним словом в одной реализации.

---

## Часть 3. auto_route

Экраны и их контракты полностью совпадают с частью 2. Отличия два: пункт
назначения — сгенерированный объект, а не строка, и между экраном и роутером
появляется слой страниц, который удерживает аннотации генератора вне экранов.

Порядок файлов тот же.

### main.dart

Отличается от части 2 тем, что конфигурация роутера берётся из сгенерированного
`config()`.

<details>
<summary>Листинг main.dart</summary>

```dart
void main() => runApp(App(appRouter: AppRouter()));

class App extends StatelessWidget {
  final AppRouter appRouter;

  const App({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      ...
      routerConfig: appRouter.config(),
    );
  }
}
```

</details></br>

### root_page.dart

Корневой экран строится из вкладок средствами `AutoTabsScaffold`.

<details>
<summary>Листинг root_page.dart</summary>

```dart
@RoutePage()
class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: [feedTab(), contactsTab()],
      bottomNavigationBuilder: (context, tabsRouter) => NavigationBar(
        selectedIndex: tabsRouter.activeIndex,
        onDestinationSelected: tabsRouter.setActiveIndex,
        destinations: const [...],
      ),
    );
  }
}
```

</details></br>

Сами вкладки — пустые вложенные роутеры, собственных виджетов им не требуется:

```dart
// app_tabs.dart
const feedTab = EmptyShellRoute('FeedTab');
const contactsTab = EmptyShellRoute('ContactsTab');
```

### app_router.dart

```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      path: AppRouterPath.root,
      page: RootRoute.page,
      initial: true,
      children: [feedTabRoute, contactsTabRoute],
    ),
  ];
}
```

### feed_tab_router.dart

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

...

final class FeedUserProfileCoordinatorImpl
    implements UserProfileScreenCoordinator {
  const FeedUserProfileCoordinatorImpl();

  @override
  void onUserPostsRoute(BuildContext context, {required String userId}) =>
      AutoRouter.of(context).push(FeedUserPostsRoute(userId: userId));
}

...
```

Ярусов здесь три: дерево локаций, страницы и реализации интерфейсов. Страница
связывает экран с той реализацией, которая ему полагается в этой вкладке.

Переход в другую вкладку требует отдельного решения: вложенный стековый роутер
не может добавить экран в соседнюю вкладку, поэтому навигируется корневой
роутер, а нужную вкладку auto_route активирует сам.

```dart
// contacts_tab_router.dart
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

### Порядок чтения

Порядок чтения не изменился:

- `main.dart` — приложение и конфигурация роутера;
- `root_page.dart` — две вкладки и переключение между ними;
- `app_router.dart` — дерево целиком;
- `feed_tab_router.dart` — локации вкладки, её страницы и ответы на запросы
  экранов.

Кодогенерация добавляет слой страниц, но не меняет ни порядок чтения, ни
распределение ответственности между уровнями.

---

## Применимость

Приём не привязан к конкретной библиотеке. Экран сообщает о запросе
пользователя; решение принимает тот, у кого есть необходимая для этого
информация. Форма контракта — колбэк или абстрактный интерфейс — и механика
перехода определяются выбранным инструментом, но распределение ответственности
остаётся прежним. В статье показаны три реализации — на штатном `Navigator`, на
go_router и на auto_route, — и тем же образом приём применяется к любому
другому пакету или к Router API напрямую.

Отсюда следует практическое свойство: подход пригоден для постепенного
рефакторинга. Переходы выносятся из экранов по одному экрану за раз, без смены
библиотеки навигации и без изменения остальной части приложения. Каждый такой
шаг самодостаточен — экран перестаёт зависеть от того, куда он ведёт, и
становится пригоден для повторного использования в другом контексте. Побочный
результат: такой экран проверяется без роутера, поскольку вместо реализации
перехода ему передаётся заглушка.

Обратная задача — выбрать библиотеку навигации — при этом остаётся отдельной и
на структуру экранов не влияет.

## Ссылки

1.<a id="ref1"></a> [Khanlou, «The Coordinator» (2015)](https://khanlou.com/2015/01/the-coordinator/) — статья, с которой пошёл паттерн Координатор.

2.<a id="ref2"></a> [Hudson, «How to use the coordinator pattern in iOS apps»](https://www.hackingwithswift.com/articles/71/how-to-use-the-coordinator-pattern-in-ios-apps) — подробный разбор Координатора на практике.

3.<a id="ref3"></a> [Попков, «iOS Navigation: A Compact Router Approach»](https://medium.com/@alexey.yu.popkov/ios-navigation-a-compact-router-approach-46cffa04a6ef) — упрощённая версия приёма для iOS. [Часть 1](#часть-1-императивная-навигация) — её перенос на Flutter.

4.<a id="ref4"></a> [Navigation with Compose](https://developer.android.com/develop/ui/compose/navigation) — официальный гайд Android: не передавать `navController` внутрь composable, а прокидывать колбэки.

5.<a id="ref5"></a> [example_routing_coordinator_flutter](https://github.com/AlexeyYuPopkov/example_routing_coordinator_flutter) — репозиторий с кодом всех трёх реализаций.

6.<a id="ref6"></a> [Shevchuk, «Navigation done right: a case for hierarchical routing with Flutter» (2020)](https://medium.com/flutter-community/navigation-done-right-a-case-for-hierarchical-routing-with-flutter-ca0aac1275ad) — близкий по смыслу подход во Flutter: решение о переходе поднимается от экрана к родителю.