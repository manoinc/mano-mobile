import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

import 'category_icons.dart';

// Categories with a bundled photo; sources in docs/develop/search.md.
const _photographed = {
  'cleaning',
  'plumbing',
  'electrical',
  'painting',
  'gardening',
};

/// The category's photo, or its icon on stone when there is no photo.
Widget categoryPhoto(String id) {
  final fallback = Builder(
    builder: (context) => ColoredBox(
      color: context.palette.stone,
      child: Icon(categoryIcon(id), color: context.palette.faint),
    ),
  );
  if (!_photographed.contains(id)) return fallback;
  return Image.asset(
    'assets/categories/$id.jpg',
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => fallback,
  );
}
