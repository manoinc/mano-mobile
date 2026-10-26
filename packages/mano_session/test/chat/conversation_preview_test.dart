import 'package:flutter_test/flutter_test.dart';
import 'package:mano_session/mano_session.dart';

Conversation _conversation({String lastMessage = ''}) => Conversation(
  id: 'c1',
  participant: const Party(id: 'p1', displayName: '', photoUrl: ''),
  participantRole: ManoRole.provider,
  lastMessage: lastMessage,
);

void main() {
  test('the preview is the last message', () {
    expect(_conversation(lastMessage: 'Hola').preview, 'Hola');
  });

  test('a conversation without messages says so', () {
    expect(_conversation().preview, 'Sin mensajes aún');
  });
}
