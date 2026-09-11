/// A person in the demo data set.
final class User {
  final String id;
  final String name;
  final String bio;

  const User({required this.id, required this.name, required this.bio});

  String get initials => name.split(' ').map((part) => part[0]).join();
}
