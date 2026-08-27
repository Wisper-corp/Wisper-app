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

class ForumPollOption {
  final String id;
  final String text;
  int votes;
  int percent;

  ForumPollOption({
    required this.id,
    required this.text,
    required this.votes,
    required this.percent,
  });

  factory ForumPollOption.fromJson(Map<String, dynamic> json) =>
      ForumPollOption(
        id: json['id'] ?? '',
        text: json['text'] ?? '',
        votes: json['votes'] ?? 0,
        percent: json['percent'] ?? 0,
      );
}

class ForumPoll {
  final String id;
  int totalVotes;

  /// The option this viewer picked, or null before they vote. Percentages are
  /// only shown once a vote is cast, the way Telegram does it.
  String? myOptionId;
  List<ForumPollOption> options;

  ForumPoll({
    required this.id,
    required this.totalVotes,
    required this.myOptionId,
    required this.options,
  });

  bool get hasVoted => myOptionId != null;

  factory ForumPoll.fromJson(Map<String, dynamic> json) => ForumPoll(
        id: json['id'] ?? '',
        totalVotes: json['totalVotes'] ?? 0,
        myOptionId: json['myOptionId'],
        options: (json['options'] as List? ?? [])
            .map((e) => ForumPollOption.fromJson(e))
            .toList(),
      );
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

  /// Attached poll, or null for an ordinary post.
  ForumPoll? poll;

  /// Whether this viewer gets notified about new replies.
  bool isFollowing;

  /// Drives the blue highlight on your own posts.
  final bool isMine;

  /// Whether this viewer may remove the post — their own, or anyone's if they
  /// are an admin or moderator. Decided by the server so the rule lives in one
  /// place.
  final bool canDelete;
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
    this.poll,
    this.isFollowing = false,
    required this.isMine,
    required this.canDelete,
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
        poll: json['poll'] == null ? null : ForumPoll.fromJson(json['poll']),
        isFollowing: json['isFollowing'] ?? false,
        isMine: json['isMine'] ?? false,
        // Older builds of the API omit this; fall back to own-posts-only.
        canDelete: json['canDelete'] ?? json['isMine'] ?? false,
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

  /// Null for a reply to the post itself; set for a reply to another reply.
  final String? parentId;

  /// Mutable so a like settles without refetching the whole thread.
  int reactionCount;
  bool hasReacted;

  final bool isMine;

  /// How many replies this one has in total — the server sends only the first
  /// couple inline, so this is what "Show more replies" counts against.
  final int replyCount;

  /// The children sent inline with this reply.
  List<ForumReplyModel> replies;

  ForumReplyModel({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.author,
    this.parentId,
    this.reactionCount = 0,
    this.hasReacted = false,
    this.isMine = false,
    this.replyCount = 0,
    List<ForumReplyModel>? replies,
  }) : replies = replies ?? [];

  /// True when the server is holding back children behind "Show more replies".
  bool get hasHiddenReplies => replyCount > replies.length;

  factory ForumReplyModel.fromJson(Map<String, dynamic> json) =>
      ForumReplyModel(
        id: json['id'] ?? '',
        text: json['text'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
        author: ForumAuthor.fromJson(json['author']),
        parentId: json['parentId'],
        reactionCount: json['reactionCount'] ?? 0,
        hasReacted: json['hasReacted'] ?? false,
        isMine: json['isMine'] ?? false,
        replyCount: json['replyCount'] ?? 0,
        replies: (json['replies'] as List? ?? [])
            .map((e) => ForumReplyModel.fromJson(e))
            .toList(),
      );
}
