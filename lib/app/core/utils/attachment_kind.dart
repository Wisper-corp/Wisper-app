import 'package:flutter/material.dart';

/// What an attachment is, worked out from its file name.
///
/// The forum stores every attachment as a plain URL in one list — the server
/// keeps whatever mime type was uploaded, but the list itself says nothing
/// about what each entry holds. The extension is what we have, and it is what
/// both ends already agree on.
enum AttachmentKind { image, video, document }

const Set<String> _imageExtensions = {
  'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp',
};

const Set<String> _videoExtensions = {
  'mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm', '3gp',
};

/// Everything else is treated as a document, so an unknown type is still
/// offered rather than silently dropped.
AttachmentKind attachmentKindOf(String pathOrUrl) {
  final withoutQuery = pathOrUrl.split('?').first;
  final lastSegment = withoutQuery.split('/').last;
  final dot = lastSegment.lastIndexOf('.');
  if (dot == -1 || dot == lastSegment.length - 1) {
    return AttachmentKind.document;
  }
  final ext = lastSegment.substring(dot + 1).toLowerCase();

  if (_imageExtensions.contains(ext)) return AttachmentKind.image;
  if (_videoExtensions.contains(ext)) return AttachmentKind.video;
  return AttachmentKind.document;
}

/// The name to show for a document, without the timestamp the uploader adds.
///
/// Files land in S3 as "wisper/1787690867962-contract.pdf"; showing that whole
/// key would bury the part someone recognises.
String attachmentDisplayName(String pathOrUrl) {
  final withoutQuery = pathOrUrl.split('?').first;
  final lastSegment = Uri.decodeComponent(withoutQuery.split('/').last);
  final dash = lastSegment.indexOf('-');
  if (dash > 0) {
    final prefix = lastSegment.substring(0, dash);
    // Only strip it when it really is the upload timestamp.
    if (prefix.length >= 10 && int.tryParse(prefix) != null) {
      return lastSegment.substring(dash + 1);
    }
  }
  return lastSegment;
}

IconData attachmentIcon(AttachmentKind kind) {
  switch (kind) {
    case AttachmentKind.image:
      return Icons.image_outlined;
    case AttachmentKind.video:
      return Icons.play_circle_outline;
    case AttachmentKind.document:
      return Icons.insert_drive_file_outlined;
  }
}
