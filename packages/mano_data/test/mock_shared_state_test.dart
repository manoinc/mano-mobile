import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'rebooking a job adds the request to the shared request store',
    () async {
      final requests = MockServiceRequestRepository();
      final jobs = MockJobRepository(requests: requests);
      final finished = (await jobs.mine(status: JobStatus.finished)).first;

      final rebooked = (await jobs.rebook(finished.id)).valueOrNull!;

      final pending = await requests.mine(status: ServiceRequestStatus.pending);
      expect(pending.map((r) => r.id), contains(rebooked.id));
    },
  );

  group('chat and conversation list share state', () {
    late MockConversationRepository conversations;
    late MockChatRepository chat;

    setUp(() {
      conversations = MockConversationRepository();
      chat = MockChatRepository(conversations: conversations);
    });

    Future<Conversation> conv(String id) async =>
        (await conversations.conversations()).firstWhere((c) => c.id == id);

    test('markRead clears the unread badge', () async {
      expect((await conv('conv-2')).unreadCount, greaterThan(0));
      await chat.markRead('conv-2');
      expect((await conv('conv-2')).unreadCount, 0);
    });

    test('sending updates the last message', () async {
      await chat.send('conv-1', 'Nos vemos el jueves');
      expect((await conv('conv-1')).lastMessage, 'Nos vemos el jueves');
    });

    test('separate repositories do not leak state between tests', () async {
      final fresh = MockConversationRepository();
      expect(
        (await fresh.conversations())
            .firstWhere((c) => c.id == 'conv-2')
            .unreadCount,
        greaterThan(0),
      );
    });
  });
}
