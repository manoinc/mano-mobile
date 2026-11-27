import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_avatar.dart';
import 'mano_primary_button.dart';

/// One label and value line in a [ManoProfileSheet].
@immutable
class ManoProfileFact {
  const ManoProfileFact({required this.label, required this.value});

  final String label;
  final String value;
}

/// Someone's profile card: photo, name, optional rating, facts and one action.
///
/// The body for [showManoSheet]; the screen maps its entities to these strings.
class ManoProfileSheet extends StatelessWidget {
  const ManoProfileSheet({
    required this.name,
    required this.photoUrl,
    required this.verified,
    this.ratingLabel,
    this.facts = const [],
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final bool verified;

  /// Already formatted, e.g. "4,8 · 32 reseñas"; `null` hides the rating.
  final String? ratingLabel;
  final List<ManoProfileFact> facts;

  /// The primary action shows only when both this and [onAction] are set.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rating = ratingLabel;
    final label = actionLabel;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ManoAvatar(photoUrl: photoUrl, size: 72),
            const SizedBox(height: ManoSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge,
                  ),
                ),
                if (verified) ...[
                  const SizedBox(width: ManoSpacing.xs),
                  Icon(Icons.verified, size: 20, color: context.palette.clay),
                ],
              ],
            ),
            if (rating != null) ...[
              const SizedBox(height: ManoSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: ManoColors.flame,
                  ),
                  const SizedBox(width: ManoSpacing.xs),
                  Text(
                    rating,
                    style: textTheme.bodyMedium?.copyWith(
                      color: context.palette.muted,
                    ),
                  ),
                ],
              ),
            ],
            if (facts.isNotEmpty) ...[
              const SizedBox(height: ManoSpacing.lg),
              for (final fact in facts) _FactRow(fact: fact),
            ],
            if (label != null && onAction != null) ...[
              const SizedBox(height: ManoSpacing.lg),
              ManoPrimaryButton(label: label, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact});

  final ManoProfileFact fact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      key: const Key('profile-fact'),
      padding: const EdgeInsets.symmetric(vertical: ManoSpacing.sm),
      child: Row(
        children: [
          Text(
            fact.label,
            style: textTheme.bodyMedium?.copyWith(color: context.palette.muted),
          ),
          const SizedBox(width: ManoSpacing.md),
          Expanded(
            child: Text(
              fact.value,
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
