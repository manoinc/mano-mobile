import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A fake search bar: a full-width pill that only ever triggers a callback.
///
/// No `TextField`, no keyboard -- it is a navigation trigger to wherever
/// real search input lives, not an input field itself.
class ManoSearchPill extends StatelessWidget {
  const ManoSearchPill({
    required this.onTap,
    this.hintText = '¿Qué necesitas hoy?',
    super.key,
  });

  final VoidCallback onTap;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ManoColors.sand,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ManoSpacing.md,
            vertical: ManoSpacing.md,
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: ManoColors.faint),
              const SizedBox(width: ManoSpacing.sm),
              Expanded(
                child: Text(
                  hintText,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ManoColors.faint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
