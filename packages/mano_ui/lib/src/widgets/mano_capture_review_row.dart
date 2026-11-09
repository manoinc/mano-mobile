import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_text_action.dart';

/// A photo just taken, its name, and a way to take it again.
class ManoCaptureReviewRow extends StatelessWidget {
  const ManoCaptureReviewRow({
    required this.image,
    required this.label,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  /// The thumbnail, given an 80 × 56 box; pass an image with BoxFit.cover.
  final Widget image;
  final String label;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ManoSpacing.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ManoRadius.card),
            child: ColoredBox(
              color: ManoColors.stone,
              child: SizedBox(width: 80, height: 56, child: image),
            ),
          ),
          const SizedBox(width: ManoSpacing.md),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          ManoTextAction(label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}
