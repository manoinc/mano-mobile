import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the app waits for a coin purchase to land, and how often it looks.
final class BillingConfig {
  const BillingConfig({
    required this.pollInterval,
    required this.settleTimeout,
  });

  static const standard = BillingConfig(
    pollInterval: Duration(seconds: 3),
    settleTimeout: Duration(minutes: 2),
  );

  final Duration pollInterval;
  final Duration settleTimeout;

  int get maxPolls =>
      settleTimeout.inMilliseconds ~/ pollInterval.inMilliseconds;
}

/// Overridden in tests to keep waits short.
final billingConfigProvider = Provider<BillingConfig>(
  (ref) => BillingConfig.standard,
);
