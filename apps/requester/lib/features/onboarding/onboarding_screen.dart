import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'widgets/google_mark.dart';
import 'widgets/slide_discovery.dart';
import 'widgets/slide_pricing.dart';
import 'widgets/slide_welcome.dart';

/// The pre-login carousel: three slides, a fixed header, a sticky bottom bar.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({required this.index, super.key});

  final int index;

  static const int slideCount = 3;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pages = PageController(initialPage: widget.index);

  /// Fractional page position, for the parallax. Safe before first layout.
  double _offset = 0;

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: ManoMotion.sheet,
  );

  bool _revealStarted = false;

  @override
  void initState() {
    super.initState();
    _offset = widget.index.toDouble();
    _pages.addListener(_trackOffset);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The rows arrive once, the first time the slide is built.
    if (_revealStarted) return;
    _revealStarted = true;
    if (_still) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
  }

  @override
  void didUpdateWidget(OnboardingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The flow moved the slide from outside -- back() from registration, say.
    if (widget.index != oldWidget.index && _pages.hasClients) {
      final current = (_pages.page ?? _offset).round();
      if (current != widget.index) _animateTo(widget.index);
    }
  }

  @override
  void dispose() {
    _pages.removeListener(_trackOffset);
    _pages.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _trackOffset() {
    if (!_pages.hasClients) return;
    setState(() => _offset = _pages.page ?? _offset);
  }

  void _animateTo(int index) {
    if (_still) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: ManoMotion.normal,
        curve: ManoMotion.entrance,
      );
    }
  }

  bool get _still => MediaQuery.disableAnimationsOf(context);

  OnboardingFlowNotifier get _flow =>
      ref.read(onboardingFlowProvider.notifier);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              index: _offset.round().clamp(0, OnboardingScreen.slideCount - 1),
              onSkip: _flow.skipTour,
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: _flow.showSlide,
                children: [
                  _Parallax(
                    delta: _offset - 0,
                    still: _still,
                    child: AnimatedBuilder(
                      animation: _reveal,
                      builder: (context, _) =>
                          SlideDiscovery(reveal: _reveal.value),
                    ),
                  ),
                  _Parallax(
                    delta: _offset - 1,
                    still: _still,
                    child: const SlidePricing(),
                  ),
                  _Parallax(
                    delta: _offset - 2,
                    still: _still,
                    child: const SlideWelcome(),
                  ),
                ],
              ),
            ),
            _BottomBar(
              index: _offset.round().clamp(0, OnboardingScreen.slideCount - 1),
              onNext: () => _animateTo(
                (_offset.round() + 1).clamp(0, OnboardingScreen.slideCount - 1),
              ),
              onRegister: _flow.startRegistration,
              onSignIn: _flow.startSignIn,
            ),
          ],
        ),
      ),
    );
  }
}

/// Drifts a slide's content against the page, which is what reads as depth.
class _Parallax extends StatelessWidget {
  const _Parallax({
    required this.delta,
    required this.still,
    required this.child,
  });

  final double delta;
  final bool still;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (still) return child;

    final width = MediaQuery.sizeOf(context).width;
    return Opacity(
      opacity: (1 - delta.abs()).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(-delta * width * 0.25, 0),
        child: child,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.index, required this.onSkip});

  final int index;
  final VoidCallback onSkip;

  /// The wordmark's band, plus room for the indicator beneath it.
  static const double _height =
      ManoLockup.inset + ManoLockup.restingHeight + ManoSpacing.lg;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Stack(
        children: [
          // Exactly where ManoOpening flies its own copy. Centre the indicator
          // on this row instead and the two collide on a narrow phone.
          const Positioned(
            left: ManoLockup.inset,
            top: ManoLockup.inset,
            child: ManoWordmark(
              height: ManoLockup.restingHeight,
              color: ManoColors.flame,
            ),
          ),
          Positioned(
            right: ManoSpacing.sm,
            top: ManoLockup.inset + (ManoLockup.restingHeight - 44) / 2,
            child: ManoTextAction(label: 'Omitir', onPressed: onSkip),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: ManoPageIndicator(
                count: OnboardingScreen.slideCount,
                index: index,
              ),
            ),
          ),
        ],
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
  });

  final int index;
  final VoidCallback onNext;
  final VoidCallback onRegister;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ManoSpacing.lg,
        ManoSpacing.md,
        ManoSpacing.lg,
        ManoSpacing.md,
      ),
      child: index < OnboardingScreen.slideCount - 1
          ? ManoPrimaryButton(
              label: index == 0 ? 'Empezar' : 'Siguiente',
              onPressed: onNext,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ManoOutlineButton(
                        label: 'Iniciar sesión',
                        onPressed: onSignIn,
                      ),
                    ),
                    const SizedBox(width: ManoSpacing.sm),
                    Expanded(
                      child: ManoPrimaryButton(
                        label: 'Registrarse',
                        onPressed: onRegister,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ManoSpacing.sm),
                ManoBrandButton(
                  label: 'Continuar con Google',
                  leading: const GoogleMark(),
                  onPressed: onSignIn,
                ),
              ],
            ),
    );
  }
}
