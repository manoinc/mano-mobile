import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'features/onboarding/onboarding_screen.dart';
import 'features/registration/registration_flow_screen.dart';
import 'screens/sign_in_screen.dart';
import 'shell/requester_shell.dart';

/// The app, once it has opened.
///
/// Separate from `main.dart` so a test can pump it without the native splash
/// plugin, which has no implementation in the test binding.
class ManoRoot extends ConsumerWidget {
  const ManoRoot({this.onFirstFrame, super.key});

  /// Called on the opening's first frame. `main` uses it to drop the splash.
  final VoidCallback? onFirstFrame;

  /// Whether the opening has already played in this process.
  static bool _opened = false;

  @visibleForTesting
  static void resetOpening() => _opened = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final flow = ref.watch(onboardingFlowProvider);

    // Signing out drops you at the door, not back in the guest lobby.
    ref.listen(sessionProvider, (before, after) {
      if (before?.value is SignedIn && after.value is SignedOut) {
        ref.read(onboardingFlowProvider.notifier).startSignIn();
      }
    });

    return ManoOpening(
      animate: !_opened,
      // A cold start is usually still restoring a session. Until it resolves
      // there is nothing worth opening onto, so the sequence waits.
      ready: state.hasError || state.value != null,
      onFirstFrame: () {
        onFirstFrame?.call();
        _opened = true;
      },
      child: _screen(ref, state, flow),
    );
  }

  /// Session first: being signed in outranks anything the flow remembers.
  Widget _screen(
    WidgetRef ref,
    AsyncValue<SessionState> state,
    OnboardingFlow flow,
  ) {
    // Every failure the app expects is returned as a value, so reaching here
    // is a bug and is reported as one.
    if (state case AsyncError(:final error)) {
      return _Crashed(error: error);
    }

    return switch (state.value) {
      // Registration signs up midway; its last steps still belong to the doorway.
      SignedIn() when flow is OnboardingRegistration => _doorway(
        ref,
        flow,
        null,
      ),
      // Signed in outright skips the doorway; the shell is the destination
      // either way, per [OnboardingBrowsing] below.
      SignedIn() => RequesterShell(
        showWelcome: flow is OnboardingBrowsing && flow.showWelcome,
      ),
      Guest() => RequesterShell(
        key: const ValueKey('guest'),
        showWelcome: flow is OnboardingBrowsing && flow.showWelcome,
      ),
      SignedOut(:final lastFailure) => _doorway(ref, flow, lastFailure),
      // Still restoring; the opening is holding.
      null => const SizedBox.shrink(),
    };
  }

  /// What somebody who is not signed in is looking at.
  Widget _doorway(WidgetRef ref, OnboardingFlow flow, AuthFailure? failure) {
    final atRoot = flow is OnboardingTour || flow is OnboardingBrowsing;

    return PopScope(
      canPop: atRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(onboardingFlowProvider.notifier).back();
      },
      child: ManoStepTransition(
        index: _depth(flow),
        child: switch (flow) {
          OnboardingTour(:final index) => OnboardingScreen(
            key: const ValueKey('tour'),
            index: index,
          ),
          OnboardingSignIn() => SignInScreen(
            key: const ValueKey('signIn'),
            failure: failure,
          ),
          OnboardingRegistration(:final step) => RegistrationFlowScreen(
            key: const ValueKey('register'),
            step: step,
          ),
          OnboardingBrowsing(:final showWelcome) => RequesterShell(
            key: const ValueKey('guest'),
            showWelcome: showWelcome,
          ),
        },
      ),
    );
  }

  /// Direction of travel, so the transition knows which way to slide.
  static int _depth(OnboardingFlow flow) => switch (flow) {
    OnboardingTour() => 0,
    OnboardingSignIn() => 1,
    OnboardingRegistration() => 2,
    OnboardingBrowsing() => 3,
  };
}

class _Crashed extends StatelessWidget {
  const _Crashed({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(ManoSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Algo se rompió.'),
              const SizedBox(height: ManoSpacing.sm),
              Text('$error', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
