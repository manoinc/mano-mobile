import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_image_viewer.dart';

/// A network photo that falls back to a flat stone block when it cannot load.
class ManoPhoto extends StatelessWidget {
  const ManoPhoto({required this.url, this.fit = BoxFit.cover, super.key});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.network(
    url,
    fit: fit,
    loadingBuilder: (context, child, progress) =>
        progress == null ? child : ColoredBox(color: context.palette.stone),
    errorBuilder: (context, error, stackTrace) => ColoredBox(
      color: context.palette.stone,
      child: Center(
        child: Icon(Icons.image_outlined, color: context.palette.faint),
      ),
    ),
  );
}

/// A horizontal strip of photos, e.g. what the client shot of the problem.
class ManoPhotoGallery extends StatelessWidget {
  const ManoPhotoGallery({
    required this.urls,
    this.height = 160,
    this.expandable = false,
    super.key,
  });

  final List<String> urls;
  final double height;

  /// Tapping a photo opens it in [ManoImageViewer].
  final bool expandable;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: ManoSpacing.sm),
        itemBuilder: (context, i) {
          final photo = ClipRRect(
            borderRadius: BorderRadius.circular(ManoRadius.card),
            child: AspectRatio(
              aspectRatio: 3 / 2,
              child: ManoPhoto(url: urls[i]),
            ),
          );
          if (!expandable) return photo;
          final tag = ManoImageViewer.heroTagFor(urls[i], i);
          return Semantics(
            label: 'Ver foto ${i + 1}',
            button: true,
            child: GestureDetector(
              onTap: () => ManoImageViewer.show(
                context,
                image: NetworkImage(urls[i]),
                heroTag: tag,
              ),
              child: Hero(tag: tag, child: photo),
            ),
          );
        },
      ),
    );
  }
}
