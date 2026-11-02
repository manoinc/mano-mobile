import 'dart:typed_data';

import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

PickedImage _image({String mime = 'image/jpeg', int size = 10}) =>
    PickedImage(bytes: Uint8List(size), mimeType: mime, name: 'foto.jpg');

void main() {
  group('MockMediaUploader', () {
    test('stores the photo in the library and returns it', () async {
      final library = MockMediaLibrary();
      final uploader = MockMediaUploader(
        library: library,
        delay: Duration.zero,
      );

      final result = await uploader.upload(
        _image(),
        const ChatUpload('conv-1'),
      );

      final attachment = result.valueOrNull!;
      expect(attachment.mimeType, 'image/jpeg');
      expect(attachment.byteSize, 10);
      expect(attachment.url, startsWith('https://'));
      expect(library[attachment.id], attachment);
    });

    test('ids are unique', () async {
      final uploader = MockMediaUploader(delay: Duration.zero);
      final a = (await uploader.upload(
        _image(),
        const AvatarUpload(),
      )).valueOrNull!;
      final b = (await uploader.upload(
        _image(),
        const AvatarUpload(),
      )).valueOrNull!;
      expect(a.id == b.id, isFalse);
    });

    test('refuses a type the media service would refuse', () async {
      final uploader = MockMediaUploader(delay: Duration.zero);
      final result = await uploader.upload(
        _image(mime: 'image/heic'),
        const ChatUpload('c'),
      );
      expect(result.failureOrNull, isA<DataRejected>());
    });

    test('refuses a file over the target cap', () async {
      final uploader = MockMediaUploader(delay: Duration.zero);
      final result = await uploader.upload(
        _image(size: 2 * 1024 * 1024 + 1),
        const AvatarUpload(),
      );
      expect(result.failureOrNull, isA<DataRejected>());
    });
  });

  group('MockChatRepository with media', () {
    Future<(MockChatRepository, MediaAttachment)> chatWithPhoto() async {
      final library = MockMediaLibrary();
      final uploader = MockMediaUploader(
        library: library,
        delay: Duration.zero,
      );
      final photo = (await uploader.upload(
        _image(),
        const ChatUpload('conv-1'),
      )).valueOrNull!;
      return (MockChatRepository(media: library), photo);
    }

    test('a sent photo comes back as an attachment from the library', () async {
      final (chat, photo) = await chatWithPhoto();

      final sent = (await chat.send(
        'conv-1',
        'Así quedó',
        mediaIds: [photo.id],
      )).valueOrNull!;

      expect(sent.media, [photo]);
      expect(sent.body, 'Así quedó');
    });

    test('like chatservice, a photo still needs text', () async {
      final (chat, photo) = await chatWithPhoto();

      expect(
        (await chat.send('conv-1', ' ', mediaIds: [photo.id])).failureOrNull,
        isA<DataRejected>(),
      );
    });

    test('an unknown media id is refused', () async {
      final chat = MockChatRepository(media: MockMediaLibrary());
      expect(
        (await chat.send('conv-1', 'hola', mediaIds: ['nope'])).failureOrNull,
        isA<DataRejected>(),
      );
    });
  });
}
