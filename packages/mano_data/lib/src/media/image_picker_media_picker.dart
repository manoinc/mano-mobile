import 'package:image_picker/image_picker.dart';
import 'package:mano_domain/mano_domain.dart';

/// The plugin call, injectable so the adapter runs without a device.
typedef PickImage = Future<XFile?> Function(
  ImageSource source, {
  double? maxWidth,
  int? imageQuality,
});

// Big enough to read on a phone, small enough for the 2 MiB avatar cap.
const _maxWidth = 1600.0;
const _quality = 80;

const _byExtension = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'heic': 'image/heic',
  'heif': 'image/heif',
};

/// [MediaPicker] over the `image_picker` plugin.
final class ImagePickerMediaPicker implements MediaPicker {
  ImagePickerMediaPicker({PickImage? pick}) : _pick = pick ?? _plugin;

  final PickImage _pick;

  static Future<XFile?> _plugin(
    ImageSource source, {
    double? maxWidth,
    int? imageQuality,
  }) => ImagePicker().pickImage(
    source: source,
    maxWidth: maxWidth,
    imageQuality: imageQuality,
    requestFullMetadata: false,
  );

  @override
  Future<PickedImage?> pick(PhotoSource source) async {
    final file = await _pick(
      source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: _maxWidth,
      imageQuality: _quality,
    );
    if (file == null) return null;
    return PickedImage(
      bytes: await file.readAsBytes(),
      mimeType: file.mimeType ?? _mimeOf(file.name),
      name: file.name,
    );
  }

  static String _mimeOf(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return _byExtension[ext] ?? 'application/octet-stream';
  }
}
