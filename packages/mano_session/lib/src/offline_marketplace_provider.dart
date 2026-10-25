import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When true, every marketplace port runs on its in-memory mock.
///
/// The apps never set it: they talk to the gateway. Tests and device test runs
/// override it once to stay hermetic, then override single ports as they need.
final offlineMarketplaceProvider = Provider<bool>((ref) => false);
