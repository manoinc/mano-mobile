import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_domain/mano_domain.dart';

import '../session_notifier.dart';
import 'onboarding_flow.dart';
import 'registration_providers.dart';

/// Drives everything a signed-out person can do before they have an account.
///
/// A plain [Notifier], not an [AsyncNotifier]: there is nothing to await at
/// startup, and a submit in flight is carried inside the value as
/// [RegistrationSubmitting] rather than as a bare `AsyncLoading` that would
/// blank the screen the root switches on.
///
/// In memory only. It dies with the process, which is exactly what "the
/// carousel shows on every cold start" means this phase.
final class OnboardingFlowNotifier extends Notifier<OnboardingFlow> {
  static const int lastSlide = 2;

  RegistrationRepository get _registration =>
      ref.read(registrationRepositoryProvider);

  SessionManager get _session => ref.read(sessionProvider.notifier);

  @override
  OnboardingFlow build() => const OnboardingTour();

  void showSlide(int index) =>
      state = OnboardingTour(index: index.clamp(0, lastSlide));

  void skipTour() => _browse();

  void startSignIn() {
    _session.leaveGuest();
    state = const OnboardingSignIn();
  }

  void startRegistration() {
    _session.leaveGuest();
    state = const OnboardingRegistration(draft: RegistrationDraft());
  }

  void skipRegistration() => _browse();

  /// Takes a phone or social session; a new account is asked its name before the shell.
  void enter(Session session) {
    if (session.isNewAccount) {
      state = const OnboardingRegistration(
        draft: RegistrationDraft(),
        hasAccount: true,
      );
    }
    _session.adopt(session);
  }

  void acknowledgeWelcome() => state = OnboardingBrowsing(
    name: switch (state) {
      OnboardingBrowsing(:final name) => name,
      _ => '',
    },
  );

  void _browse({bool showWelcome = false, String name = ''}) {
    _session.browseAsGuest();
    state = OnboardingBrowsing(showWelcome: showWelcome, name: name);
  }

  void editName({String? givenName, String? familyName}) => _edit(
    (draft) => draft.copyWith(givenName: givenName, familyName: familyName),
  );

  void editAddress(String address) =>
      _edit((draft) => draft.copyWith(address: address));

  void editEmail(String email) => _editAccount(email: email);

  void editPassword(String password) => _editAccount(password: password);

  /// Signs the new account up from the password step; on success the address is next.
  Future<void> createAccount() async {
    if (state case final OnboardingRegistration flow
        when flow.step == RegistrationStep.password) {
      if (flow.status is RegistrationSubmitting) return;
      if (validatePassword(flow.password) != null) {
        state = flow.copyWith(showProblems: true);
        return;
      }
      state = flow.copyWith(status: const RegistrationSubmitting());

      final failure = await _session.signUp(
        Credentials(email: flow.email, password: flow.password),
      );

      if (state case final OnboardingRegistration current) {
        if (failure == null) {
          state = current.copyWith(
            step: RegistrationStep.address,
            showProblems: false,
            status: const RegistrationIdle(),
          );
          return;
        }
        // Shown on the step itself; the door must not repeat it.
        _session.acknowledgeFailure();
        state = current.copyWith(
          step: failure is EmailAlreadyRegistered
              ? RegistrationStep.email
              : RegistrationStep.password,
          status: RegistrationAccountRejected(failure),
        );
      }
    }
  }

  void _editAccount({String? email, String? password}) {
    if (state case final OnboardingRegistration flow) {
      state = flow.copyWith(
        email: email,
        password: password,
        status: flow.status is RegistrationAccountRejected
            ? const RegistrationIdle()
            : null,
      );
    }
  }

  void setWantsNotifications({required bool value}) =>
      _edit((draft) => draft.copyWith(wantsNotifications: value));

  void setWantsPromotions({required bool value}) =>
      _edit((draft) => draft.copyWith(wantsPromotions: value));

  /// Advances if the step can be answered; otherwise starts showing why not.
  void next() {
    if (state case final OnboardingRegistration flow) {
      final step = _nextAfter(flow);
      state = step == null
          ? flow.copyWith(showProblems: true)
          : flow.copyWith(step: step, showProblems: false);
    }
  }

  /// A step back, or out of the flow entirely at the first one.
  void back() {
    if (state case final OnboardingRegistration flow) {
      state = switch (flow.step) {
        // The account already exists; there is no going back to create it.
        RegistrationStep.name when flow.hasAccount => flow,
        RegistrationStep.name => const OnboardingTour(index: lastSlide),
        RegistrationStep.email => _stepBack(flow, RegistrationStep.name),
        RegistrationStep.password => _stepBack(flow, RegistrationStep.email),
        // The account already exists; there is no going back to create it.
        RegistrationStep.address => flow,
        RegistrationStep.notifications => flow.copyWith(
          step: RegistrationStep.address,
          showProblems: false,
        ),
      };
    } else if (state is OnboardingSignIn) {
      state = const OnboardingTour(index: lastSlide);
    }
  }

  void acknowledgeFailure() {
    if (state case final OnboardingRegistration flow) {
      if (flow.status is RegistrationFailed) {
        state = flow.copyWith(status: const RegistrationIdle());
      }
    }
  }

  Future<void> submit() async {
    if (state case final OnboardingRegistration flow) {
      if (flow.status is RegistrationSubmitting) return;
      state = flow.copyWith(status: const RegistrationSubmitting());

      // A guest has no profile to write to yet; the draft stays on the device.
      final result = ref.read(hasAccountProvider)
          ? await _registration.submit(flow.draft)
          : const Ok<void, RegistrationFailure>(null);

      // The screen may have moved on while this was in flight.
      if (state case final OnboardingRegistration current) {
        switch (result) {
          case Ok():
            _browse(showWelcome: true, name: flow.draft.greetingName);
          case Err(:final failure):
            state = current.copyWith(status: RegistrationFailed(failure));
        }
      }
    }
  }

  void _edit(RegistrationDraft Function(RegistrationDraft) change) {
    if (state case final OnboardingRegistration flow) {
      state = flow.copyWith(draft: change(flow.draft));
    }
  }

  /// The step after this one, or null when this one is not answerable yet.
  RegistrationStep? _nextAfter(OnboardingRegistration flow) =>
      switch (flow.step) {
        RegistrationStep.name =>
          validateGivenName(flow.draft.givenName) == null &&
                  validateFamilyName(flow.draft.familyName) == null
              ? (flow.hasAccount
                    ? RegistrationStep.address
                    : RegistrationStep.email)
              : null,
        RegistrationStep.email =>
          validateEmail(flow.email) == null ? RegistrationStep.password : null,
        // The password step leaves through createAccount, not here.
        RegistrationStep.password => null,
        RegistrationStep.address =>
          validateAddress(flow.draft.address) == null
              ? RegistrationStep.notifications
              : null,
        RegistrationStep.notifications => null,
      };

  static OnboardingRegistration _stepBack(
    OnboardingRegistration flow,
    RegistrationStep to,
  ) => flow.copyWith(
    step: to,
    showProblems: false,
    status: const RegistrationIdle(),
  );
}

final onboardingFlowProvider =
    NotifierProvider<OnboardingFlowNotifier, OnboardingFlow>(
      OnboardingFlowNotifier.new,
    );
