import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../marketplace_providers.dart';

/// What the requester is searching for; blanks mean "no filter".
final class ServiceQuery {
  const ServiceQuery({this.category, this.text = ''});

  final String? category;
  final String text;

  String? get categoryFilter => _blankToNull(category);
  String? get searchText => _blankToNull(text);

  // A function so callers can clear the category, not just change it.
  ServiceQuery copyWith({String? Function()? category, String? text}) =>
      ServiceQuery(
        category: category == null ? this.category : category(),
        text: text ?? this.text,
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
