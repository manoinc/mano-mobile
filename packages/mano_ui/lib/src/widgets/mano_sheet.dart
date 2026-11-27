import 'package:flutter/material.dart';

import '../theme/mano_motion.dart';
import '../theme/mano_theme.dart';
import 'tag_pill.dart';

/// One choice in a [ManoActionSheet].
///
/// Carries its own callback rather than an identifier, so the sheet never has
/// to know what the choices mean -- which is the only way it can live in a
/// package that cannot see the domain.
@immutable
class ManoSheetAction {
  const ManoSheetAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.detail,
  });

  final String label;

  /// `null` disables the row, for a method that is not available yet.
  final VoidCallback? onPressed;

  final IconData? icon;

  /// A quiet second line. Use it to say why a row is disabled.
  final String? detail;
}

/// A row in a sheet: something to pick, and somewhere it leads.
///
/// Tall enough to hit without looking, and quiet enough that a list of them
/// reads as a list rather than as a stack of buttons.
class ManoOptionRow extends StatelessWidget {
  const ManoOptionRow({
    required this.label,
    required this.onPressed,
    this.icon,
    this.detail,
    this.destructive = false,
    this.tag,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? detail;

  /// A small pill after the label, e.g. "Predeterminada".
  final String? tag;

  /// Marks a row that undoes or removes something, e.g. "Eliminar cuenta".
  /// Ignored while the row is disabled -- a row nobody can tap stays quiet
  /// regardless of what it would have done.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    final ink = !enabled
        ? context.palette.faint
        : destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(ManoRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ManoSpacing.md),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22, color: ink),
              const SizedBox(width: ManoSpacing.md),
            ],
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
                        label,
                        style: theme.textTheme.titleSmall?.copyWith(color: ink),
                      ),
                      if (tag case final tag?) TagPill(tag),
                    ],
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.palette.faint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: ManoSpacing.sm),
            Icon(
              Icons.chevron_right,
              size: 20,
              // A disabled row's chevron recedes into the divider colour.
              color: enabled
                  ? context.palette.faint
                  : theme.colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled list of choices, raised from the bottom of the screen.
///
/// Dumb, like everything else here: it is handed a title and some actions, and
/// calls them back. Show it with [showManoSheet].
class ManoActionSheet extends StatelessWidget {
  const ManoActionSheet({
    required this.title,
    required this.actions,
    this.onClose,
    this.footnote,
    super.key,
  });

  final String title;
  final List<ManoSheetAction> actions;

  /// `null` hides the close control, for a sheet that must be answered.
  final VoidCallback? onClose;

  /// Fine print under the list -- terms, or why a choice is missing.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ManoSpacing.lg,
          ManoSpacing.md,
          ManoSpacing.lg,
          ManoSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onClose != null)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  iconSize: 22,
                  tooltip: 'Cerrar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                ),
              ),
            const SizedBox(height: ManoSpacing.sm),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: ManoSpacing.md),
            for (final (index, action) in actions.indexed) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
              ManoOptionRow(
                label: action.label,
                icon: action.icon,
                detail: action.detail,
                onPressed: action.onPressed,
              ),
            ],
            if (footnote != null) ...[
              const SizedBox(height: ManoSpacing.md),
              Text(
                footnote!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.palette.faint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Raises a sheet with Mano's shape and timing.
///
/// Dimmed rather than blurred. The ground behind the hero is a flat colour and
/// one very pale motif, so a blur would cost a full-screen filter every frame
/// to change almost nothing.
Future<T?> showManoSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  // Someone who asked for less motion still gets the sheet, just not the climb.
  final still = MediaQuery.disableAnimationsOf(context);
  // Snackbars paint above sheets and would cover their buttons.
  ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();

  return showModalBottomSheet<T>(
    context: context,
    // Keeps every sheet's last action above the system navigation bar.
    builder: (sheet) => SafeArea(top: false, child: builder(sheet)),
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    barrierColor: ManoColors.scrim.withValues(alpha: 0.45),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ManoRadius.lg)),
    ),
    sheetAnimationStyle: AnimationStyle(
      duration: still ? Duration.zero : ManoMotion.sheet,
      curve: ManoMotion.entrance,
      reverseDuration: still ? Duration.zero : ManoMotion.normal,
      reverseCurve: ManoMotion.exit,
    ),
  );
}
