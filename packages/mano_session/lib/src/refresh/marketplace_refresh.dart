import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../activity/activity_providers.dart';
import '../availability/availability_providers.dart';
import '../conversation_providers.dart';
import '../marketplace_providers.dart';
import '../projects/project_providers.dart';
import '../services/my_offers_provider.dart';

/// The signed-in user's reads that change on the other side of the marketplace.
final List<ProviderOrFamily> marketplaceReads = [
  myServiceRequestsProvider,
  myJobsProvider,
  jobProvider,
  conversationsProvider,
  myOffersProvider,
  myAvailabilityRulesProvider,
  myCalendarBlocksProvider,
  myCalendarFeedProvider,
  myProjectsProvider,
  openProjectsProvider,
  myQuotesProvider,
];

/// Marks every marketplace read stale; pass `ref.invalidate` from a Ref or a WidgetRef.
void refreshMarketplaceReads(void Function(ProviderOrFamily) invalidate) =>
    marketplaceReads.forEach(invalidate);

/// Refetches the marketplace reads each time the app comes back into view; the app root watches it.
final refreshOnResumeProvider = Provider<void>((ref) {
  final listener = AppLifecycleListener(
    onShow: () => refreshMarketplaceReads(ref.invalidate),
  );
  ref.onDispose(listener.dispose);
});
