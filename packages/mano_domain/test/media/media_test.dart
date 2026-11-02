import 'dart:typed_data';

import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('PickedImage', () {
    PickedImage image(String mime) =>
        PickedImage(bytes: Uint8List(3), mimeType: mime, name: 'a');

    test('only the image types the media service accepts are supported', () {
      expect(image('image/jpeg').isSupported, isTrue);
      expect(image('image/png').isSupported, isTrue);
      expect(image('image/webp').isSupported, isTrue);
      expect(image('image/heic').isSupported, isFalse);
      expect(image('video/mp4').isSupported, isFalse);
    });

    test('knows its size in bytes', () {
      expect(image('image/png').byteSize, 3);
    });
  });

  group('MediaAttachment', () {
    test('compares by value', () {
      const a = MediaAttachment(id: 'm1', url: 'https://x/1');
      const b = MediaAttachment(id: 'm1', url: 'https://x/1');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == const MediaAttachment(id: 'm2', url: 'https://x/1'), isFalse);
    });

    test('is an image unless its type says otherwise', () {
      expect(const MediaAttachment(id: 'm', url: 'u').isImage, isTrue);
      expect(
        const MediaAttachment(id: 'm', url: 'u', mimeType: 'image/png').isImage,
        isTrue,
      );
      expect(
        const MediaAttachment(id: 'm', url: 'u', mimeType: 'video/mp4').isImage,
        isFalse,
      );
    });
  });

  group('UploadTarget', () {
    test('targets compare by value so they can key state', () {
      expect(const ChatUpload('c1'), const ChatUpload('c1'));
      expect(const ChatUpload('c1') == const ChatUpload('c2'), isFalse);
      expect(const AvatarUpload(), const AvatarUpload());
      expect(const ProjectPhotoUpload(), const ProjectPhotoUpload());
      expect(const PortfolioUpload(), const PortfolioUpload());
      expect(const ChatUpload('c1').hashCode, const ChatUpload('c1').hashCode);
    });

    test('each target caps the bytes the media service will keep', () {
      expect(const AvatarUpload().maxBytes, 2 * 1024 * 1024);
      expect(const ChatUpload('c').maxBytes, 100 * 1024 * 1024);
      expect(const ProjectPhotoUpload().maxBytes, 10 * 1024 * 1024);
      expect(const PortfolioUpload().maxBytes, 10 * 1024 * 1024);
    });
  });
}
