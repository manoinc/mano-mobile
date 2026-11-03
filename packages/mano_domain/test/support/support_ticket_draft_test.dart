import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  const valid = SupportTicketDraft(
    subject: 'Pago pendiente',
    description: 'No he recibido el pago del trabajo del lunes.',
  );

  test('a petición by default', () {
    expect(const SupportTicketDraft().kind, SupportTicketKind.peticion);
    expect(SupportTicketKind.values, hasLength(4));
  });

  test('a subject and a description are required', () {
    expect(valid.isValid, isTrue);
    expect(const SupportTicketDraft().problems, {
      SupportTicketProblem.emptySubject,
      SupportTicketProblem.emptyDescription,
    });
  });

  test('the subject and the description have maximum lengths', () {
    expect(
      valid.copyWith(subject: 'a' * (supportSubjectMaxLength + 1)).problems,
      contains(SupportTicketProblem.subjectTooLong),
    );
    expect(
      valid
          .copyWith(description: 'a' * (supportDescriptionMaxLength + 1))
          .problems,
      contains(SupportTicketProblem.descriptionTooLong),
    );
  });

  test('copyWith changes the kind', () {
    expect(
      valid.copyWith(kind: SupportTicketKind.queja).kind,
      SupportTicketKind.queja,
    );
  });
}
