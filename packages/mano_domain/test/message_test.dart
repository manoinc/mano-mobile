import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Message', () {
    Message make({MessageStatus? status}) => status == null
        ? Message(
            id: 'm',
            conversationId: 'c',
            body: 'Hola',
            sentAt: DateTime(2026, 1, 1),
            fromMe: true,
          )
        : Message(
            id: 'm',
            conversationId: 'c',
            body: 'Hola',
            sentAt: DateTime(2026, 1, 1),
            fromMe: true,
            status: status,
          );

    test('is sent by default', () {
      expect(make().status, MessageStatus.sent);
    });

    test('status takes part in equality', () {
      expect(make(), make(status: MessageStatus.sent));
      expect(make() == make(status: MessageStatus.read), isFalse);
    });

    test('copyWith changes only the status', () {
      final read = make().copyWith(status: MessageStatus.read);
      expect(read.status, MessageStatus.read);
      expect(read.id, 'm');
    });
  });
}
