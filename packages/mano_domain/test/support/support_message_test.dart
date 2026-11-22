import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('a trimmed non-empty body up to the limit is valid', () {
    expect(isValidSupportMessage('  Hola  '), isTrue);
    expect(isValidSupportMessage('a' * supportMessageMaxLength), isTrue);
  });

  test('blank or too long bodies are not', () {
    expect(isValidSupportMessage('   '), isFalse);
    expect(isValidSupportMessage('a' * (supportMessageMaxLength + 1)), isFalse);
  });

  test('a message is equal by value', () {
    final at = DateTime(2026, 11, 2);
    expect(
      SupportMessage(id: '1', fromStaff: true, body: 'Hola', sentAt: at),
      SupportMessage(id: '1', fromStaff: true, body: 'Hola', sentAt: at),
    );
  });

  test('only a closed ticket refuses replies', () {
    expect(SupportTicketStatus.closed.acceptsMessages, isFalse);
    expect(SupportTicketStatus.resolved.acceptsMessages, isTrue);
  });
}
