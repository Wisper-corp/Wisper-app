class ForumAuthor {
  final String? id;
  final String? name;
  final String? image;

  /// The professional title shown under the name on every card.
  final String? title;

  const ForumAuthor({this.id, this.name, this.image, this.title});

  factory ForumAuthor.fromJson(Map<String, dynamic>? json) => ForumAuthor(
        id: json?['id'],
        name: json?['name'],
        image: json?['image'],
        title: json?['title'],
      );
}

class ForumReplyAvatar {
  final String? id;
  final String? image;
  const ForumReplyAvatar({this.id, this.image});

  factory ForumReplyAvatar.fromJson(Map<String, dynamic> json) =>
      ForumReplyAvatar(id: json['id'], image: json['image']);
}

class ForumPostModel {
  final String id;
  final String text;
  final List<String> images;
  final DateTime? createdAt;
  final ForumAuthor author;
  final int replyCount;

  /// Kept mutable so a heart tap can settle without refetching the list.
  int reactionCount;
  bool hasReacted;

  /// Drives the blue highlight on your own posts.
  final bool isMine;
  final List<ForumReplyAvatar> replyAvatars;

  ForumPostModel({
    required this.id,
    required this.text,
    required this.images,
    required this.createdAt,
    required this.author,
    required this.replyCount,
    required this.reactionCount,
    required this.hasReacted,
    required this.isMine,
    required this.replyAvatars,
  });

  factory ForumPostModel.fromJson(Map<String, dynamic> json) => ForumPostModel(
        id: json['id'] ?? '',
        text: json['text'] ?? '',
        images: (json['images'] as List?)?.map((e) => '$e').toList() ?? const [],
        createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
        author: ForumAuthor.fromJson(json['author']),
        replyCount: json['replyCount'] ?? 0,
        reactionCount: json['reactionCount'] ?? 0,
        hasReacted: json['hasReacted'] ?? false,
        isMine: json['isMine'] ?? false,
        replyAvatars: (json['replyAvatars'] as List?)
                ?.map((e) => ForumReplyAvatar.fromJson(e))
                .toList() ??
            const [],
      );
}

class ForumReplyModel {
  final String id;
  final String text;
  final DateTime? createdAt;
  final ForumAuthor author;

  const ForumReplyModel({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.author,
  });

  factory ForumReplyModel.fromJson(Map<String, dynamic> json) =>
      ForumReplyModel(
        id: json['id'] ?? '',
        text: json['text'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
        author: ForumAuthor.fromJson(json['author']),
      );
}
