import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../offline_marketplace_provider.dart';
import '../session_providers.dart';

/// Invite links the app is opened with (App Links, Universal Links).
final inviteLinkSourceProvider = Provider<InviteLinkSource>(
  (ref) => AppLinksInviteLinkSource(),
);

/// The Play install referrer; null off Android.
final installReferrerSourceProvider = Provider<InstallReferrerSource>(
  (ref) => PlayInstallReferrerSource(),
);

// Live with redeemWorkerReferral (mano-profiles via the gateway).
final workerReferralRedeemerProvider = Provider<WorkerReferralRedeemer>(
  (ref) => ref.watch(offlineMarketplaceProvider)
      ? MockWorkerReferralRedeemer()
      : GatewayWorkerReferralRedeemer(ref.watch(gatewayTransportProvider)),
);
