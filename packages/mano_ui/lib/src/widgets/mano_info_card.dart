import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// An outlined card with one reassurance: icon, title, message, and optional links.
class ManoInfoCard extends StatelessWidget {
  const ManoInfoCard({
    required this.icon,
    required this.title,
    required this.message,
    this.messageLinks = const {},
    this.linkLabel,
    this.onLink,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Phrases of [message] underlined and tappable, e.g. the terms.
  final Map<String, VoidCallback> messageLinks;

  /// Shown only with [onLink].
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final link = linkLabel;
    final body = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ManoRadius.card),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ManoSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: ManoColors.clay),
            const SizedBox(width: ManoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: ManoSpacing.xs),
                  _LinkedText(message, links: messageLinks, style: body),
                  if (link != null && onLink != null)
                    TextButton(
                      onPressed: onLink,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: EdgeInsets.zero,
                        foregroundColor: ManoColors.clay,
                      ),
                      child: Text(
                        link,
                        style: _linkStyle(theme.textTheme.labelLarge),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle? _linkStyle(TextStyle? base) => base?.copyWith(
  color: ManoColors.clay,
  fontWeight: FontWeight.w600,
  decoration: TextDecoration.underline,
  decorationColor: ManoColors.clay,
);

/// [text] with each phrase in [links] underlined and tappable.
class _LinkedText extends StatefulWidget {
  const _LinkedText(this.text, {required this.links, this.style});

  final String text;
  final Map<String, VoidCallback> links;
  final TextStyle? style;

  @override
  State<_LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<_LinkedText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final links = widget.links;
    if (links.isEmpty) return Text(widget.text, style: widget.style);
    _disposeRecognizers();
    final pattern = RegExp(links.keys.map(RegExp.escape).join('|'));
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in pattern.allMatches(widget.text)) {
      final phrase = match.group(0)!;
      final recognizer = TapGestureRecognizer()..onTap = links[phrase];
      _recognizers.add(recognizer);
      spans
        ..add(TextSpan(text: widget.text.substring(start, match.start)))
        ..add(
          TextSpan(
            text: phrase,
            style: _linkStyle(widget.style),
            recognizer: recognizer,
          ),
        );
      start = match.end;
    }
    spans.add(TextSpan(text: widget.text.substring(start)));
    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}
