import 'package:flutter/material.dart';

/// One sentence with one fragment set apart, the accent by default.
class ManoEmphasisText extends StatelessWidget {
  const ManoEmphasisText(
    this.text, {
    this.emphasis,
    this.style,
    this.emphasisStyle,
    super.key,
  });

  final String text;

  /// Must appear verbatim in [text]; otherwise the text stays plain.
  final String? emphasis;
  final TextStyle? style;

  /// Merged over [style]; defaults to the theme's primary colour.
  final TextStyle? emphasisStyle;

  @override
  Widget build(BuildContext context) {
    final fragment = emphasis;
    final at = fragment == null || fragment.isEmpty
        ? -1
        : text.indexOf(fragment);
    if (at < 0) return Text(text, style: style);
    final accent =
        emphasisStyle ??
        TextStyle(color: Theme.of(context).colorScheme.primary);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (at > 0) TextSpan(text: text.substring(0, at)),
          TextSpan(text: fragment, style: accent),
          if (at + fragment!.length < text.length)
            TextSpan(text: text.substring(at + fragment.length)),
        ],
      ),
    );
  }
}
