// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [ContactsPage]
class ContactsRoute extends PageRouteInfo<void> {
  const ContactsRoute({List<PageRouteInfo>? children})
    : super(ContactsRoute.name, initialChildren: children);

  static const String name = 'ContactsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ContactsPage();
    },
  );
}

/// generated route for
/// [ContactsUserProfilePage]
class ContactsUserProfileRoute
    extends PageRouteInfo<ContactsUserProfileRouteArgs> {
  ContactsUserProfileRoute({
    Key? key,
    required String userId,
    List<PageRouteInfo>? children,
  }) : super(
         ContactsUserProfileRoute.name,
         args: ContactsUserProfileRouteArgs(key: key, userId: userId),
         rawPathParams: {'userId': userId},
         initialChildren: children,
       );

  static const String name = 'ContactsUserProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ContactsUserProfileRouteArgs>(
        orElse: () => ContactsUserProfileRouteArgs(
          userId: pathParams.getString('userId'),
        ),
      );
      return ContactsUserProfilePage(key: args.key, userId: args.userId);
    },
  );
}

class ContactsUserProfileRouteArgs {
  const ContactsUserProfileRouteArgs({this.key, required this.userId});

  final Key? key;

  final String userId;

  @override
  String toString() {
    return 'ContactsUserProfileRouteArgs{key: $key, userId: $userId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ContactsUserProfileRouteArgs) return false;
    return key == other.key && userId == other.userId;
  }

  @override
  int get hashCode => key.hashCode ^ userId.hashCode;
}

/// generated route for
/// [FeedPage]
class FeedRoute extends PageRouteInfo<void> {
  const FeedRoute({List<PageRouteInfo>? children})
    : super(FeedRoute.name, initialChildren: children);

  static const String name = 'FeedRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FeedPage();
    },
  );
}

/// generated route for
/// [FeedPostDetailsPage]
class FeedPostDetailsRoute extends PageRouteInfo<FeedPostDetailsRouteArgs> {
  FeedPostDetailsRoute({
    Key? key,
    required String postId,
    List<PageRouteInfo>? children,
  }) : super(
         FeedPostDetailsRoute.name,
         args: FeedPostDetailsRouteArgs(key: key, postId: postId),
         rawPathParams: {'postId': postId},
         initialChildren: children,
       );

  static const String name = 'FeedPostDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<FeedPostDetailsRouteArgs>(
        orElse: () =>
            FeedPostDetailsRouteArgs(postId: pathParams.getString('postId')),
      );
      return FeedPostDetailsPage(key: args.key, postId: args.postId);
    },
  );
}

class FeedPostDetailsRouteArgs {
  const FeedPostDetailsRouteArgs({this.key, required this.postId});

  final Key? key;

  final String postId;

  @override
  String toString() {
    return 'FeedPostDetailsRouteArgs{key: $key, postId: $postId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FeedPostDetailsRouteArgs) return false;
    return key == other.key && postId == other.postId;
  }

  @override
  int get hashCode => key.hashCode ^ postId.hashCode;
}

/// generated route for
/// [FeedUserPickerPage]
class FeedUserPickerRoute extends PageRouteInfo<void> {
  const FeedUserPickerRoute({List<PageRouteInfo>? children})
    : super(FeedUserPickerRoute.name, initialChildren: children);

  static const String name = 'FeedUserPickerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const FeedUserPickerPage();
    },
  );
}

/// generated route for
/// [FeedUserPostsPage]
class FeedUserPostsRoute extends PageRouteInfo<FeedUserPostsRouteArgs> {
  FeedUserPostsRoute({
    Key? key,
    required String userId,
    List<PageRouteInfo>? children,
  }) : super(
         FeedUserPostsRoute.name,
         args: FeedUserPostsRouteArgs(key: key, userId: userId),
         rawPathParams: {'userId': userId},
         initialChildren: children,
       );

  static const String name = 'FeedUserPostsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<FeedUserPostsRouteArgs>(
        orElse: () =>
            FeedUserPostsRouteArgs(userId: pathParams.getString('userId')),
      );
      return FeedUserPostsPage(key: args.key, userId: args.userId);
    },
  );
}

class FeedUserPostsRouteArgs {
  const FeedUserPostsRouteArgs({this.key, required this.userId});

  final Key? key;

  final String userId;

  @override
  String toString() {
    return 'FeedUserPostsRouteArgs{key: $key, userId: $userId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FeedUserPostsRouteArgs) return false;
    return key == other.key && userId == other.userId;
  }

  @override
  int get hashCode => key.hashCode ^ userId.hashCode;
}

/// generated route for
/// [FeedUserProfilePage]
class FeedUserProfileRoute extends PageRouteInfo<FeedUserProfileRouteArgs> {
  FeedUserProfileRoute({
    Key? key,
    required String userId,
    List<PageRouteInfo>? children,
  }) : super(
         FeedUserProfileRoute.name,
         args: FeedUserProfileRouteArgs(key: key, userId: userId),
         rawPathParams: {'userId': userId},
         initialChildren: children,
       );

  static const String name = 'FeedUserProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<FeedUserProfileRouteArgs>(
        orElse: () =>
            FeedUserProfileRouteArgs(userId: pathParams.getString('userId')),
      );
      return FeedUserProfilePage(key: args.key, userId: args.userId);
    },
  );
}

class FeedUserProfileRouteArgs {
  const FeedUserProfileRouteArgs({this.key, required this.userId});

  final Key? key;

  final String userId;

  @override
  String toString() {
    return 'FeedUserProfileRouteArgs{key: $key, userId: $userId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FeedUserProfileRouteArgs) return false;
    return key == other.key && userId == other.userId;
  }

  @override
  int get hashCode => key.hashCode ^ userId.hashCode;
}

/// generated route for
/// [RootPage]
class RootRoute extends PageRouteInfo<void> {
  const RootRoute({List<PageRouteInfo>? children})
    : super(RootRoute.name, initialChildren: children);

  static const String name = 'RootRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RootPage();
    },
  );
}
