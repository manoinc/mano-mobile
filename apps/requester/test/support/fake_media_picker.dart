import 'dart:convert';

import 'package:mano_session/mano_session.dart';

/// Always hands back the same 1x1 PNG, from either source.
final class FakeMediaPicker implements MediaPicker {
  final sources = <PhotoSource>[];

  @override
  Future<PickedImage?> pick(
    PhotoSource source, {
    CameraFacing facing = CameraFacing.rear,
  }) async {
    sources.add(source);
    return PickedImage(
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
      ),
      mimeType: 'image/png',
      name: 'foto.png',
    );
  }
}
