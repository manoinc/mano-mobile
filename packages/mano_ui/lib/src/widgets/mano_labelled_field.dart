import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A label above an outlined, rounded box: a text input, or a select that opens a picker.
class ManoLabelledField extends StatelessWidget {
  const ManoLabelledField({
    required this.label,
    required TextEditingController this.controller,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    super.key,
  }) : value = null,
       leading = null,
       onTap = null;

  /// The same box showing [value], with a chevron; taps go to [onTap].
  const ManoLabelledField.select({
    required this.label,
    required String this.value,
    required this.onTap,
    this.leading,
    this.helperText,
    this.errorText,
    this.enabled = true,
    super.key,
  }) : controller = null,
       hintText = null,
       keyboardType = null,
       textInputAction = null,
       autofillHints = null,
       onChanged = null,
       onSubmitted = null,
       focusNode = null,
       autofocus = false;

  final String label;
  final TextEditingController? controller;
  final String? value;

  /// Before [value] in a select, e.g. a flag.
  final Widget? leading;
  final VoidCallback? onTap;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  /// Replaced by [errorText] while set.
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final note = errorText ?? helperText;
    final rest = errorText == null ? scheme.outline : scheme.error;

    OutlineInputBorder box(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(ManoRadius.card),
      borderSide: BorderSide(color: color, width: width),
    );

    final decoration = InputDecoration(
      hintText: hintText,
      hintStyle: theme.textTheme.titleMedium?.copyWith(
        color: context.palette.faint,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ManoSpacing.md,
        vertical: ManoSpacing.md,
      ),
      prefixIcon: leading == null
          ? null
          : Padding(
              padding: const EdgeInsetsDirectional.only(
                start: ManoSpacing.md,
                end: ManoSpacing.sm,
              ),
              child: leading,
            ),
      prefixIconConstraints: const BoxConstraints(),
      suffixIcon: onTap == null
          ? null
          : const Icon(Icons.keyboard_arrow_down_rounded),
      border: box(rest, 1),
      enabledBorder: box(rest, 1),
      focusedBorder: box(
        errorText == null ? ManoColors.flame : scheme.error,
        2,
      ),
      disabledBorder: box(scheme.outlineVariant, 1),
    );

    final input = controller == null
        ? InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(ManoRadius.card),
            child: InputDecorator(
              decoration: decoration.copyWith(enabled: enabled),
              child: Text(value!, style: theme.textTheme.titleMedium),
            ),
          )
        : TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            enabled: enabled,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            style: theme.textTheme.titleMedium,
            cursorColor: ManoColors.flame,
            decoration: decoration,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: ManoSpacing.sm),
        input,
        if (note != null) ...[
          const SizedBox(height: ManoSpacing.sm),
          Text(
            note,
            style: theme.textTheme.bodySmall?.copyWith(
              color: errorText == null ? context.palette.faint : scheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
