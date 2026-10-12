import 'service_category.dart';

/// The canonical category ids every layer agrees on; the gateway stores them as free text.
abstract final class ServiceCategories {
  static const cleaning = 'cleaning';
  static const plumbing = 'plumbing';
  static const electrical = 'electrical';
  static const painting = 'painting';
  static const gardening = 'gardening';

  static const all = <ServiceCategory>[
    ServiceCategory(id: cleaning, label: 'Limpieza', iconKey: cleaning),
    ServiceCategory(id: plumbing, label: 'Plomería', iconKey: plumbing),
    ServiceCategory(id: electrical, label: 'Electricidad', iconKey: electrical),
    ServiceCategory(id: painting, label: 'Pintura', iconKey: painting),
    ServiceCategory(id: gardening, label: 'Jardinería', iconKey: gardening),
  ];

  // Spellings seen in backend data, folded to lower case without accents.
  static const _aliases = {
    'limpieza': cleaning,
    'plomeria': plumbing,
    'electricidad': electrical,
    'electric': electrical,
    'pintura': painting,
    'jardineria': gardening,
  };

  /// The canonical id for [raw], or [raw] trimmed when it is not one we know.
  static String normalize(String raw) {
    final trimmed = raw.trim();
    final folded = _fold(trimmed);
    for (final category in all) {
      if (category.id == folded) return category.id;
    }
    return _aliases[folded] ?? trimmed;
  }

  /// The Spanish label for [category], or its raw text when unknown.
  static String labelOf(String category) {
    final id = normalize(category);
    for (final known in all) {
      if (known.id == id) return known.label;
    }
    return id;
  }

  static String _fold(String text) => text
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
}
