import 'package:mano_domain/mano_domain.dart';

/// Which question of the registration form is on screen.
///
/// The account is created on leaving [password], so [address] onward is signed in.
enum RegistrationStep { name, email, password, address, notifications }

/// How a submit is going.
///
/// Four states rather than a pair of booleans, so a screen can draw all four
/// without inferring any of them.
sealed class RegistrationStatus {
  const RegistrationStatus();
}

final class RegistrationIdle extends RegistrationStatus {
  const RegistrationIdle();
}

final class RegistrationSubmitting extends RegistrationStatus {
  const RegistrationSubmitting();
}

final class RegistrationFailed extends RegistrationStatus {
  const RegistrationFailed(this.failure);

  final RegistrationFailure failure;
}

/// Creating the account was refused; the step shows why, inline.
final class RegistrationAccountRejected extends RegistrationStatus {
  const RegistrationAccountRejected(this.failure);

  final AuthFailure failure;
}

/// What somebody who is not signed in is currently doing.
///
/// One sealed type rather than a set of flags, so the root cannot render an
/// impossible combination and a new case breaks the switch rather than the app.
sealed class OnboardingFlow {
  const OnboardingFlow();
}

/// The carousel, on slide [index].
final class OnboardingTour extends OnboardingFlow {
  const OnboardingTour({this.index = 0});

  final int index;
}

/// Signing in to an account that already exists.
final class OnboardingSignIn extends OnboardingFlow {
  const OnboardingSignIn();
}

/// Registering. The draft rides along, so stepping back loses nothing.
final class OnboardingRegistration extends OnboardingFlow {
  const OnboardingRegistration({
    required this.draft,
    this.step = RegistrationStep.name,
    this.email = '',
    this.password = '',
    this.showProblems = false,
    this.status = const RegistrationIdle(),
  });

  final RegistrationDraft draft;
  final RegistrationStep step;

  /// The new account's credentials, kept out of the draft that gets submitted.
  final String email;
  final String password;

  /// Errors appear on the first refused Siguiente, not on the first keystroke.
  final bool showProblems;

  final RegistrationStatus status;

  OnboardingRegistration copyWith({
    RegistrationDraft? draft,
    RegistrationStep? step,
    String? email,
    String? password,
    bool? showProblems,
    RegistrationStatus? status,
  }) => OnboardingRegistration(
    draft: draft ?? this.draft,
    step: step ?? this.step,
    email: email ?? this.email,
    password: password ?? this.password,
    showProblems: showProblems ?? this.showProblems,
    status: status ?? this.status,
  );
}

/// Through the front door, looking around without an account.
final class OnboardingBrowsing extends OnboardingFlow {
  const OnboardingBrowsing({this.showWelcome = false, this.name = ''});

  /// One-shot, cleared once shown -- the same contract as
  /// `SessionNotifier.acknowledgeFailure`.
  final bool showWelcome;

  /// First name typed while registering, kept for the greeting; '' if none.
  final String name;
}
