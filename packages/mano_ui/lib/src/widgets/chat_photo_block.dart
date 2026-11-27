import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';
import 'mano_photo_picker_grid.dart';
import 'mano_spinner.dart';

/// A message's photos: one wide, or several in two columns; internal to mano_ui.
class ChatPhotoBlock extends StatelessWidget {
  const ChatPhotoBlock({
    required this.photos,
    required this.width,
    this.status = ManoPhotoStatus.done,
    this.onTap,
    this.heroTags,
    super.key,
  });

  final List<ImageProvider> photos;
  final double width;
  final ManoPhotoStatus status;
  final ValueChanged<int>? onTap;
  final List<Object>? heroTags;

  @override
  Widget build(BuildContext context) {
    if (photos.length == 1) {
      return SizedBox(
        width: width,
        child: AspectRatio(aspectRatio: 4 / 3, child: _photo(0)),
      );
    }
    const gap = ManoSpacing.xs;
    final side = (width - gap) / 2;
    return SizedBox(
      width: width,
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (var i = 0; i < photos.length; i++)
            SizedBox.square(dimension: side, child: _photo(i)),
        ],
      ),
    );
  }

  Widget _photo(int i) {
    Widget image = Image(
      image: photos[i],
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: context.palette.stone,
        child: Center(
          child: Icon(Icons.image_outlined, color: context.palette.faint),
        ),
      ),
    );
    final tags = heroTags;
    if (tags != null && i < tags.length) {
      image = Hero(tag: tags[i], child: image);
    }
    final tap = onTap;
    return Semantics(
      label: 'Foto ${i + 1}',
      image: true,
      button: tap != null,
      child: GestureDetector(
        key: const Key('chat-bubble-photo'),
        onTap: tap == null ? null : () => tap(i),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ManoRadius.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              AnimatedOpacity(
                opacity: status == ManoPhotoStatus.done ? 0 : 1,
                duration: ManoMotion.normal,
                child: ColoredBox(
                  color: ManoColors.scrim.withValues(alpha: 0.45),
                  child: Center(
                    child: switch (status) {
                      ManoPhotoStatus.uploading => const ManoSpinner(
                        color: Colors.white,
                      ),
                      ManoPhotoStatus.failed => const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white,
                      ),
                      ManoPhotoStatus.done => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
