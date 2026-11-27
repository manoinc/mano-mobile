import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_avatar.dart';

/// The chat app-bar title: avatar, name and an optional verified badge.
///
/// With [onTap] the whole row is a button, for opening the person's profile.
class ManoChatHeader extends StatelessWidget {
  const ManoChatHeader({
    required this.name,
    required this.photoUrl,
    required this.online,
    required this.verified,
    this.onTap,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final bool online;
  final bool verified;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        ManoAvatar(photoUrl: photoUrl, size: 36, online: online),
        const SizedBox(width: ManoSpacing.sm),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (verified) ...[
          const SizedBox(width: ManoSpacing.xs),
          Icon(Icons.verified, size: 16, color: context.palette.clay),
        ],
      ],
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: 'Ver perfil de $name',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: row,
      ),
    );
  }
}
