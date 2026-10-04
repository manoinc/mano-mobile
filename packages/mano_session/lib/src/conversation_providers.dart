import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

/// The composition step that matters: an adapter bound to the domain's port.
final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => MockConversationRepository(),
);

final conversationsProvider = FutureProvider<List<Conversation>>(
  (ref) => ref.watch(conversationRepositoryProvider).conversations(),
);
