import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'steps/documents_step.dart';
import 'steps/pending_step.dart';
import 'steps/profile_step.dart';
import 'steps/review_step.dart';
import 'steps/welcome_step.dart';

/// A professional's sign-up, one step at a time, ending in pending verification.
class ProfessionalOnboardingScreen extends ConsumerWidget {
  const ProfessionalOnboardingScreen({required this.onFinished, super.key});

  /// Enters the shell; local only until a real auth backend exists.
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerOnboardingProvider);
    final step = state.step;

    return PopScope(
      canPop: step == ProviderOnboardingStep.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(providerOnboardingProvider.notifier).back();
      },
      child: ManoStepTransition(
        index: step.index,
        child: switch (step) {
          ProviderOnboardingStep.welcome => const WelcomeStep(
            key: ValueKey('welcome'),
          ),
          ProviderOnboardingStep.profile => ProfileStep(
            key: const ValueKey('profile'),
            state: state,
          ),
          ProviderOnboardingStep.documents => DocumentsStep(
            key: const ValueKey('documents'),
            state: state,
          ),
          ProviderOnboardingStep.review => ReviewStep(
            key: const ValueKey('review'),
            state: state,
          ),
          ProviderOnboardingStep.pending => PendingStep(
            key: const ValueKey('pending'),
            onExplore: onFinished,
          ),
        },
      ),
    );
  }
}
