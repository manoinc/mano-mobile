import 'dart:convert';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mano_session/mano_session.dart';

// A 1x1 PNG, so Image.memory decodes it.
final tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Always hands back [tinyPng], from either source.
final class FakeMediaPicker implements MediaPicker {
  final sources = <PhotoSource>[];
  final facings = <CameraFacing>[];

  @override
  Future<PickedImage?> pick(
    PhotoSource source, {
    CameraFacing facing = CameraFacing.rear,
  }) async {
    sources.add(source);
    facings.add(facing);
    return PickedImage(bytes: tinyPng, mimeType: 'image/png', name: 'a.png');
  }
}

/// Stores instantly, at upload-1.jpg, upload-2.jpg…
final class FakeMediaUploader implements MediaUploader {
  var _n = 0;

  @override
  Future<Result<MediaAttachment, DataFailure>> upload(
    PickedImage image,
    UploadTarget target,
  ) async {
    _n++;
    return Ok(
      MediaAttachment(id: 'm$_n', url: 'https://x.test/upload-$_n.jpg'),
    );
  }
}

/// The picker and an instant uploader.
List<Override> fakeMediaOverrides() => [
  mediaPickerProvider.overrideWithValue(FakeMediaPicker()),
  mediaUploaderProvider.overrideWithValue(FakeMediaUploader()),
];
