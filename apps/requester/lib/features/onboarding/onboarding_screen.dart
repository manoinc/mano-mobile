import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'widgets/google_mark.dart';
import 'widgets/slide_discovery.dart';
import 'widgets/slide_pricing.dart';
import 'widgets/slide_welcome.dart';

/// The pre-login carousel: three slides, a fixed header, a sticky bottom bar.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({required this.index, super.key});

  final int index;

  static const int slideCount = 3;

  // A failure is shown on the sign-in screen, which keeps the same phone sign-in state.
  Future<void> _platform(
    BuildContext context,
    WidgetRef ref,
    SocialProvider provider,
  ) async {
    final flow = ref.read(onboardingFlowProvider.notifier);
    final phone = ref.read(phoneSignInProvider.notifier);
    final session = await phone.signInWith(provider);
    if (!context.mounted) return;
    if (session != null) return flow.enter(session);
    if (ref.read(phoneSignInProvider).failure != null) flow.startSignIn();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(phoneSignInProvider.select((s) => s.busy));
    final flow = ref.read(onboardingFlowProvider.notifier);
    return ManoIntroCarousel(
      count: slideCount,
      index: index,
      onPageChanged: flow.showSlide,
      onSkip: flow.skipTour,
      slideBuilder: (context, i, reveal) => switch (i) {
        0 => SlideDiscovery(reveal: reveal),
        1 => const SlidePricing(),
        _ => const SlideWelcome(),
      },
      bottomBarBuilder: (context, i, next) => _BottomBar(
        index: i,
        onNext: next,
        onRegister: flow.startSignIn,
        onSignIn: flow.startSignIn,
        onPlatform: busy ? null : (p) => _platform(context, ref, p),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.onNext,
    required this.onRegister,
    required this.onSignIn,
    required this.onPlatform,
  });

  final int index;
  final VoidCallback onNext;
  final VoidCallback onRegister;
  final VoidCallback onSignIn;

  /// Google or Apple; `null` while one is in flight.
  final void Function(SocialProvider)? onPlatform;

  @override
  Widget build(BuildContext context) {
    return index < OnboardingScreen.slideCount - 1
        ? ManoPrimaryButton(
            label: index == 0 ? 'Empezar' : 'Siguiente',
            onPressed: onNext,
          )
        : ManoWelcomeActions(
            firstLabel: 'Iniciar sesión',
            onFirst: onSignIn,
            secondLabel: 'Registrarse',
            onSecond: onRegister,
            below: ManoPlatformSignInButton(
              googleMark: const GoogleMark(),
              appleMark: const Icon(Icons.apple, size: 22),
              onGoogle: onPlatform == null
                  ? null
                  : () => onPlatform!(SocialProvider.google),
              onApple: onPlatform == null
                  ? null
                  : () => onPlatform!(SocialProvider.apple),
            ),
          );
  }
}
