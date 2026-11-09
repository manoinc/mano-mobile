import 'dart:async';
import 'dart:typed_data';

import 'package:mano_session/mano_session.dart';

// A 1x1 transparent PNG.
final tinyPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// Always hands back [tinyPng], and records where it was asked to look.
final class FakeMediaPicker implements MediaPicker {
  final sources = <PhotoSource>[];

  @override
  Future<PickedImage?> pick(
    PhotoSource source, {
    CameraFacing facing = CameraFacing.rear,
  }) async {
    sources.add(source);
    return PickedImage(bytes: tinyPng, mimeType: 'image/png', name: 'a.png');
  }
}

/// Holds each upload until the test completes it.
final class HeldMediaUploader implements MediaUploader {
  final _pending = <Completer<Result<MediaAttachment, DataFailure>>>[];
  final targets = <UploadTarget>[];

  @override
  Future<Result<MediaAttachment, DataFailure>> upload(
    PickedImage image,
    UploadTarget target,
  ) {
    targets.add(target);
    final completer = Completer<Result<MediaAttachment, DataFailure>>();
    _pending.add(completer);
    return completer.future;
  }

  void succeed(String url) =>
      _pending.removeAt(0).complete(Ok(MediaAttachment(id: 'm-1', url: url)));

  void fail() => _pending.removeAt(0).complete(const Err(DataUnavailable()));
}
