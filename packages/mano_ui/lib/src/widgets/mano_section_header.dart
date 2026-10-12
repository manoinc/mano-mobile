import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A rail's title; with [onTap] the whole row, chevron included, is the "see all" target.
class ManoSectionHeader extends StatelessWidget {
  const ManoSectionHeader({required this.title, this.onTap, super.key});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium,
    );

    if (onTap == null) return label;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ManoRadius.card),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Flexible(child: label),
              const SizedBox(width: ManoSpacing.xs),
              const Icon(Icons.chevron_right, color: ManoColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}
