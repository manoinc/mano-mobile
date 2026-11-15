import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../onboarding_copy.dart';
import '../widgets/google_mark.dart';

/// The front door: both ways in go to the phone screen; Google or Apple below.
class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.read(providerOnboardingProvider.notifier);
    final busy = ref.watch(phoneSignInProvider.select((s) => s.busy));
    final failure = switch (ref.watch(sessionProvider).value) {
      SignedOut(:final lastFailure) => lastFailure,
      _ => null,
    };

    // A failure is shown on the phone screen, which keeps the same sign-in state.
    Future<void> platform(SocialProvider provider) async {
      final phone = ref.read(phoneSignInProvider.notifier);
      final session = await phone.signInWith(provider);
      if (session != null) return onboarding.enter(session);
      if (ref.read(phoneSignInProvider).failure != null) {
        onboarding.startWithPhone();
      }
    }

    return ManoHeroScaffold(
      headline: 'Tu oficio, más cerca de tus clientes.',
      actions: ManoWelcomeActions(
        firstLabel: 'Iniciar sesión',
        onFirst: onboarding.startWithPhone,
        secondLabel: 'Registrarse',
        onSecond: onboarding.startWithPhone,
        busy: busy,
        below: ManoPlatformSignInButton(
          googleMark: const GoogleMark(),
          appleMark: const Icon(Icons.apple, size: 22),
          onGoogle: busy ? null : () => platform(SocialProvider.google),
          onApple: busy ? null : () => platform(SocialProvider.apple),
        ),
      ),
      footnote:
          'Con Mano Profesionales recibes solicitudes de hogares en tu zona. '
          'Verificamos tu identidad antes de que publiques servicios.',
      notice: failure == null
          ? null
          : ManoNotice(
              message: authFailureCopy(failure),
              tone: authFailureTone(failure),
              onDismiss: () =>
                  ref.read(sessionProvider.notifier).acknowledgeFailure(),
            ),
    );
  }
}
