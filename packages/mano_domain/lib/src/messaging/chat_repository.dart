import '../result.dart';
import '../shared/data_failure.dart';
import 'message.dart';

/// One conversation's thread; the list of conversations is [ConversationRepository].
abstract interface class ChatRepository {
  /// Oldest first.
  Future<List<Message>> messages(String conversationId);

  /// Messages that arrive after subscribing, from either side.
  Stream<Message> watch(String conversationId);

  /// [mediaIds] come from a finished `MediaUploader` upload to this conversation.
  Future<Result<Message, DataFailure>> send(
    String conversationId,
    String body, {
    List<String> mediaIds = const [],
  });

  Future<Result<void, DataFailure>> markRead(String conversationId);
}
