import '../result.dart';
import '../shared/data_failure.dart';
import 'conversation.dart';

abstract interface class ConversationRepository {
  Future<List<Conversation>> conversations();

  /// Finds or creates the chat with [withWorkerId] or about [jobId]; give exactly one.
  Future<Result<Conversation, DataFailure>> open({
    String? withWorkerId,
    String? jobId,
  });
}
