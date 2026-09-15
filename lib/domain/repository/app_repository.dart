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
  User(id: 'u1', name: 'Ada Lovelace', bio: 'Writes about analytical engines'),
  User(id: 'u2', name: 'Grace Hopper', bio: 'Compilers, and one very real bug'),
  User(id: 'u3', name: 'Alan Turing', bio: 'Decidability and machines'),
  User(id: 'u4', name: 'Barbara Liskov', bio: 'Abstraction and substitution'),
];

const _posts = <Post>[
  Post(
    id: 'p1',
    authorId: 'u1',
    title: 'Notes on the Analytical Engine',
    body: 'The engine can operate on symbols just as well as on numbers.',
  ),
  Post(
    id: 'p2',
    authorId: 'u2',
    title: 'The first bug',
    body: 'A moth in a relay. Debugging has been called that ever since.',
  ),
  Post(
    id: 'p3',
    authorId: 'u3',
    title: 'On levels of abstraction',
    body: 'A machine need not know why it was started.',
  ),
  Post(
    id: 'p4',
    authorId: 'u1',
    title: 'An algorithm is an object',
    body: 'A sequence of operations deserves a description of its own.',
  ),
  Post(
    id: 'p5',
    authorId: 'u4',
    title: 'The substitution principle',
    body: 'A subtype must work wherever its supertype was expected.',
  ),
  Post(
    id: 'p6',
    authorId: 'u2',
    title: 'On readability',
    body:
        'Code is read more often than it is written. Names matter more than they seem to.',
  ),
];
