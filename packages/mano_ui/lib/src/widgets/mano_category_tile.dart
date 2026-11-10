import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A category in a browse grid: a square photo with its name beside it.
class ManoCategoryTile extends StatelessWidget {
  const ManoCategoryTile({
    required this.image,
    required this.label,
    required this.onTap,
    super.key,
  });

  // The app's own photo; mano_ui ships no images.
  final Widget image;
  final String label;
  final VoidCallback onTap;

  static const double _photo = 64;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ManoRadius.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ManoSpacing.xs),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(ManoRadius.card),
                  child: SizedBox.square(dimension: _photo, child: image),
                ),
                const SizedBox(width: ManoSpacing.sm),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Text(
                      label,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: _fitLongestWord(
                        label,
                        Theme.of(context).textTheme.labelMedium!
                            .copyWith(color: ManoColors.ink),
                        constraints.maxWidth,
                        MediaQuery.textScalerOf(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [style], shrunk just enough that the longest word of [text] fits [width] unbroken.
TextStyle _fitLongestWord(
  String text,
  TextStyle style,
  double width,
  TextScaler scaler,
) {
  var widest = 0.0;
  for (final word in text.split(RegExp(r'\s+'))) {
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    if (painter.width > widest) widest = painter.width;
    painter.dispose();
  }
  if (widest <= width || width <= 0) return style;
  return style.copyWith(fontSize: style.fontSize! * width / widest * 0.98);
}
