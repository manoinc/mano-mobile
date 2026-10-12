import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';

/// A compact bar chart: one bar and one label per value, the peak in flame.
///
/// Plain boxes, no chart package. Values are already numbers; labelling the
/// amounts is the screen's job.
class ManoBarChart extends StatelessWidget {
  const ManoBarChart({
    required this.labels,
    required this.values,
    this.highlightIndex,
    this.height = 96,
    this.semanticLabel,
    super.key,
  });

  final List<String> labels;
  final List<int> values;

  /// Defaults to the tallest bar.
  final int? highlightIndex;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final max = values.fold(0, (a, b) => b > a ? b : a);
    final peak = highlightIndex ?? (max == 0 ? -1 : values.indexOf(max));
    final still = MediaQuery.disableAnimationsOf(context);
    final labelStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: ManoColors.faint);

    return Semantics(
      label: semanticLabel,
      container: true,
      child: ExcludeSemantics(
        excluding: semanticLabel != null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ManoSpacing.xs,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: height,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: max == 0 ? 0 : values[i] / max),
                            duration: still ? Duration.zero : ManoMotion.sheet,
                            curve: ManoMotion.entrance,
                            builder: (context, fraction, _) => Container(
                              key: Key('mano-bar-$i'),
                              height: 4 + (height - 4) * fraction,
                              decoration: BoxDecoration(
                                color: i == peak
                                    ? ManoColors.flame
                                    : ManoColors.stone,
                                borderRadius: BorderRadius.circular(
                                  ManoRadius.sm,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: ManoSpacing.xs),
                      Text(labels[i], style: labelStyle),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
