import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

import '../session_providers.dart';

// Mock until a vendor adapter (Didit or Tusdatos.co) or gateway D10 exists.
final identityVerificationProvider = Provider<IdentityVerificationPort>(
  (ref) => MockIdentityVerification(
    approveOnFinish: ref.watch(manoConfigProvider).approveIdentityChecks,
  ),
);
