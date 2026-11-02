import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

final class _Picker implements MediaPicker {
  PickedImage? next = PickedImage(
    bytes: Uint8List.fromList([1, 2]),
    mimeType: 'image/jpeg',
    name: 'a.jpg',
  );
  final sources = <PhotoSource>[];

  @override
  Future<PickedImage?> pick(PhotoSource source) async {
    sources.add(source);
    return next;
  }
}

final class _Uploader implements MediaUploader {
  final pending = <Completer<Result<MediaAttachment, DataFailure>>>[];
  final targets = <UploadTarget>[];

  @override
  Future<Result<MediaAttachment, DataFailure>> upload(
    PickedImage image,
    UploadTarget target,
  ) {
    targets.add(target);
    final c = Completer<Result<MediaAttachment, DataFailure>>();
    pending.add(c);
    return c.future;
  }
}

const _target = ChatUpload('conv-1');

void main() {
  late _Picker picker;
  late _Uploader uploader;
  late ProviderContainer container;

  setUp(() {
    picker = _Picker();
    uploader = _Uploader();
    container = ProviderContainer.test(
      overrides: [
        mediaPickerProvider.overrideWithValue(picker),
        mediaUploaderProvider.overrideWithValue(uploader),
      ],
    );
    // Screens watch it; without a listener autoDispose would drop it between reads.
    container.listen(photoAttachmentsProvider(_target), (_, _) {});
  });

  List<PhotoAttachment> state() =>
      container.read(photoAttachmentsProvider(_target));
  PhotoAttachmentsNotifier notifier() =>
      container.read(photoAttachmentsProvider(_target).notifier);

  test('starts empty', () {
    expect(state(), isEmpty);
    expect(notifier().isUploading, isFalse);
  });

  test('a picked photo shows at once as uploading, then done', () async {
    final picking = notifier().pick(PhotoSource.gallery);
    await pumpEventQueue();

    expect(picker.sources, [PhotoSource.gallery]);
    expect(uploader.targets, [_target]);
    expect(state().single.state, PhotoUploadState.uploading);
    expect(state().single.bytes, [1, 2]);
    expect(notifier().isUploading, isTrue);

    uploader.pending.single.complete(
      const Ok(MediaAttachment(id: 'md1', url: 'https://x/1')),
    );
    await picking;

    expect(state().single.state, PhotoUploadState.done);
    expect(notifier().mediaIds, ['md1']);
    expect(notifier().urls, ['https://x/1']);
    expect(notifier().isUploading, isFalse);
  });

  test('backing out of the picker adds nothing', () async {
    picker.next = null;
    await notifier().pick(PhotoSource.camera);
    expect(state(), isEmpty);
    expect(uploader.targets, isEmpty);
  });

  test('a failed upload can be retried', () async {
    final first = notifier().pick(PhotoSource.gallery);
    await pumpEventQueue();
    uploader.pending.single.complete(const Err(DataUnavailable()));
    await first;

    expect(state().single.state, PhotoUploadState.failed);
    expect(state().single.failure, isA<DataUnavailable>());
    expect(notifier().mediaIds, isEmpty);

    final retry = notifier().retry(state().single.localId);
    await pumpEventQueue();
    expect(state().single.state, PhotoUploadState.uploading);
    uploader.pending.last.complete(
      const Ok(MediaAttachment(id: 'md2', url: 'https://x/2')),
    );
    await retry;

    expect(notifier().mediaIds, ['md2']);
  });

  test('remove drops a photo, clear drops them all, order is kept', () async {
    for (var i = 0; i < 3; i++) {
      final p = notifier().pick(PhotoSource.gallery);
      await pumpEventQueue();
      uploader.pending.last.complete(
        Ok(MediaAttachment(id: 'md$i', url: 'https://x/$i')),
      );
      await p;
    }
    expect(notifier().mediaIds, ['md0', 'md1', 'md2']);

    notifier().remove(state()[1].localId);
    expect(notifier().mediaIds, ['md0', 'md2']);

    notifier().clear();
    expect(state(), isEmpty);
  });

  test('a photo removed while uploading stays removed', () async {
    final p = notifier().pick(PhotoSource.gallery);
    await pumpEventQueue();
    notifier().remove(state().single.localId);
    uploader.pending.single.complete(
      const Ok(MediaAttachment(id: 'md1', url: 'https://x/1')),
    );
    await p;
    expect(state(), isEmpty);
  });

  test('each target keeps its own photos', () async {
    final p = notifier().pick(PhotoSource.gallery);
    await pumpEventQueue();
    expect(
      container.read(photoAttachmentsProvider(const AvatarUpload())),
      isEmpty,
    );
    uploader.pending.single.complete(
      const Ok(MediaAttachment(id: 'md1', url: 'u')),
    );
    await p;
  });
}
