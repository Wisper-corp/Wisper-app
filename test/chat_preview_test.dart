import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wisper/app/core/utils/chat_preview.dart';

/// The inbox showed emoji baked into the string — "📷 Photo", "📄 File" —
/// which render differently on every device, cannot be styled, and told
/// nobody what the file actually was.
void main() {
  group('what the inbox shows', () {
    test('a photo and a clip get their own icons', () {
      final photo = chatPreview(fileType: 'IMAGE');
      expect(photo.label, 'Photo');
      expect(photo.icon, Icons.photo);

      final video = chatPreview(fileType: 'VIDEO');
      expect(video.label, 'Video');
      expect(video.icon, Icons.videocam);
    });

    test('a document is named by its type, not called "File"', () {
      final pdf = chatPreview(
        fileType: 'DOC',
        fileUrl: 'https://s3.amazonaws.com/wisper/1788115947829-contract.pdf',
      );
      expect(pdf.label, 'PDF');
      expect(pdf.icon, Icons.description);

      expect(
        chatPreview(fileType: 'DOC', fileUrl: 'wisper/report.docx').label,
        'DOCX',
      );
    });

    test('a document with nothing to go on still reads sensibly', () {
      expect(chatPreview(fileType: 'DOC').label, 'Document');
      expect(chatPreview(fileType: 'DOC', fileUrl: 'wisper/README').label,
          'Document');
      // A long tail after a dot is a filename, not an extension.
      expect(
        chatPreview(fileType: 'DOC', fileUrl: 'a/b.somethinglong').label,
        'Document',
      );
    });

    test('plain text is itself, with no icon', () {
      final text = chatPreview(text: 'hello there');
      expect(text.label, 'hello there');
      expect(text.icon, isNull);
    });

    test('an offer keeps its own text rather than becoming a file', () {
      // Offers are rendered specially in the row; they are not attachments.
      final offer = chatPreview(fileType: 'OFFER', text: '🧾 Offer sent');
      expect(offer.label, '🧾 Offer sent');
      expect(offer.icon, isNull);
    });

    test('audio is named too', () {
      expect(chatPreview(fileType: 'AUDIO').icon, Icons.mic);
    });

    test('no emoji are left in a preview', () {
      for (final p in [
        chatPreview(fileType: 'IMAGE'),
        chatPreview(fileType: 'VIDEO'),
        chatPreview(fileType: 'DOC', fileUrl: 'a/b.pdf'),
      ]) {
        expect(p.label, isNot(contains('📷')));
        expect(p.label, isNot(contains('🎥')));
        expect(p.label, isNot(contains('📄')));
      }
    });
  });
}
