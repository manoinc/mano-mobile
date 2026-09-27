import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A quiet way out, in the corner of a screen.
///
/// Distinct from [ManoQuietButton], which is a full-width secondary action and
/// demands all the width it can get. This one takes only the room its label
/// needs, so it can sit in a header row.
class ManoTextAction extends StatelessWidget {
  const ManoTextAction({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: ManoSpacing.md),
        shape: const StadiumBorder(),
        foregroundColor: ManoColors.clay,
        disabledForegroundColor: ManoColors.faint,
        textStyle: theme.textTheme.labelLarge,
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
