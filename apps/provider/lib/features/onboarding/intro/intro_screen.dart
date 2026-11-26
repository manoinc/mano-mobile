import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import '../onboarding_copy.dart';
import 'intro_previews.dart';
import 'intro_slide.dart';

/// Three slides before the welcome; skipping or finishing both land on it.
class IntroScreen extends ConsumerWidget {
  const IntroScreen({super.key});

  static const _previews = [RequestsPreview(), OffersPreview(), TrustPreview()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leave = ref.read(providerOnboardingProvider.notifier).leaveIntro;
    final last = introSlides.length - 1;

    return ManoIntroCarousel(
      count: introSlides.length,
      skipLabel: introSkipLabel,
      onSkip: leave,
      slideBuilder: (context, i, reveal) => IntroSlide(
        title: introSlides[i].title,
        subtitle: introSlides[i].subtitle,
        preview: _previews[i],
      ),
      bottomBarBuilder: (context, i, next) => ManoPrimaryButton(
        label: i == last
            ? introDoneLabel
            : i == 0
            ? introStartLabel
            : introNextLabel,
        onPressed: i == last ? leave : next,
      ),
    );
  }
}
