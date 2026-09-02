import 'package:wisper/app/core/utils/chat_preview.dart';

/// The message a reply quotes.
///
/// Sent alongside the reply so the bar above it can be drawn without going
/// looking for a message that may not even be loaded yet.
class QuotedMessage {
  const QuotedMessage({
    required this.id,
    required this.senderName,
    required this.text,
    this.fileType,
    this.file,
    this.senderId,
  });

  final String id;
  final String senderName;
  final String text;
  final String? fileType;
  final String? file;
  final String? senderId;

  /// What to show when the quoted message is a file rather than words —
  /// "Photo", "Video", "PDF" — using the same wording as the chat list.
  String get label {
    if (text.isNotEmpty) return text;
    final kind = fileType;
    if (kind == null || kind.isEmpty) return 'Message';
    return chatPreview(fileType: kind, fileUrl: file, text: '').label;
  }

  static QuotedMessage? fromJson(dynamic json) {
    if (json is! Map) return null;
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return QuotedMessage(
      id: id,
      senderName: json['senderName']?.toString() ?? 'Someone',
      senderId: json['senderId']?.toString(),
      text: json['text']?.toString() ?? '',
      fileType: json['fileType']?.toString(),
      file: json['file']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderName': senderName,
        'senderId': senderId,
        'text': text,
        'fileType': fileType,
        'file': file,
      };
}
