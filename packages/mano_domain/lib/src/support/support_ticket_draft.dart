/// The four kinds of PQRS Colombian consumer law names.
enum SupportTicketKind { peticion, queja, reclamo, sugerencia }

/// What is wrong with a [SupportTicketDraft]; the screen words it in Spanish.
enum SupportTicketProblem {
  emptySubject,
  subjectTooLong,
  emptyDescription,
  descriptionTooLong,
}

const int supportSubjectMaxLength = 120;
const int supportDescriptionMaxLength = 2000;

/// A support request being written, before it is filed.
final class SupportTicketDraft {
  const SupportTicketDraft({
    this.kind = SupportTicketKind.peticion,
    this.subject = '',
    this.description = '',
  });

  final SupportTicketKind kind;
  final String subject;
  final String description;

  Set<SupportTicketProblem> get problems {
    final subject = this.subject.trim();
    final description = this.description.trim();
    return {
      if (subject.isEmpty) SupportTicketProblem.emptySubject,
      if (subject.length > supportSubjectMaxLength)
        SupportTicketProblem.subjectTooLong,
      if (description.isEmpty) SupportTicketProblem.emptyDescription,
      if (description.length > supportDescriptionMaxLength)
        SupportTicketProblem.descriptionTooLong,
    };
  }

  bool get isValid => problems.isEmpty;

  SupportTicketDraft copyWith({
    SupportTicketKind? kind,
    String? subject,
    String? description,
  }) => SupportTicketDraft(
    kind: kind ?? this.kind,
    subject: subject ?? this.subject,
    description: description ?? this.description,
  );

  @override
  bool operator ==(Object other) =>
      other is SupportTicketDraft &&
      other.kind == kind &&
      other.subject == subject &&
      other.description == description;

  @override
  int get hashCode => Object.hash(kind, subject, description);

  @override
  String toString() => 'SupportTicketDraft($kind, $subject)';
}
