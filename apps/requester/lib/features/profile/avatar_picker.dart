import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'profile_sheets.dart';

const _target = AvatarUpload();

/// The profile photo: shows the picked bytes while uploading, then keeps the URL.
class AvatarPicker extends ConsumerWidget {
  const AvatarPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(photoAttachmentsProvider(_target));
    final photoUrl = ref.watch(clientProfileProvider).value?.photoUrl;
    final latest = photos.lastOrNull;

    return ManoAvatarEditor(
      photoUrl: photoUrl,
      localImage: latest == null ? null : MemoryImage(latest.bytes),
      uploading: latest?.state == PhotoUploadState.uploading,
      onTap: () => _change(context, ref),
    );
  }

  Future<void> _change(BuildContext context, WidgetRef ref) async {
    final source = await showManoSheet<PhotoSource>(
      context: context,
      builder: (sheet) => ManoMediaSourceSheet(
        onGallery: () => Navigator.pop(sheet, PhotoSource.gallery),
        onCamera: () => Navigator.pop(sheet, PhotoSource.camera),
        onClose: () => Navigator.pop(sheet),
      ),
    );
    if (source == null || !context.mounted) return;
    final photos = ref.read(photoAttachmentsProvider(_target).notifier)
      ..clear();
    await photos.pick(source);
    if (!context.mounted) return;
    final url = photos.urls.lastOrNull;
    if (url != null) {
      await ref.read(clientProfileActionsProvider.notifier).setPhoto(url);
    } else if (ref.read(photoAttachmentsProvider(_target)).isNotEmpty) {
      photos.clear();
      showProfileMessage(
        context,
        'No pudimos subir tu foto. Intenta de nuevo.',
      );
    }
  }
}
