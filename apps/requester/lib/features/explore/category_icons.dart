import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

const Map<String, IconData> _categoryIcons = {
  'cleaning': Icons.cleaning_services_outlined,
  'plumbing': Icons.plumbing,
  'electrical': Icons.electrical_services,
  'painting': Icons.format_paint_outlined,
  'gardening': Icons.grass,
};

// Unknown keys fall back to a generic icon so new categories still render.
IconData categoryIcon(String iconKey) =>
    _categoryIcons[iconKey] ?? Icons.build_outlined;

List<ManoCategoryRailItem> categoryRailItems(
  List<ServiceCategory> categories,
) => [
  for (final category in categories)
    ManoCategoryRailItem(
      id: category.id,
      icon: categoryIcon(category.iconKey),
      label: category.label,
    ),
];
