/// What can go wrong while registering someone.
///
/// Two cases, for the same reason [AuthFailure] splits them: "we will not take
/// this" and "we could not ask" call for opposite responses from the screen.
sealed class RegistrationFailure {
  const RegistrationFailure();

  /// A short, non-technical description, suitable for showing a user.
  String get message;
}

/// The details were refused.
final class RegistrationRejected extends RegistrationFailure {
  const RegistrationRejected({this.reason});

  /// What the backend said, when it said anything useful. Not for display.
  final String? reason;

  @override
  String get message => 'Those details were not accepted.';

  @override
  String toString() => 'RegistrationRejected(reason: $reason)';
}

/// Registration could not be reached or failed on its own side.
final class RegistrationUnavailable extends RegistrationFailure {
  const RegistrationUnavailable({this.detail});

  /// Operational detail worth logging. Never show this to a user.
  final String? detail;

  @override
  String get message =>
      'We cannot finish signing you up right now. Please try again shortly.';

  @override
  String toString() => 'RegistrationUnavailable(detail: $detail)';
}
