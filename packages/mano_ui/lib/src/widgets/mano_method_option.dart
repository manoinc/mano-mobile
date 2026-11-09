import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_press_scale.dart';
import 'tag_pill.dart';

/// One way to pay, picked like a radio; null [onTap] shows it disabled.
class ManoMethodOption extends StatelessWidget {
  const ManoMethodOption({
    required this.leading,
    required this.title,
    required this.selected,
    required this.onTap,
    this.detail,
    this.tag,
    super.key,
  });

  /// The method's mark; a third-party logo is an app asset.
  final Widget leading;
  final String title;
  final String? detail;

  /// A small pill after the title, e.g. "Próximamente".
  final String? tag;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onTap != null;
    final on = selected && enabled;
    final ink = enabled ? scheme.onSurface : ManoColors.faint;

    return ManoPressScale(
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ManoRadius.card),
          side: BorderSide(
            color: on ? scheme.onSurface : scheme.outlineVariant,
            width: on ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(ManoSpacing.md),
            child: Row(
              children: [
                IconTheme.merge(
                  data: IconThemeData(color: ink, size: 24),
                  child: Opacity(opacity: enabled ? 1 : 0.5, child: leading),
                ),
                const SizedBox(width: ManoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: ManoSpacing.sm,
                        runSpacing: ManoSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: ink,
                            ),
                          ),
                          if (tag case final tag?) TagPill(tag),
                        ],
                      ),
                      if (detail case final detail?)
                        Text(
                          detail,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ManoColors.faint,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: ManoSpacing.sm),
                Icon(
                  on
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: on ? scheme.onSurface : scheme.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
