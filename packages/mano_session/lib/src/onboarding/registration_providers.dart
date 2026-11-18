import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../offline_marketplace_provider.dart';
import '../session_providers.dart';

/// Where a finished sign-up draft goes: the profiles service, or nowhere offline.
final registrationRepositoryProvider = Provider<RegistrationRepository>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? const _LocalOnlyRegistration()
      : GatewayRegistrationRepository(ref.watch(gatewayTransportProvider)),
);

/// Offline (mock) builds keep the draft on the device.
final class _LocalOnlyRegistration implements RegistrationRepository {
  const _LocalOnlyRegistration();

  @override
  Future<Result<void, RegistrationFailure>> submit(
    RegistrationDraft draft,
  ) async => const Ok<void, RegistrationFailure>(null);
}
