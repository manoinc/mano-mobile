import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';

/// A horizontally-scrollable row of pill toggles, one per status filter.
///
/// `selectedIndex` is handed in by the screen and drives which pill reads as
/// active -- this widget holds no state of its own. Not built on `TabBar` /
/// `TabController`: there is no `PageView` of tab content behind it, just a
/// filter the screen applies to a list it owns.
class ManoProjectFilterTabs extends StatelessWidget {
  const ManoProjectFilterTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Pills run on to the screen edge, so a cut-off one reads as "scroll".
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (index, label) in labels.indexed) ...[
            if (index > 0) const SizedBox(width: ManoSpacing.sm),
            _FilterPill(
              badgeKey: Key('mano-project-filter-tab-$index'),
              label: label,
              selected: index == selectedIndex,
              onTap: () => onSelected(index),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.badgeKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Keys the pill's [Container] (not this widget) so tests can pick out a
  /// specific pill's decoration by index.
  final Key badgeKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ManoRadius.pill),
        onTap: () {
          onTap();
          // A pill half off screen slides fully into view once chosen.
          Scrollable.ensureVisible(
            context,
            duration: ManoMotion.normal,
            curve: ManoMotion.entrance,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        },
        child: Container(
          key: badgeKey,
          padding: const EdgeInsets.symmetric(
            horizontal: ManoSpacing.md,
            vertical: ManoSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? ManoColors.flame : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(ManoRadius.pill),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: selected ? Colors.white : scheme.onSurface),
          ),
        ),
      ),
    );
  }
}
