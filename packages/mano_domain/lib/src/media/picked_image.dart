import 'dart:typed_data';

/// A photo the user chose, read into memory and not yet uploaded.
final class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.mimeType,
    required this.name,
  });

  /// The image types the media service accepts.
  static const supportedTypes = {'image/jpeg', 'image/png', 'image/webp'};

  final Uint8List bytes;
  final String mimeType;
  final String name;

  int get byteSize => bytes.length;

  bool get isSupported => supportedTypes.contains(mimeType);

  @override
  String toString() => 'PickedImage($name, $mimeType, $byteSize B)';
}
