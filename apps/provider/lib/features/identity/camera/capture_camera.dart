import 'package:flutter/widgets.dart';
import 'package:mano_session/mano_session.dart';

/// A live camera for one capture: open a lens, show it, take a photo.
abstract interface class CaptureCamera {
  /// Opens the lens facing [facing], or whichever exists; throws [CameraDenied].
  Future<void> open(CameraFacing facing);

  /// What the open lens sees.
  Widget preview();

  Future<PickedImage> take();

  Future<void> close();

  /// The phone's settings for this app, to grant the camera after a refusal.
  Future<void> openSettings();
}

/// The person refused the camera, or the phone does not allow it.
final class CameraDenied implements Exception {
  const CameraDenied();
}
