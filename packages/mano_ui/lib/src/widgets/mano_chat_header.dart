import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_avatar.dart';

/// The chat app-bar title: avatar, name and an optional verified badge.
class ManoChatHeader extends StatelessWidget {
  const ManoChatHeader({
    required this.name,
    required this.photoUrl,
    required this.online,
    required this.verified,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final bool online;
  final bool verified;

  @override
  Widget build(BuildContext context) => Row(
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
        const Icon(Icons.verified, size: 16, color: ManoColors.clay),
      ],
    ],
  );
}
