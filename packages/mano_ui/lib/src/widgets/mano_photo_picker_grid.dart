import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'picked_photo_tile.dart';

enum ManoPhotoStatus { uploading, done, failed }

/// One tile in a [ManoPhotoPickerGrid].
@immutable
class ManoPickedPhoto {
  const ManoPickedPhoto({
    required this.id,
    required this.image,
    this.status = ManoPhotoStatus.done,
  });

  final String id;

  /// Local bytes while uploading, or the stored photo.
  final ImageProvider image;
  final ManoPhotoStatus status;
}

/// Square photo tiles with a dashed add tile, for any "add photos" step.
class ManoPhotoPickerGrid extends StatelessWidget {
  const ManoPhotoPickerGrid({
    required this.photos,
    required this.onAdd,
    this.onRemove,
    this.onRetry,
    this.maxPhotos = 6,
    this.addLabel = 'Agregar fotos',
    this.columns = 3,
    super.key,
  });

  final List<ManoPickedPhoto> photos;
  final VoidCallback onAdd;
  final ValueChanged<String>? onRemove;
  final ValueChanged<String>? onRetry;
  final int maxPhotos;
  final String addLabel;
  final int columns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = ManoSpacing.sm;
      final side = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final (i, photo) in photos.indexed)
            SizedBox.square(
              key: ValueKey(photo.id),
              dimension: side,
              child: PickedPhotoTile(
                photo: photo,
                position: i + 1,
                onRemove: onRemove,
                onRetry: onRetry,
              ),
            ),
          if (photos.length < maxPhotos)
            SizedBox.square(
              dimension: side,
              child: _AddTile(label: addLabel, onTap: onAdd),
            ),
        ],
      );
    },
  );
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ManoRadius.card),
        child: CustomPaint(
          painter: _DashedBorder(color: theme.colorScheme.outlineVariant),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: ink),
              const SizedBox(height: ManoSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: ManoSpacing.xs),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(ManoRadius.card),
        ),
      );
    const dash = 6.0;
    const space = 4.0;
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + space) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
