import 'package:routing_coordinator_flutter/domain/model/post.dart';
import 'package:routing_coordinator_flutter/domain/model/user.dart';

/// In-memory data source.
///
/// Deliberately synchronous and dependency free: the point of this project is
/// navigation, so nothing here should pull attention towards loading states.
final class AppRepository {
  const AppRepository();

  static const AppRepository instance = AppRepository();

  List<User> get users => _users;

  List<Post> get posts => _posts;

  User userById(String id) => _users.firstWhere((user) => user.id == id);

  Post postById(String id) => _posts.firstWhere((post) => post.id == id);

  List<Post> postsByAuthor(String userId) =>
      _posts.where((post) => post.authorId == userId).toList();
}

const _users = <User>[
  User(id: 'u1', name: 'Ada Lovelace', bio: 'Пишет про аналитические машины'),
  User(id: 'u2', name: 'Grace Hopper', bio: 'Компиляторы и настоящие баги'),
  User(id: 'u3', name: 'Alan Turing', bio: 'Разрешимость и машины'),
  User(id: 'u4', name: 'Barbara Liskov', bio: 'Абстракции и подстановка'),
];

const _posts = <Post>[
  Post(
    id: 'p1',
    authorId: 'u1',
    title: 'Заметки к машине Бэббиджа',
    body: 'Машина может обрабатывать не только числа, но и символы.',
  ),
  Post(
    id: 'p2',
    authorId: 'u2',
    title: 'Первый баг',
    body: 'Мотылёк в реле. С тех пор отладка называется именно так.',
  ),
  Post(
    id: 'p3',
    authorId: 'u3',
    title: 'Об уровне абстракции',
    body: 'Машина не обязана знать, зачем её запустили.',
  ),
  Post(
    id: 'p4',
    authorId: 'u1',
    title: 'Алгоритм как объект',
    body: 'Последовательность операций стоит описывать отдельно от машины.',
  ),
  Post(
    id: 'p5',
    authorId: 'u4',
    title: 'Принцип подстановки',
    body: 'Наследник обязан работать там, где ожидали предка.',
  ),
  Post(
    id: 'p6',
    authorId: 'u2',
    title: 'Про читаемость',
    body: 'Код читают чаще, чем пишут. Имена важнее, чем кажется.',
  ),
];
