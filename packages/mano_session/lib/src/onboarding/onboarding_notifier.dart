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

  void acknowledgeWelcome() => state = const OnboardingBrowsing();

  void _browse({bool showWelcome = false}) {
    _session.browseAsGuest();
    state = OnboardingBrowsing(showWelcome: showWelcome);
  }

  void editName({String? givenName, String? familyName}) => _edit(
    (draft) => draft.copyWith(givenName: givenName, familyName: familyName),
  );

  void editAddress(String address) =>
      _edit((draft) => draft.copyWith(address: address));

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
        RegistrationStep.name => const OnboardingTour(index: lastSlide),
        RegistrationStep.address => flow.copyWith(
          step: RegistrationStep.name,
          showProblems: false,
        ),
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

      final result = await _registration.submit(flow.draft);

      // The screen may have moved on while this was in flight.
      if (state case final OnboardingRegistration current) {
        switch (result) {
          case Ok():
            _browse(showWelcome: true);
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
              ? RegistrationStep.address
              : null,
        RegistrationStep.address =>
          validateAddress(flow.draft.address) == null
              ? RegistrationStep.notifications
              : null,
        RegistrationStep.notifications => null,
      };
}

final onboardingFlowProvider =
    NotifierProvider<OnboardingFlowNotifier, OnboardingFlow>(
      OnboardingFlowNotifier.new,
    );
