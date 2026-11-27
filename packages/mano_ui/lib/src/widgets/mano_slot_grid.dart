import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';

/// One time slot as the grid draws it.
class ManoSlot {
  const ManoSlot({required this.label, this.enabled = true});

  final String label;
  final bool enabled;
}

/// A wrap of time-slot chips; taken slots render struck through and inert.
class ManoSlotGrid extends StatelessWidget {
  const ManoSlotGrid({
    required this.slots,
    required this.selectedIndex,
    required this.onSelected,
    this.emptyLabel = '',
    super.key,
  });

  final List<ManoSlot> slots;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: ManoSpacing.lg),
        child: Text(
          emptyLabel,
          style: textTheme.bodyMedium?.copyWith(color: context.palette.faint),
        ),
      );
    }
    return Wrap(
      spacing: ManoSpacing.sm,
      runSpacing: ManoSpacing.sm,
      children: [
        for (var i = 0; i < slots.length; i++)
          _SlotChip(
            slot: slots[i],
            selected: i == selectedIndex,
            onTap: slots[i].enabled ? () => onSelected(i) : null,
          ),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final ManoSlot slot;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? context.palette.paper
        : slot.enabled
        ? Theme.of(context).colorScheme.onSurface
        : context.palette.faint;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ManoMotion.quick,
        curve: ManoMotion.entrance,
        padding: const EdgeInsets.symmetric(
          horizontal: ManoSpacing.md,
          vertical: ManoSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? context.palette.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(ManoRadius.pill),
          border: Border.all(
            color: selected ? context.palette.ink : context.palette.stone,
          ),
        ),
        child: Text(
          slot.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: foreground,
            decoration: slot.enabled ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }
}
