import 'picked_image.dart';

/// Where a new photo comes from.
enum PhotoSource { camera, gallery }

/// The device's camera and photo library.
abstract interface class MediaPicker {
  /// Null when the user backs out without choosing.
  Future<PickedImage?> pick(PhotoSource source);
}
