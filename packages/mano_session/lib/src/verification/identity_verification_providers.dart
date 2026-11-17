import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../session_providers.dart';

/// Didit's native SDK; the provider app overrides it, nothing else needs it.
final diditLauncherProvider = Provider<DiditLauncher>(
  (ref) => throw UnimplementedError('Override diditLauncherProvider'),
);

/// The gateway and Didit once the build signs in for real, else the mock.
final identityVerificationProvider = Provider<IdentityVerificationPort>((ref) {
  final config = ref.watch(manoConfigProvider);
  if (config.authApiDomain == null) {
    return MockIdentityVerification(
      approveOnVerify: config.approveIdentityChecks,
    );
  }
  return GatewayIdentityVerification(
    ref.watch(gatewayTransportProvider),
    launcher: ref.watch(diditLauncherProvider),
  );
});
