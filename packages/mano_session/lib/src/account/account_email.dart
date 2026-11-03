import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session_notifier.dart';

/// The signed-in user's email, or empty; prefills payer and payout holder emails.
final accountEmailProvider = Provider<String>(
  (ref) => ref.watch(currentUserProvider)?.email ?? '',
);
