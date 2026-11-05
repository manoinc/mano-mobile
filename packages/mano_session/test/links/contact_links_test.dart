import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  test('a call dials the number without spaces', () {
    expect(phoneCallUri('300 123 4567'), Uri.parse('tel:3001234567'));
    expect(phoneCallUri('+57 300 123 4567'), Uri.parse('tel:+573001234567'));
  });

  test('WhatsApp opens a chat, adding Colombia\'s code to a local mobile', () {
    expect(
      whatsAppUri('300 123 4567'),
      Uri.parse('https://wa.me/573001234567'),
    );
    expect(
      whatsAppUri('+57 300-123-4567'),
      Uri.parse('https://wa.me/573001234567'),
    );
  });

  test('an email opens the mail app', () {
    expect(
      emailUri('laura@mano.test'),
      Uri.parse('mailto:laura@mano.test'),
    );
  });
}
