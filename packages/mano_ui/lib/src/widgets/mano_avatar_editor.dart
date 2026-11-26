import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_avatar.dart';
import 'mano_spinner.dart';

/// The user's own photo with a camera badge; tapping asks for a new one.
class ManoAvatarEditor extends StatelessWidget {
  const ManoAvatarEditor({
    required this.photoUrl,
    required this.onTap,
    this.localImage,
    this.uploading = false,
    this.size = 96,
    super.key,
  });

  final String? photoUrl;

  /// The picked photo, shown at once while it uploads.
  final ImageProvider? localImage;
  final bool uploading;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badge = size * 0.32;

    return Semantics(
      button: true,
      label: 'Cambiar foto',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: uploading ? null : onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ManoAvatar(photoUrl: photoUrl, image: localImage, size: size),
              if (uploading)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ManoColors.ink.withValues(alpha: 0.35),
                    ),
                    child: Center(
                      child: ManoSpinner(
                        size: size * 0.2,
                        color: scheme.surface,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: badge,
                  height: badge,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.onSurface,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: badge * 0.55,
                    color: scheme.surface,
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
