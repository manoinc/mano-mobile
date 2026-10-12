import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// One question, one line to answer it.
///
/// The label sits above the rule rather than floating into it, so it stays
/// readable while typing. Everything it knows is a string and a callback;
/// what counts as a valid answer is decided elsewhere.
class ManoTextField extends StatelessWidget {
  const ManoTextField({
    required this.label,
    required this.controller,
    this.errorText,
    this.helperText,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.minLines,
    this.maxLines = 1,
    this.obscureText = false,
    this.autofillHints,
    super.key,
  });

  final String label;
  final TextEditingController controller;

  /// Replaces [helperText] while set.
  final String? errorText;
  final String? helperText;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autofocus;

  /// Supplied by the screen so one field can hand off to the next.
  final FocusNode? focusNode;

  final bool enabled;

  // Set both above 1 for a free-text message.
  final int? minLines;
  final int? maxLines;

  final bool obscureText;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    UnderlineInputBorder rule(Color color, double width) =>
        UnderlineInputBorder(borderSide: BorderSide(color: color, width: width));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(color: ManoColors.faint),
        ),
        const SizedBox(height: ManoSpacing.xs),
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofocus: autofocus,
          focusNode: focusNode,
          enabled: enabled,
          minLines: minLines,
          maxLines: maxLines,
          obscureText: obscureText,
          autofillHints: autofillHints,
          style: theme.textTheme.titleMedium,
          cursorColor: ManoColors.flame,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: ManoSpacing.sm,
            ),
            helperText: helperText,
            helperMaxLines: 2,
            errorText: errorText,
            errorMaxLines: 2,
            helperStyle: theme.textTheme.bodySmall?.copyWith(
              color: ManoColors.faint,
            ),
            errorStyle: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            border: rule(scheme.outlineVariant, 1),
            enabledBorder: rule(scheme.outlineVariant, 1),
            focusedBorder: rule(ManoColors.flame, 2),
            errorBorder: rule(scheme.error, 1),
            focusedErrorBorder: rule(scheme.error, 2),
          ),
        ),
      ],
    );
  }
}
