import '../shared/party.dart';

enum QuoteStatus { submitted, selected, discarded }

/// A provider's price for a [Project], as the owner or its author sees it.
final class Quote {
  const Quote({
    required this.id,
    required this.projectId,
    required this.projectTitle,
    required this.worker,
    required this.amountCop,
    required this.status,
    required this.createdAt,
    this.message,
    this.leadPurchased = false,
    this.projectCategory = '',
  });

  final String id;
  final String projectId;
  final String projectTitle;
  final Party worker;
  final int amountCop;
  final String? message;
  final QuoteStatus status;
  final DateTime createdAt;

  /// Its worker bought the lead and sees the requester's contact.
  final bool leadPurchased;

  /// The project's canonical category; empty when the reader did not ask for it.
  final String projectCategory;

  Quote copyWith({
    QuoteStatus? status,
    bool? leadPurchased,
    String? projectCategory,
  }) => Quote(
    id: id,
    projectId: projectId,
    projectTitle: projectTitle,
    worker: worker,
    amountCop: amountCop,
    message: message,
    status: status ?? this.status,
    createdAt: createdAt,
    leadPurchased: leadPurchased ?? this.leadPurchased,
    projectCategory: projectCategory ?? this.projectCategory,
  );

  @override
  bool operator ==(Object other) =>
      other is Quote &&
      other.id == id &&
      other.projectId == projectId &&
      other.projectTitle == projectTitle &&
      other.worker == worker &&
      other.amountCop == amountCop &&
      other.message == message &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.leadPurchased == leadPurchased &&
      other.projectCategory == projectCategory;

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    projectTitle,
    worker,
    amountCop,
    message,
    status,
    createdAt,
    leadPurchased,
    projectCategory,
  );

  @override
  String toString() => 'Quote($id, $amountCop, $status)';
}
