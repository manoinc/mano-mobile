/// A stored file, as the reader may fetch it right now.
final class MediaAttachment {
  const MediaAttachment({
    required this.id,
    required this.url,
    this.mimeType,
    this.byteSize,
  });

  final String id;

  /// Short-lived for chat; never persist it.
  final String url;
  final String? mimeType;
  final int? byteSize;

  bool get isImage => mimeType == null || mimeType!.startsWith('image/');

  @override
  bool operator ==(Object other) =>
      other is MediaAttachment &&
      other.id == id &&
      other.url == url &&
      other.mimeType == mimeType &&
      other.byteSize == byteSize;

  @override
  int get hashCode => Object.hash(id, url, mimeType, byteSize);

  @override
  String toString() => 'MediaAttachment($id)';
}
