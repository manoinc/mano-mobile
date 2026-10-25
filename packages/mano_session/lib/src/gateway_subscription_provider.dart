import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';

import 'session_notifier.dart';
import 'session_providers.dart';

/// The one `graphql-transport-ws` socket every gateway subscription shares.
final gatewaySubscriptionClientProvider = Provider<SubscriptionClient>((ref) {
  final client = SubscriptionClient(
    ref.watch(manoConfigProvider).gatewaySubscriptionUrl,
    // Asked per connection_init, so a reconnect carries a fresh token.
    accessToken: () => ref.read(sessionProvider.notifier).freshAccessToken(),
  );
  ref.onDispose(client.dispose);
  return client;
});
