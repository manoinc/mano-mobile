/// Where someone's identity check stands.
sealed class IdentityCheckStatus {
  const IdentityCheckStatus();
}

/// Nothing has reached the checker yet, or the person left it unfinished.
final class IdentityCheckNotStarted extends IdentityCheckStatus {
  const IdentityCheckNotStarted();
}

/// Sent; the checker (Didit, then Mano's staff) has not answered yet.
final class IdentityCheckPending extends IdentityCheckStatus {
  const IdentityCheckPending();
}

final class IdentityCheckApproved extends IdentityCheckStatus {
  const IdentityCheckApproved();
}

final class IdentityCheckRejected extends IdentityCheckStatus {
  const IdentityCheckRejected({required this.reason, required this.canRetry});

  /// Shown to the person, so they know what to fix.
  final String reason;

  /// False once the staff's refusal is final or no attempts remain.
  final bool canRetry;
}
