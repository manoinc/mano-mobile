import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A category in a browse grid: a square photo with its name beside it.
class ManoCategoryTile extends StatelessWidget {
  const ManoCategoryTile({
    required this.image,
    required this.label,
    required this.onTap,
    super.key,
  });

  // The app's own photo; mano_ui ships no images.
  final Widget image;
  final String label;
  final VoidCallback onTap;

  static const double _photo = 64;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ManoRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ManoSpacing.xs),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(ManoRadius.card),
                  child: SizedBox.square(dimension: _photo, child: image),
                ),
                const SizedBox(width: ManoSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: ManoColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
