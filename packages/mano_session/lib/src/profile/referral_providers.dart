import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

// Mock until STREAM-05 wires linkWorkerByReferralCode.
final referralLinkerProvider = Provider<ReferralLinker>(
  (ref) => MockReferralLinker(),
);
