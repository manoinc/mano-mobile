import 'dart:typed_data';

import 'package:mano_domain/mano_domain.dart';

enum PhotoUploadState { uploading, done, failed }

/// One photo the user added, from the moment it is picked.
final class PhotoAttachment {
  const PhotoAttachment({
    required this.localId,
    required this.image,
    this.state = PhotoUploadState.uploading,
    this.uploaded,
    this.failure,
  });

  final String localId;
  final PickedImage image;
  final PhotoUploadState state;

  /// Set once [state] is done.
  final MediaAttachment? uploaded;

  /// Set when [state] is failed.
  final DataFailure? failure;

  /// Shown while uploading, so the photo appears at once.
  Uint8List get bytes => image.bytes;

  PhotoAttachment uploading() =>
      PhotoAttachment(localId: localId, image: image);

  PhotoAttachment done(MediaAttachment attachment) => PhotoAttachment(
    localId: localId,
    image: image,
    state: PhotoUploadState.done,
    uploaded: attachment,
  );

  PhotoAttachment failed(DataFailure reason) => PhotoAttachment(
    localId: localId,
    image: image,
    state: PhotoUploadState.failed,
    failure: reason,
  );
}
