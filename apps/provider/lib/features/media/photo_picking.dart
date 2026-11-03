import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Asks gallery or camera, then picks into [photos].
Future<void> pickPhoto(BuildContext context, PhotoAttachmentsNotifier photos) =>
    showManoSheet<void>(
      context: context,
      builder: (sheet) {
        void pick(PhotoSource source) {
          Navigator.pop(sheet);
          photos.pick(source);
        }

        return ManoMediaSourceSheet(
          onGallery: () => pick(PhotoSource.gallery),
          onCamera: () => pick(PhotoSource.camera),
          onClose: () => Navigator.pop(sheet),
        );
      },
    );

/// The photos as tiles, drawn from their local bytes.
List<ManoPickedPhoto> pickedPhotos(List<PhotoAttachment> photos) => [
  for (final p in photos)
    ManoPickedPhoto(
      id: p.localId,
      image: MemoryImage(p.bytes),
      status: switch (p.state) {
        PhotoUploadState.uploading => ManoPhotoStatus.uploading,
        PhotoUploadState.done => ManoPhotoStatus.done,
        PhotoUploadState.failed => ManoPhotoStatus.failed,
      },
    ),
];
