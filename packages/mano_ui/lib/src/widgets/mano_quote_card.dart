import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_rating_badge.dart';
import 'mano_status_chip.dart';
import 'mano_text_action.dart';

/// One professional's price for a project, with its message and decisions.
class ManoQuoteCard extends StatelessWidget {
  const ManoQuoteCard({
    required this.avatar,
    required this.name,
    required this.amountLabel,
    this.ageLabel,
    this.message,
    this.statusLabel,
    this.statusTone = ManoStatusTone.neutral,
    this.onSelect,
    this.onDiscard,
    this.selected = false,
    this.selectLabel = 'Elegir',
    this.discardLabel = 'Descartar',
    this.ratingLabel,
    this.rated = true,
    this.onProviderTap,
    super.key,
  });

  final Widget avatar;
  final String name;

  /// Pre-formatted, e.g. "$1.650.000".
  final String amountLabel;

  /// e.g. "hace 1h".
  final String? ageLabel;
  final String? message;

  /// null hides the chip.
  final String? statusLabel;
  final ManoStatusTone statusTone;

  /// null hides the action.
  final VoidCallback? onSelect;
  final VoidCallback? onDiscard;

  /// Outlines the card as the chosen one.
  final bool selected;
  final String selectLabel;
  final String discardLabel;

  /// Shown under the name, e.g. "4,9 · 32"; null hides it.
  final String? ratingLabel;
  final bool rated;

  /// Tapping the avatar and name, e.g. to open the professional's profile.
  final VoidCallback? onProviderTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final note = message;
    final status = statusLabel;
    final age = ageLabel;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ManoRadius.card),
        side: selected
            ? const BorderSide(color: ManoColors.clay, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ProviderArea(
                    onTap: onProviderTap,
                    child: Row(
                      children: [
                        avatar,
                        const SizedBox(width: ManoSpacing.sm),
                        Expanded(child: _who(textTheme, age)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: ManoSpacing.sm),
                // A price is never truncated; it shrinks instead.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      amountLabel,
                      style: textTheme.titleMedium?.copyWith(
                        color: ManoColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (status != null) ...[
              const SizedBox(height: ManoSpacing.sm),
              ManoStatusChip(label: status, tone: statusTone),
            ],
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: ManoSpacing.sm),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: ManoColors.sand,
                  borderRadius: BorderRadius.circular(ManoRadius.card),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(ManoSpacing.sm),
                  child: Text(
                    note,
                    style: textTheme.bodyMedium?.copyWith(
                      color: ManoColors.muted,
                    ),
                  ),
                ),
              ),
            ],
            if (onSelect != null || onDiscard != null) ...[
              const SizedBox(height: ManoSpacing.xs),
              Row(
                children: [
                  if (onDiscard != null)
                    Flexible(
                      child: ManoTextAction(
                        label: discardLabel,
                        onPressed: onDiscard,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  const Spacer(),
                  if (onSelect != null)
                    Flexible(
                      child: ManoTextAction(
                        label: selectLabel,
                        onPressed: onSelect,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _who(TextTheme textTheme, String? age) {
    final faint = textTheme.bodySmall?.copyWith(color: ManoColors.faint);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall?.copyWith(color: ManoColors.ink),
        ),
        if (ratingLabel != null || age != null)
          Row(
            children: [
              if (ratingLabel case final rating?)
                Flexible(
                  child: ManoRatingBadge(label: rating, rated: rated),
                ),
              if (ratingLabel != null && age != null)
                Text('  ·  ', style: faint),
              if (age != null)
                Flexible(
                  child: Text(
                    age,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: faint,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _ProviderArea extends StatelessWidget {
  const _ProviderArea({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => onTap == null
      ? child
      : InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ManoRadius.card),
          child: child,
        );
}
