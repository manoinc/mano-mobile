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
    super.key,
  });

  final String name;

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
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge,
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
