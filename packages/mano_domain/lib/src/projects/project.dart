import 'quote.dart';

enum ProjectStatus { open, awarded, closed, cancelled }

/// A requester's job posted for providers to quote on.
final class Project {
  const Project({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.photoUrls = const [],
    this.budgetCop,
    this.quotes,
  });

  final String id;

  /// Canonical [ServiceCategories] id, or the backend's text when unknown.
  final String category;
  final String title;
  final String description;
  final List<String> photoUrls;
  final int? budgetCop;
  final ProjectStatus status;
  final DateTime createdAt;

  /// The quotes received; null unless the viewer owns the project.
  final List<Quote>? quotes;

  /// Providers may quote only while the project is open.
  bool get acceptsQuotes => status == ProjectStatus.open;

  // Selection, discarding and cancelling stay possible until the project closes.
  bool get _isLive =>
      status == ProjectStatus.open || status == ProjectStatus.awarded;

  bool get canCancel => _isLive;

  /// Selecting swaps out any earlier pick, so only the current one is refused.
  bool canSelect(Quote quote) =>
      _isLive && quote.status != QuoteStatus.selected;

  bool canDiscard(Quote quote) =>
      _isLive && quote.status != QuoteStatus.discarded;

  Project copyWith({ProjectStatus? status, List<Quote>? quotes}) => Project(
    id: id,
    category: category,
    title: title,
    description: description,
    photoUrls: photoUrls,
    budgetCop: budgetCop,
    status: status ?? this.status,
    createdAt: createdAt,
    quotes: quotes ?? this.quotes,
  );

  @override
  bool operator ==(Object other) =>
      other is Project &&
      other.id == id &&
      other.category == category &&
      other.title == title &&
      other.description == description &&
      _sameList(other.photoUrls, photoUrls) &&
      other.budgetCop == budgetCop &&
      other.status == status &&
      other.createdAt == createdAt &&
      _sameNullableList(other.quotes, quotes);

  @override
  int get hashCode => Object.hash(
    id,
    category,
    title,
    description,
    Object.hashAll(photoUrls),
    budgetCop,
    status,
    createdAt,
    quotes == null ? null : Object.hashAll(quotes!),
  );

  @override
  String toString() => 'Project($id, $status)';
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameNullableList<T>(List<T>? a, List<T>? b) =>
    a == null || b == null ? a == b : _sameList(a, b);
