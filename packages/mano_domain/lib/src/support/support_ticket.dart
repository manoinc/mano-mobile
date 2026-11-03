import '../registration/registration_validation.dart';

enum SupportField { subject, description }

const int _subjectMin = 3;
const int _subjectMax = 80;
const int _descriptionMin = 10;
const int _descriptionMax = 2000;

/// A message to support before it is filed (gateway: `SupportTicketInput`).
final class SupportTicketDraft {
  const SupportTicketDraft({required this.subject, required this.description});

  final String subject;
  final String description;

  Map<SupportField, FieldProblem> get problems => {
    SupportField.subject: ?validateLength(
      subject,
      min: _subjectMin,
      max: _subjectMax,
    ),
    SupportField.description: ?validateLength(
      description,
      min: _descriptionMin,
      max: _descriptionMax,
    ),
  };
}

/// A filed request, known to the user by its [ticketNumber] (radicado).
final class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String ticketNumber;
  final String subject;
  final String description;
  final DateTime createdAt;
}
