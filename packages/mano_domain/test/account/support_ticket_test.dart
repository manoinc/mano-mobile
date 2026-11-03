import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('a subject and a described problem are enough', () {
    const draft = SupportTicketDraft(
      subject: 'Cobro doble',
      description: 'Me cobraron dos veces la limpieza del sábado.',
    );
    expect(draft.problems, isEmpty);
  });

  test('blank or thin drafts report each field', () {
    expect(const SupportTicketDraft(subject: '', description: ' ').problems, {
      SupportField.subject: FieldProblem.empty,
      SupportField.description: FieldProblem.empty,
    });
    expect(
      const SupportTicketDraft(subject: 'Ay', description: 'Ayuda').problems,
      {
        SupportField.subject: FieldProblem.tooShort,
        SupportField.description: FieldProblem.tooShort,
      },
    );
    expect(
      SupportTicketDraft(subject: 'x' * 81, description: 'y' * 2001).problems,
      {
        SupportField.subject: FieldProblem.tooLong,
        SupportField.description: FieldProblem.tooLong,
      },
    );
  });
}
