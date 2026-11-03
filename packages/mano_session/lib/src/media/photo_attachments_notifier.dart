import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import 'media_providers.dart';
import 'photo_attachment.dart';

/// Photos being added for one [UploadTarget]: pick, upload, retry, remove.
final photoAttachmentsProvider = NotifierProvider.autoDispose
    .family<PhotoAttachmentsNotifier, List<PhotoAttachment>, UploadTarget>(
      PhotoAttachmentsNotifier.new,
    );

final class PhotoAttachmentsNotifier extends Notifier<List<PhotoAttachment>> {
  PhotoAttachmentsNotifier(this.target);

  final UploadTarget target;
  var _nextId = 0;

  @override
  List<PhotoAttachment> build() => const [];

  bool get isUploading =>
      state.any((p) => p.state == PhotoUploadState.uploading);

  /// True when nothing is uploading or failed, so the photos can go out.
  bool get isReady => state.every((p) => p.state == PhotoUploadState.done);

  /// Ids to attach, in the order the photos were added.
  List<String> get mediaIds => [
    for (final p in state)
      if (p.uploaded case final u?) u.id,
  ];

  List<String> get urls => [
    for (final p in state)
      if (p.uploaded case final u?) u.url,
  ];

  Future<void> pick(PhotoSource source) async {
    final image = await ref.read(mediaPickerProvider).pick(source);
    if (image == null || !ref.mounted) return;
    final photo = PhotoAttachment(localId: 'photo-${_nextId++}', image: image);
    state = [...state, photo];
    await _upload(photo);
  }

  Future<void> retry(String localId) async {
    final photo = state.where((p) => p.localId == localId).firstOrNull;
    if (photo == null || photo.state != PhotoUploadState.failed) return;
    final again = photo.uploading();
    _replace(again);
    await _upload(again);
  }

  void remove(String localId) => state = [
    for (final p in state)
      if (p.localId != localId) p,
  ];

  void clear() => state = const [];

  Future<void> _upload(PhotoAttachment photo) async {
    final result = await ref
        .read(mediaUploaderProvider)
        .upload(photo.image, target);
    if (!ref.mounted) return;
    _replace(switch (result) {
      Ok(:final value) => photo.done(value),
      Err(:final failure) => photo.failed(failure),
    });
  }

  // A photo removed meanwhile stays removed.
  void _replace(PhotoAttachment photo) =>
      state = [for (final p in state) p.localId == photo.localId ? photo : p];
}
