import 'package:flutter/widgets.dart';

/// How things move.
///
/// One curve, a handful of durations. Taken from the landing site's stylesheet
/// (`--mano-ease`, and the transitions hung on it) rather than re-picked, for
/// the same reason the palette is: sign-in leaves the app for a browser and
/// comes back, and a different sense of timing on either side of that handoff
/// reads as two different products.
abstract final class ManoMotion {
  /// The entrance curve: `cubic-bezier(0.23, 1, 0.32, 1)`.
  ///
  /// Very fast to begin with and a long settle at the end. Anything arriving on
  /// screen uses it, so the first frame is the one that moves furthest and the
  /// motion has stopped being interesting by the time it stops.
  static const Curve entrance = Cubic(0.23, 1, 0.32, 1);

  /// Leaving, rather than arriving. Entrance played backwards lingers, which
  /// on the way out reads as hesitation.
  static const Curve exit = Curves.easeInCubic;

  /// A field border taking a focus colour, a chevron turning over.
  static const Duration quick = Duration(milliseconds: 160);

  /// A press, a fade, a notice appearing.
  static const Duration normal = Duration(milliseconds: 200);

  /// A sheet climbing into place.
  static const Duration sheet = Duration(milliseconds: 320);

  /// The whole app-open sequence, from the first Flutter frame to the hero
  /// being ready to touch.
  static const Duration opening = Duration(milliseconds: 1150);

  /// What the opening costs when it is not being played in full -- a warm
  /// resume, or coming back from signing out.
  static const Duration openingReplay = Duration(milliseconds: 200);

  /// How much of a staggered reveal one item occupies.
  static const double staggerSpan = 0.5;

  /// The gap between one item starting and the next. Smaller than
  /// [staggerSpan], so items overlap and the group reads as one movement
  /// rather than a queue.
  static const double staggerGap = 0.25;

  /// How far through its own arrival item [index] is, 0 to 1.
  ///
  /// Tuned for three items: the third starts at `2 * staggerGap` and has
  /// exactly [staggerSpan] left to run.
  static double stagger(int index, double progress) {
    final start = index * staggerGap;
    return entrance.transform(
      ((progress - start) / staggerSpan).clamp(0.0, 1.0),
    );
  }
}
