import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

const _size = 96.0;

/// The profile photo: the new one's local bytes while it uploads, else the saved one.
class AvatarEditor extends StatelessWidget {
  const AvatarEditor({
    required this.photoUrl,
    required this.latest,
    required this.onChange,
    required this.onRetry,
    super.key,
  });

  final String photoUrl;

  /// The photo just picked, if any.
  final PhotoAttachment? latest;
  final VoidCallback onChange;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final picked = latest;
    return Column(
      children: [
        GestureDetector(
          onTap: onChange,
          child: picked == null
              ? ManoAvatar(
                  photoUrl: photoUrl.isEmpty ? null : photoUrl,
                  size: _size,
                )
              : _Local(photo: picked, onRetry: onRetry),
        ),
        const SizedBox(height: ManoSpacing.xs),
        ManoTextAction(label: 'Cambiar foto', onPressed: onChange),
      ],
    );
  }
}

class _Local extends StatelessWidget {
  const _Local({required this.photo, required this.onRetry});

  final PhotoAttachment photo;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: _size,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipOval(child: Image.memory(photo.bytes, fit: BoxFit.cover)),
        if (photo.state != PhotoUploadState.done)
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ManoColors.ink.withValues(alpha: 0.45),
            ),
            child: Center(
              child: photo.state == PhotoUploadState.uploading
                  ? ManoSpinner(
                      size: _size * 0.2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : IconButton(
                      onPressed: onRetry,
                      tooltip: 'Reintentar foto',
                      icon: const Icon(Icons.refresh_rounded),
                      color: Colors.white,
                    ),
            ),
          ),
      ],
    ),
  );
}
