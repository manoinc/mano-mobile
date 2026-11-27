import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_avatar.dart';

/// The Profile tab's header: photo, name, and a way to edit both.
///
/// Dumb like everything else here -- a `User` entity's name and photo URL
/// arrive already unwrapped, so this widget cannot see the domain and the
/// screen does the mapping.
class ManoProfileHeader extends StatelessWidget {
  const ManoProfileHeader({
    required this.name,
    required this.photoUrl,
    required this.onEdit,
    this.subtitle,
    super.key,
  });

  final String name;

  /// A quiet line under the name, e.g. the contact details.
  final String? subtitle;

  /// `null` when there is no real photo to show -- `ManoAvatar` renders its
  /// stone-circle-and-person-icon fallback rather than a stranger's photo.
  final String? photoUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        ManoAvatar(photoUrl: photoUrl, size: 72),
        const SizedBox(width: ManoSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge,
              ),
              if (subtitle case final line?)
                Text(
                  line,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: context.palette.muted,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Editar',
        ),
      ],
    );
  }
}
