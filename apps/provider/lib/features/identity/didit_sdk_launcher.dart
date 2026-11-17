import 'package:didit_sdk_core/sdk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:mano_session/mano_session.dart';

/// [DiditLauncher] over Didit's native SDK, in Spanish.
final class DiditSdkLauncher implements DiditLauncher {
  const DiditSdkLauncher();

  @override
  Future<DiditOutcome> start(String sessionToken) async {
    final result = await DiditSdk.startVerification(
      sessionToken,
      config: const DiditConfig(languageCode: 'es'),
    );
    return switch (result) {
      VerificationCompleted() => DiditOutcome.finished,
      VerificationCancelled() => DiditOutcome.cancelled,
      VerificationFailed(:final error) => _failed(error),
    };
  }

  DiditOutcome _failed(VerificationError error) {
    debugPrint('Didit failed: ${error.type} ${error.message}');
    return DiditOutcome.failed;
  }
}
