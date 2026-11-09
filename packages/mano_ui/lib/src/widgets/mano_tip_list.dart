import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_emphasis_text.dart';

/// One piece of advice; [emphasis] is the part to read first.
class ManoTip {
  const ManoTip(this.text, {this.emphasis});

  final String text;
  final String? emphasis;
}

/// Short bulleted advice in quiet text, each with a bold fragment.
class ManoTipList extends StatelessWidget {
  const ManoTipList({required this.tips, super.key});

  final List<ManoTip> tips;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(color: ManoColors.muted);
    final strong = TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tip in tips)
          Padding(
            padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Text('•  ', style: body)),
                Expanded(
                  child: ManoEmphasisText(
                    tip.text,
                    emphasis: tip.emphasis,
                    style: body,
                    emphasisStyle: strong,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
