import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_avatar.dart';

/// The Home tab's opening line: a warm, first-name greeting.
///
/// Takes a name and, optionally, a photo -- no session, no user entity. The
/// screen resolves whatever "name" means and hands over plain strings.
class ManoGreetingHeader extends StatelessWidget {
  const ManoGreetingHeader({required this.name, this.photoUrl, super.key});

  final String name;

  /// Shows a small avatar before the greeting when given.
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final greeting = Text(
      'Hola, $name',
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
    );
    final photo = photoUrl;
    if (photo == null) return greeting;

    return Row(
      children: [
        ManoAvatar(photoUrl: photo, size: 40),
        const SizedBox(width: ManoSpacing.sm),
        Expanded(child: greeting),
      ],
    );
  }
}
