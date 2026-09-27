import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'address_step_screen.dart';
import 'name_step_screen.dart';
import 'notifications_sheet.dart';

/// The registration form, one step at a time.
///
/// The steps are pages of a [ManoStepTransition] rather than routes: the state
/// they render already lives in the notifier, and an imperative route stack
/// beside a declarative parent is two answers to "what is on screen".
class RegistrationFlowScreen extends ConsumerStatefulWidget {
  const RegistrationFlowScreen({required this.step, super.key});

  final RegistrationStep step;

  @override
  ConsumerState<RegistrationFlowScreen> createState() =>
      _RegistrationFlowScreenState();
}

class _RegistrationFlowScreenState
    extends ConsumerState<RegistrationFlowScreen> {
  bool _sheetOpen = false;

  OnboardingFlowNotifier get _notifier =>
      ref.read(onboardingFlowProvider.notifier);

  /// Raises the notifications sheet, and treats dismissal as a step back.
  Future<void> _askAboutNotifications() async {
    if (_sheetOpen) return;
    _sheetOpen = true;

    final accepted = await showManoSheet<bool>(
      context: context,
      builder: (_) => const NotificationsSheet(),
    );

    if (!mounted) return;
    _sheetOpen = false;

    if (accepted ?? false) {
      await _notifier.submit();
    } else {
      _notifier.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(onboardingFlowProvider, (before, after) {
      final wasAsking = before is OnboardingRegistration &&
          before.step == RegistrationStep.notifications;
      final isAsking = after is OnboardingRegistration &&
          after.step == RegistrationStep.notifications;
      if (!wasAsking && isAsking) unawaited(_askAboutNotifications());
    });

    final flow = ref.watch(onboardingFlowProvider);
    if (flow is! OnboardingRegistration) return const SizedBox.shrink();

    final notice = switch (flow.status) {
      RegistrationFailed(:final failure) => ManoNotice(
        message: _messageFor(failure),
        tone: ManoNoticeTone.warning,
        onDismiss: _notifier.acknowledgeFailure,
      ),
      _ => null,
    };

    return Stack(
      children: [
        ManoStepTransition(
          index: switch (flow.step) {
            RegistrationStep.name => 0,
            // The sheet sits over step 2; the page beneath does not change.
            RegistrationStep.address || RegistrationStep.notifications => 1,
          },
          child: switch (flow.step) {
            RegistrationStep.name => NameStepScreen(
              key: const ValueKey('name'),
              flow: flow,
            ),
            RegistrationStep.address || RegistrationStep.notifications =>
              AddressStepScreen(key: const ValueKey('address'), flow: flow),
          },
        ),
        if (notice != null)
          Positioned(
            left: ManoSpacing.lg,
            right: ManoSpacing.lg,
            bottom: ManoSpacing.xl * 2.5,
            child: notice,
          ),
      ],
    );
  }

  String _messageFor(RegistrationFailure failure) => switch (failure) {
    RegistrationRejected() =>
      'No pudimos completar tu registro. Revisa tus datos e inténtalo de '
          'nuevo.',
    RegistrationUnavailable() =>
      'No pudimos terminar tu registro ahora. Vuelve a intentarlo en un '
          'momento.',
  };
}
