import '../result.dart';
import '../shared/data_failure.dart';
import 'media_attachment.dart';
import 'picked_image.dart';
import 'upload_target.dart';

/// Stores a picked file and hands back what can be attached to it.
abstract interface class MediaUploader {
  Future<Result<MediaAttachment, DataFailure>> upload(
    PickedImage image,
    UploadTarget target,
  );
}
