import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A labelled value.
class ManoDetailRow extends StatelessWidget {
  const ManoDetailRow({
    required this.label,
    required this.value,
    this.monospace = false,
    super.key,
  });

  final String label;
  final String value;

  /// For identifiers and tokens, where character shapes matter.
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: ManoSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 13,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A set of short labels, for things like roles.
class ManoTagList extends StatelessWidget {
  const ManoTagList({required this.tags, this.emptyLabel, super.key});

  final List<String> tags;

  /// Shown when [tags] is empty. Omitting it renders nothing at all.
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      final label = emptyLabel;
      return label == null
          ? const SizedBox.shrink()
          : Text(label, style: Theme.of(context).textTheme.bodySmall);
    }

    return Wrap(
      spacing: ManoSpacing.sm,
      runSpacing: ManoSpacing.sm,
      children: [
        for (final tag in tags)
          Chip(label: Text(tag), visualDensity: VisualDensity.compact),
      ],
    );
  }
}
