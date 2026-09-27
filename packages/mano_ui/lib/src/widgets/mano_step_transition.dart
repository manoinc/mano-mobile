import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';

/// Slides one step out and the next in, in the direction of travel.
///
/// Used both between the screens of the signed-out flow and between the steps
/// within it, so every hop moves the same way.
///
/// Deliberately not a nested [Navigator]: the state driving this already lives
/// outside the widgets, and an imperative route stack beside a declarative
/// parent is two answers to "what is on screen". The cost is Android's
/// predictive-back preview, which a two-step form can spare.
class ManoStepTransition extends StatefulWidget {
  const ManoStepTransition({
    required this.index,
    required this.child,
    this.parallax = 0.25,
    super.key,
  });

  /// Position in the flow. A rise is forward, a fall is back.
  final int index;

  /// Must carry a unique [Key]; that is how the switcher tells steps apart.
  final Widget child;

  /// How far the leaving step drifts, as a fraction of the arriving step's
  /// travel. The depth cue.
  final double parallax;

  @override
  State<ManoStepTransition> createState() => _ManoStepTransitionState();
}

class _ManoStepTransitionState extends State<ManoStepTransition> {
  bool _forward = true;

  @override
  void didUpdateWidget(ManoStepTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compared against the old widget rather than a remembered field: a `late`
    // field first read here would initialise from the *new* index and never
    // see a change.
    if (widget.index != oldWidget.index) {
      _forward = widget.index > oldWidget.index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);

    return AnimatedSwitcher(
      duration: still ? Duration.zero : ManoMotion.normal,
      switchInCurve: ManoMotion.entrance,
      switchOutCurve: ManoMotion.exit,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        // The same builder runs backwards for the leaving child, so the offset
        // has to know which of the two it is holding.
        final arriving = child.key == widget.child.key;
        final dx = arriving
            ? (_forward ? 1.0 : -1.0)
            : (_forward ? -widget.parallax : widget.parallax);

        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(dx, 0),
            end: Offset.zero,
          ).animate(animation),
          child: arriving
              ? child
              : FadeTransition(opacity: animation, child: child),
        );
      },
      child: widget.child,
    );
  }
}
