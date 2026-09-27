import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// One category, shown as an icon in a round chip with a label below.
///
/// `selected` is a fact handed in by the screen (which category is active),
/// not state this widget tracks itself.
class ManoCategoryChip extends StatelessWidget {
  const ManoCategoryChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? ManoColors.flame : ManoColors.faint;
    final background = selected
        ? ManoColors.flame.withValues(alpha: 0.12)
        : ManoColors.stone;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ManoRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ManoSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: foreground),
              ),
              const SizedBox(height: ManoSpacing.xs),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
