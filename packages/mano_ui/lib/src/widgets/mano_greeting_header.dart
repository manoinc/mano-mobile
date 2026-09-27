import 'package:flutter/material.dart';

/// The Home tab's opening line: a warm, first-name greeting.
///
/// Takes a name and nothing else -- no session, no user entity. The screen
/// resolves whatever "name" means (a requester's given name, a fallback) and
/// hands over a plain string.
class ManoGreetingHeader extends StatelessWidget {
  const ManoGreetingHeader({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Text(
      'Hola, $name',
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
    );
  }
}
