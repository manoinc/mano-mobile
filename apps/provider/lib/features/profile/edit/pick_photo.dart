import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Asks gallery or camera, then picks and uploads into [target].
Future<void> pickPhoto(
  BuildContext context,
  WidgetRef ref,
  UploadTarget target,
) async {
  final photos = ref.read(photoAttachmentsProvider(target).notifier);
  final source = await showManoSheet<PhotoSource>(
    context: context,
    builder: (sheet) => ManoMediaSourceSheet(
      onGallery: () => Navigator.pop(sheet, PhotoSource.gallery),
      onCamera: () => Navigator.pop(sheet, PhotoSource.camera),
      onClose: () => Navigator.pop(sheet),
    ),
  );
  if (source != null) await photos.pick(source);
}

ManoPhotoStatus photoStatus(PhotoUploadState state) => switch (state) {
  PhotoUploadState.uploading => ManoPhotoStatus.uploading,
  PhotoUploadState.done => ManoPhotoStatus.done,
  PhotoUploadState.failed => ManoPhotoStatus.failed,
};
