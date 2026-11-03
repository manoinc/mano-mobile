import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';
import 'mano_photo_picker_grid.dart';

/// One picked photo with its upload overlay and remove button; internal to mano_ui.
class PickedPhotoTile extends StatelessWidget {
  const PickedPhotoTile({
    required this.photo,
    required this.position,
    this.onRemove,
    this.onRetry,
    super.key,
  });

  final ManoPickedPhoto photo;
  final int position;
  final ValueChanged<String>? onRemove;
  final ValueChanged<String>? onRetry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(ManoRadius.card),
          child: Image(
            image: photo.image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: ManoColors.stone,
              child: Icon(Icons.image_outlined, color: ManoColors.faint),
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: photo.status == ManoPhotoStatus.done ? 0 : 1,
          duration: ManoMotion.normal,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ManoColors.ink.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(ManoRadius.card),
            ),
            child: Center(
              child: switch (photo.status) {
                ManoPhotoStatus.uploading => const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
                ManoPhotoStatus.failed => Semantics(
                  label: 'Reintentar foto $position',
                  button: true,
                  onTap: onRetry == null ? null : () => onRetry!(photo.id),
                  child: ExcludeSemantics(
                    child: IconButton(
                      onPressed: onRetry == null
                          ? null
                          : () => onRetry!(photo.id),
                      icon: const Icon(Icons.refresh_rounded),
                      color: Colors.white,
                    ),
                  ),
                ),
                ManoPhotoStatus.done => const SizedBox.shrink(),
              },
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: ManoSpacing.xs,
            right: ManoSpacing.xs,
            child: Semantics(
              label: 'Quitar foto $position',
              button: true,
              onTap: () => onRemove!(photo.id),
              child: ExcludeSemantics(
                child: GestureDetector(
                  onTap: () => onRemove!(photo.id),
                  child: Container(
                    padding: const EdgeInsets.all(ManoSpacing.xs),
                    decoration: BoxDecoration(
                      color: ManoColors.ink.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
