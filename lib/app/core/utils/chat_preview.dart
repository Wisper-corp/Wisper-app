import 'package:flutter/material.dart';
import 'package:wisper/app/core/utils/attachment_kind.dart';

/// What the inbox shows in place of a message that has no text.
///
/// Previously these were emoji baked into the string — "📷 Photo", "📄 File" —
/// which render differently on every device and cannot be styled. An icon and
/// a label keep the row consistent and let the label say what the file
/// actually is.
class ChatPreview {
  const ChatPreview({required this.label, this.icon});

  final String label;

  /// Null for an ordinary text message, which needs no icon.
  final IconData? icon;
}

/// Builds the preview for a chat's most recent message.
///
/// [fileType] is the server's own enum (IMAGE, VIDEO, DOC, AUDIO, OFFER);
/// [fileUrl] is used only to name a document, since "PDF" tells someone more
/// than "File" does.
ChatPreview chatPreview({
  String? fileType,
  String? fileUrl,
  String? text,
}) {
  switch (fileType) {
    case 'IMAGE':
      return const ChatPreview(label: 'Photo', icon: Icons.photo);
    case 'VIDEO':
      return const ChatPreview(label: 'Video', icon: Icons.videocam);
    case 'AUDIO':
      return const ChatPreview(label: 'Audio', icon: Icons.mic);
    case 'OFFER':
    case null:
    case '':
      return ChatPreview(label: text ?? '');
    default:
      // A document. Name it by its extension where there is one.
      return ChatPreview(
        label: _documentLabel(fileUrl),
        icon: Icons.description,
      );
  }
}

/// "PDF", "DOCX" — and "Document" when the name gives nothing away.
String _documentLabel(String? fileUrl) {
  if (fileUrl == null || fileUrl.isEmpty) return 'Document';

  final name = attachmentDisplayName(fileUrl);
  final dot = name.lastIndexOf('.');
  if (dot == -1 || dot == name.length - 1) return 'Document';

  final ext = name.substring(dot + 1).toUpperCase();
  // Anything longer is not an extension, it is the rest of a filename.
  return ext.length <= 5 ? ext : 'Document';
}
