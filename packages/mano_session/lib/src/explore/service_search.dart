import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../marketplace_providers.dart';

/// What the requester is searching for; blanks mean "no filter".
final class ServiceQuery {
  const ServiceQuery({String? category, String text = ''})
    : _category = category,
      _text = text;

  final String? _category;
  final String _text;

  String? get categoryFilter => _blankToNull(_category);
  String? get searchText => _blankToNull(_text);

  // A function so callers can clear the category, not just change it.
  ServiceQuery copyWith({String? Function()? category, String? text}) =>
      ServiceQuery(
        category: category == null ? _category : category(),
        text: text ?? _text,
      );

  @override
  bool operator ==(Object other) =>
      other is ServiceQuery &&
      other.categoryFilter == categoryFilter &&
      other.searchText == searchText;

  @override
  int get hashCode => Object.hash(categoryFilter, searchText);

  @override
  String toString() => 'ServiceQuery($categoryFilter, $searchText)';
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

// No auto-retry: the screen offers an explicit "Reintentar" instead of a silent spinner.
final serviceSearchProvider = FutureProvider.autoDispose
    .family<List<JobService>, ServiceQuery>(
      (ref, query) => ref
          .watch(serviceCatalogProvider)
          .search(category: query.categoryFilter, text: query.searchText),
      retry: (_, _) => null,
    );
