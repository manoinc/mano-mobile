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
  });

  final String id;
  final String projectId;
  final String projectTitle;
  final Party worker;
  final int amountCop;
  final String? message;
  final QuoteStatus status;
  final DateTime createdAt;

  Quote copyWith({QuoteStatus? status}) => Quote(
    id: id,
    projectId: projectId,
    projectTitle: projectTitle,
    worker: worker,
    amountCop: amountCop,
    message: message,
    status: status ?? this.status,
    createdAt: createdAt,
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
      other.createdAt == createdAt;

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
  );

  @override
  String toString() => 'Quote($id, $amountCop, $status)';
}
