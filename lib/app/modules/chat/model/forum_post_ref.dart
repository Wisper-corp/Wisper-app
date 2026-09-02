import 'package:wisper/app/core/utils/attachment_kind.dart';

/// The forum post a private reply is about.
///
/// Replying privately used to open a bare chat, so the recipient got a message
/// with no subject. The server sends this alongside the message — trimmed, and
/// flattened so the app does not care whether a person or a business wrote it.
class ForumPostRef {
  const ForumPostRef({
    required this.id,
    required this.groupId,
    required this.text,
    required this.authorName,
    this.authorImage,
    this.attachment,
    this.isTrimmed = false,
  });

  final String id;

  /// Needed to open the post, which lives inside its community.
  final String groupId;

  /// Already shortened by the server, so the card reads the same everywhere.
  final String text;
  final bool isTrimmed;

  final String authorName;
  final String? authorImage;

  /// The post's first attachment, which is not always a picture — a post with
  /// a video puts the clip here.
  final String? attachment;

  bool get hasVideo =>
      attachment != null && attachmentKindOf(attachment!) == AttachmentKind.video;

  /// Only worth showing as a thumbnail when it is actually an image.
  String? get thumbnail {
    final url = attachment;
    if (url == null || url.isEmpty) return null;
    return attachmentKindOf(url) == AttachmentKind.image ? url : null;
  }

  /// Null unless the message really is a private reply to a post.
  static ForumPostRef? fromJson(dynamic json) {
    if (json is! Map) return null;
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;

    final author = json['author'];
    final authorMap = author is Map ? author : const {};

    return ForumPostRef(
      id: id,
      groupId: json['groupId']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      isTrimmed: json['isTrimmed'] == true,
      authorName: authorMap['name']?.toString() ?? 'Someone',
      authorImage: authorMap['image']?.toString(),
      attachment: json['image']?.toString(),
    );
  }

  /// Kept on the message map the chat list is built from, so it survives the
  /// trip through the socket handler without a second model.
  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'text': text,
        'isTrimmed': isTrimmed,
        'image': attachment,
        'author': {'name': authorName, 'image': authorImage},
      };
}
