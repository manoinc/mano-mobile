import 'identity_document_kind.dart';

/// Where someone's identity check stands.
sealed class IdentityCheckStatus {
  const IdentityCheckStatus();
}

/// Documents are being collected; nothing has been sent for review yet.
final class IdentityCheckInProgress extends IdentityCheckStatus {
  const IdentityCheckInProgress({required this.submitted});

  final Set<IdentityDocumentKind> submitted;

  Set<IdentityDocumentKind> get missing =>
      IdentityDocumentKind.values.toSet().difference(submitted);

  bool get isComplete => missing.isEmpty;
}

/// Sent; the checker (Didit, Tusdatos.co, a person) has not answered yet.
final class IdentityCheckPending extends IdentityCheckStatus {
  const IdentityCheckPending();
}

final class IdentityCheckApproved extends IdentityCheckStatus {
  const IdentityCheckApproved();
}

final class IdentityCheckRejected extends IdentityCheckStatus {
  const IdentityCheckRejected({required this.reason});

  /// Shown to the person, so they know what to fix.
  final String reason;

  bool get canRetry => true;
}
