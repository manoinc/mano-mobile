import 'package:mano_domain/mano_domain.dart';

import '../mock/mock_fixtures.dart';
import 'mock_media_library.dart';

// Stock photos stand in for the user's bytes, which have nowhere to live offline.
const _stock = ['1581578731548-c64695cc6952', '1504148455328-c376907d081c'];

/// [MediaUploader] that keeps nothing but applies the media service's rules.
final class MockMediaUploader implements MediaUploader {
  MockMediaUploader({
    MockMediaLibrary? library,
    this.delay = const Duration(milliseconds: 600),
  }) : _library = library ?? MockMediaLibrary();

  final MockMediaLibrary _library;
  final Duration delay;
  int _next = 1;

  @override
  Future<Result<MediaAttachment, DataFailure>> upload(
    PickedImage image,
    UploadTarget target,
  ) async {
    if (!image.isSupported) {
      return Err(
        DataRejected(reason: 'UnsupportedMimeType: ${image.mimeType}'),
      );
    }
    if (image.byteSize > target.maxBytes) {
      return const Err(DataRejected(reason: 'ObjectTooLarge'));
    }
    await Future<void>.delayed(delay);
    final n = _next++;
    final attachment = MediaAttachment(
      id: 'media-$n',
      url: mockPhoto(_stock[n % _stock.length]),
      mimeType: image.mimeType,
      byteSize: image.byteSize,
    );
    _library.add(attachment);
    return Ok(attachment);
  }
}
