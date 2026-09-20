import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';
import 'mano_logo_paths.g.dart';
import 'mano_wordmark.dart';

/// Where the wordmark sits once a screen has opened.
///
/// Shared by [ManoOpening] and the hero it opens into, because the whole effect
/// depends on the travelling lockup landing exactly where the hero draws its
/// own. Two copies of these numbers would drift and the handover would jump.
abstract final class ManoLockup {
  /// The wordmark's height at rest, in a screen's top-left corner.
  static const double restingHeight = 30;

  /// Its height while the app is opening, before anything has to fit.
  ///
  /// Measured against the native splash rather than chosen: Android draws the
  /// monogram at this height on a 450dpi device, so the `m` does not change
  /// size at the handover.
  static const double preferredOpeningHeight = 64;

  /// The opening height that also leaves the finished word on the screen.
  ///
  /// At the preferred height the lockup is a shade over 320px wide, so the
  /// narrowest phones would clip the `o`. They give up a little of the splash
  /// match to keep the word whole, which is the right way round: the match is
  /// a detail, and a cut-off logo is not.
  ///
  /// Clamped at zero because Flutter's very first frame can arrive before the
  /// surface has a size. At `availableWidth == 0` the inset alone makes the
  /// fitted height negative, and a negative height is an assertion rather than
  /// a small logo.
  static double openingHeightFor(double availableWidth) => math.max(
    0,
    math.min(
      preferredOpeningHeight,
      (availableWidth - 2 * inset) / kManoWordmarkSize.aspectRatio,
    ),
  );

  /// Its inset from the leading and top edges of the safe area.
  static const double inset = ManoSpacing.lg;
}

/// The app opening.
///
/// Draws the `m` where the native splash left it, brings the rest of the word
/// in, then carries the lockup up to the corner as [child] fades in beneath.
/// By the end the travelling wordmark is exactly on top of the one the hero
/// draws for itself, so the swap is invisible.
///
/// Three things it deliberately does not do:
///
///   - It does not fade the `m` in. The native splash has been showing it; this
///     is a continuation, not a second entrance.
///   - It does not cut short when [ready] arrives early. A logo that flashes
///     past is worse than one that reads.
///   - It does not run on every launch. Pass `animate: false` on a warm resume
///     or after signing out; the sequence is a greeting, and a greeting
///     repeated every time someone switches back to the app is an obstacle.
class ManoOpening extends StatefulWidget {
  const ManoOpening({
    required this.child,
    this.animate = true,
    this.ready = true,
    this.onFirstFrame,
    super.key,
  });

  /// Revealed once the sequence has run and [ready] is true.
  final Widget child;

  /// Whether to play the full sequence.
  final bool animate;

  /// Whether [child] is worth showing yet -- a cold start is usually still
  /// restoring a session. False holds on the finished lockup rather than
  /// handing over to a half-built screen.
  final bool ready;

  /// Fired after the first frame is on screen. This is where the native splash
  /// gets taken down: doing it any earlier shows a blank window between the two.
  final VoidCallback? onFirstFrame;

  /// The `m` alone, holding the native splash's final frame long enough that
  /// the two reliably overlap.
  static const double _holdUntil = 0.2;

  /// The letters arriving.
  static const double _lettersUntil = 0.62;

  /// The lockup travelling to the corner. Also where the sequence waits, if the
  /// session is still being restored.
  static const double _travelFrom = _lettersUntil;

  /// When [child] starts fading up -- a little after the lockup sets off, so it
  /// arrives as a background rather than a competing entrance.
  static const double _childFrom = 0.72;

  @override
  State<ManoOpening> createState() => _ManoOpeningState();
}

class _ManoOpeningState extends State<ManoOpening>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ManoMotion.opening,
  );

  bool _started = false;

  static Duration _slice(double fraction) => ManoMotion.opening * fraction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onFirstFrame?.call();
      _start();
    });
  }

  void _start() {
    if (_started) return;
    _started = true;

    // Someone who has asked for less motion still needs the screen, just not
    // the performance.
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }

    _controller
        .animateTo(
          ManoOpening._travelFrom,
          duration: _slice(ManoOpening._travelFrom),
          curve: Curves.linear,
        )
        .then((_) => _travel());
  }

  /// The second half only starts once there is something to open into.
  void _travel() {
    if (!mounted || !widget.ready || _controller.value >= 1) return;
    _controller.animateTo(
      1,
      duration: _slice(1 - ManoOpening._travelFrom),
      curve: Curves.linear,
    );
  }

  @override
  void didUpdateWidget(ManoOpening old) {
    super.didUpdateWidget(old);
    if (widget.ready && !old.ready) _travel();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surface,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          if (t >= 1 && widget.ready) return widget.child;

          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: _span(t, ManoOpening._childFrom, 1),
                child: widget.child,
              ),
              _TravellingLockup(
                letters: _span(t, ManoOpening._holdUntil, ManoOpening._lettersUntil),
                travel: ManoMotion.entrance
                    .transform(_span(t, ManoOpening._travelFrom, 1)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// How far [value] has moved through the window [from]..[to], clamped.
double _span(double value, double from, double to) =>
    ((value - from) / (to - from)).clamp(0.0, 1.0);

class _TravellingLockup extends StatelessWidget {
  const _TravellingLockup({required this.letters, required this.travel});

  /// How much of the word has arrived.
  final double letters;

  /// How far along the journey to the corner.
  final double travel;

  /// Where the `m`'s middle falls across the lockup, as a fraction of its
  /// width. The native splash centres the `m`; a finished lockup centres the
  /// whole word. Holding the first and easing to the second is what keeps the
  /// mark still while the letters grow out to the right of it.
  static double get _mCentre {
    final (left, right) = kManoWordmarkGlyphExtents.first;
    return (left + right) / 2 / kManoWordmarkSize.width;
  }

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.paddingOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Nothing to place yet, and no lockup small enough to be worth drawing.
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        final height = _lerp(
          ManoLockup.openingHeightFor(constraints.maxWidth),
          ManoLockup.restingHeight,
          travel,
        );
        final width = height * kManoWordmarkSize.aspectRatio;

        final anchor = _lerp(_mCentre, 0.5, letters);
        final left = _lerp(
          constraints.maxWidth / 2 - anchor * width,
          ManoLockup.inset,
          travel,
        );
        final top = _lerp(
          (constraints.maxHeight - height) / 2,
          safeArea.top + ManoLockup.inset,
          travel,
        );

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: ManoWordmark(
                progress: letters,
                height: height,
                color: ManoColors.flame,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// `dart:ui` has one of these, but it is nullable in and nullable out, which
/// costs a `!` at every call site here for no benefit.
double _lerp(double a, double b, double t) => a + (b - a) * t;
