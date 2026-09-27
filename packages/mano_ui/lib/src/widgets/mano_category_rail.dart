import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_category_chip.dart';

/// One entry in a [ManoCategoryRail].
///
/// A plain local DTO -- not `ServiceCategory`, which `mano_ui` cannot import.
/// The screen that builds a rail maps its domain categories into these
/// itself, including looking up an `IconData` for whatever `iconKey` the
/// domain entity carries.
@immutable
class ManoCategoryRailItem {
  const ManoCategoryRailItem({
    required this.id,
    required this.icon,
    required this.label,
  });

  final String id;
  final IconData icon;
  final String label;
}

/// A horizontal, scrollable row of category chips.
class ManoCategoryRail extends StatelessWidget {
  const ManoCategoryRail({
    required this.items,
    this.selectedId,
    required this.onSelected,
    super.key,
  });

  final List<ManoCategoryRailItem> items;

  /// `null` = nothing selected.
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: ManoSpacing.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          return ManoCategoryChip(
            icon: item.icon,
            label: item.label,
            selected: item.id == selectedId,
            onTap: () => onSelected(item.id),
          );
        },
      ),
    );
  }
}
