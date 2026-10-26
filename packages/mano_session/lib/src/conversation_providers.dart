import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import 'offline_marketplace_provider.dart';
import 'session_notifier.dart';
import 'session_providers.dart';

/// The composition step that matters: an adapter bound to the domain's port.
final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? MockConversationRepository()
      : GatewayConversationRepository(
          ref.watch(gatewayTransportProvider),
          // The gateway's profileId is the session subject.
          viewerId: () => ref.read(currentUserProvider)?.subject,
        ),
);

/// Newest activity first, whatever order the adapter returns; empty threads last.
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final all = await ref.watch(conversationRepositoryProvider).conversations();
  return [...all]..sort(Conversation.newestFirst);
});

/// One conversation from the loaded list; `null` until loaded or when unknown.
final conversationProvider = Provider.family<Conversation?, String>(
  (ref, id) => ref
      .watch(conversationsProvider)
      .value
      ?.where((c) => c.id == id)
      .firstOrNull,
);
