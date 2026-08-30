import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/utils/attachment_kind.dart';

/// The "+" in the forum composer opened the photo library directly, because a
/// photo was the only thing a post could carry. With video and documents
/// alongside it, every attachment arrives in one list of URLs and the kind has
/// to be worked out from the name.
void main() {
  group('telling the three kinds apart', () {
    test('images', () {
      for (final name in [
        'photo.jpg', 'PHOTO.JPG', 'a.jpeg', 'b.png', 'c.gif', 'd.webp',
        'e.heic', 'shot.BMP',
      ]) {
        expect(attachmentKindOf(name), AttachmentKind.image, reason: name);
      }
    });

    test('videos', () {
      for (final name in ['clip.mp4', 'a.MOV', 'b.m4v', 'c.webm', 'd.3gp']) {
        expect(attachmentKindOf(name), AttachmentKind.video, reason: name);
      }
    });

    test('everything else is a document, not dropped', () {
      for (final name in ['contract.pdf', 'a.docx', 'b.xlsx', 'c.zip', 'odd.xyz']) {
        expect(attachmentKindOf(name), AttachmentKind.document, reason: name);
      }
    });

    test('a name with no extension is still offered', () {
      expect(attachmentKindOf('README'), AttachmentKind.document);
      expect(attachmentKindOf('trailing.'), AttachmentKind.document);
    });

    test('a full S3 url, query string and all', () {
      const url =
          'https://junayed-noman.s3.eu-north-1.amazonaws.com/wisper/1787690867962-comp.jpg?X-Amz-Expires=900';
      expect(attachmentKindOf(url), AttachmentKind.image);
    });

    test('a dot in the folder name does not decide it', () {
      expect(
        attachmentKindOf('https://x.com/my.photos/clip.mp4'),
        AttachmentKind.video,
      );
    });
  });

  group('what a document is called', () {
    test('the upload timestamp is stripped', () {
      expect(
        attachmentDisplayName(
          'https://s3.amazonaws.com/wisper/1787690867962-contract.pdf',
        ),
        'contract.pdf',
      );
    });

    test('a real hyphen in the name survives', () {
      expect(
        attachmentDisplayName('https://s3.amazonaws.com/wisper/end-of-year.pdf'),
        'end-of-year.pdf',
      );
    });

    test('an encoded space comes back readable', () {
      expect(
        attachmentDisplayName('https://s3.amazonaws.com/wisper/my%20report.pdf'),
        'my report.pdf',
      );
    });
  });

  test('every kind has an icon', () {
    for (final kind in AttachmentKind.values) {
      expect(attachmentIcon(kind), isA<IconData>());
    }
  });
}
