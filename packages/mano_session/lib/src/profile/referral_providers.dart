import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../offline_marketplace_provider.dart';
import '../session_providers.dart';

// Live on D2 (linkWorkerByReferralCode).
final referralLinkerProvider = Provider<ReferralLinker>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? MockReferralLinker()
      : GatewayReferralLinker(ref.watch(gatewayTransportProvider)),
);
