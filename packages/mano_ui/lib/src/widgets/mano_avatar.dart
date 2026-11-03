import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A circular network-image avatar, shared by Inbox tiles and the Profile
/// header.
///
/// Loading and error states are flat colour rather than a shimmer or a
/// spinner, for the same reason `showManoSheet` dims instead of blurring --
/// it costs nothing per frame and there is nothing here worth drawing
/// attention to.
class ManoAvatar extends StatelessWidget {
  const ManoAvatar({
    required this.photoUrl,
    this.size = 44,
    this.online,
    this.image,
    super.key,
  });

  /// `null` renders the same stone-circle-and-person-icon fallback as a
  /// failed network load -- there is no photo to fetch, so this skips
  /// `Image.network` entirely rather than requesting a URL that isn't there.
  final String? photoUrl;
  final double size;

  /// Shown instead of [photoUrl], e.g. a photo still uploading.
  final ImageProvider? image;

  /// `null` = no online indicator at all. `true`/`false` shows the dot.
  final bool? online;

  Widget _fallback() => ColoredBox(
    color: ManoColors.stone,
    child: Center(
      child: Icon(Icons.person, color: ManoColors.faint, size: size * 0.6),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final local = image;
    final photo = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: local != null
            ? Image(
                image: local,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              )
            : url == null
            ? _fallback()
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return ColoredBox(color: ManoColors.stone);
                },
                errorBuilder: (context, error, stackTrace) => _fallback(),
              ),
      ),
    );

    final isOnline = online;
    if (isOnline == null) return photo;

    final dotSize = size * 0.28;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          photo,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              key: const Key('mano-avatar-online-dot'),
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? Colors.green : ManoColors.faint,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
