import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../offline_marketplace_provider.dart';
import '../session_providers.dart';

final supportDeskProvider = Provider<SupportDesk>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? MockSupportDesk()
      : GatewaySupportDesk(ref.watch(gatewayTransportProvider)),
);

/// My tickets, newest first; invalidate to refresh.
final myTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>(
  (ref) async => _unwrap(await ref.watch(supportDeskProvider).myTickets()),
);

/// One ticket's thread, oldest first; invalidate to fetch new replies.
final supportThreadProvider = FutureProvider.autoDispose
    .family<List<SupportMessage>, String>(
      (ref, ticketId) async =>
          _unwrap(await ref.watch(supportDeskProvider).messages(ticketId)),
    );

T _unwrap<T>(Result<T, DataFailure> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => throw StateError(failure.message),
};
