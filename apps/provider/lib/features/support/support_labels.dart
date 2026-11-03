import 'package:mano_session/mano_session.dart';

// Support (PQRS) domain -> Spanish (Colombia) copy.

String supportKindLabel(SupportTicketKind kind) => switch (kind) {
  SupportTicketKind.peticion => 'Petición',
  SupportTicketKind.queja => 'Queja',
  SupportTicketKind.reclamo => 'Reclamo',
  SupportTicketKind.sugerencia => 'Sugerencia',
};

String supportStatusLabel(SupportTicketStatus status) => switch (status) {
  SupportTicketStatus.filed => 'Radicada',
};

String? subjectError(Set<SupportTicketProblem> problems) =>
    problems.contains(SupportTicketProblem.subjectTooLong)
    ? 'Máximo $supportSubjectMaxLength caracteres.'
    : null;

String? descriptionError(Set<SupportTicketProblem> problems) =>
    problems.contains(SupportTicketProblem.descriptionTooLong)
    ? 'Máximo $supportDescriptionMaxLength caracteres.'
    : null;
