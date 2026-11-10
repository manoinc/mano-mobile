import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mano_provider/features/identity/camera/capture_camera.dart';
import 'package:mano_provider/features/identity/camera/capture_camera_provider.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'fake_media.dart';

/// A camera that records which lens was asked for; [denied] refuses access.
final class FakeCaptureCamera implements CaptureCamera {
  FakeCaptureCamera({this.denied = false});

  bool denied;
  final opened = <CameraFacing>[];
  var shots = 0;
  var closed = 0;
  var settings = 0;

  @override
  Future<void> open(CameraFacing facing) async {
    opened.add(facing);
    if (denied) throw const CameraDenied();
  }

  @override
  Widget preview() =>
      const ColoredBox(key: Key('fake-preview'), color: ManoColors.muted);

  @override
  Future<PickedImage> take() async {
    shots++;
    return PickedImage(bytes: tinyPng, mimeType: 'image/png', name: 'id.png');
  }

  @override
  Future<void> close() async => closed++;

  @override
  Future<void> openSettings() async => settings++;
}

/// Every identity photo comes from [camera].
Override fakeCamera(FakeCaptureCamera camera) =>
    captureCameraProvider.overrideWithValue(() => camera);
