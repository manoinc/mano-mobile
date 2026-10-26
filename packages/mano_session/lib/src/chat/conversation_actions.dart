import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../conversation_providers.dart';

/// Starts chats; an opened conversation joins the inbox and its id is returned.
final class ConversationActions extends Notifier<void> {
  @override
  void build() {}

  Future<Result<String, DataFailure>> open({
    String? withWorkerId,
    String? jobId,
  }) async {
    final result = await ref
        .read(conversationRepositoryProvider)
        .open(withWorkerId: withWorkerId, jobId: jobId);
    if (result.isOk) ref.invalidate(conversationsProvider);
    return result.map((conversation) => conversation.id);
  }
}

final conversationActionsProvider = NotifierProvider<ConversationActions, void>(
  ConversationActions.new,
);
