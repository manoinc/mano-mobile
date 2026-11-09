import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// A fixed country pill above a phone-number pill, Airbnb's layout in Mano's stadium shapes.
class ManoPhoneField extends StatelessWidget {
  const ManoPhoneField({
    required this.controller,
    this.countryLabel = 'País o región',
    this.country = 'Colombia (+57)',
    this.label = 'Número de celular',
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String countryLabel;
  final String country;
  final String label;

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

    OutlineInputBorder pill(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(ManoRadius.pill),
      borderSide: BorderSide(color: color, width: width),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ManoSpacing.lg,
            vertical: ManoSpacing.sm,
          ),
          decoration: ShapeDecoration(
            shape: StadiumBorder(
              side: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                countryLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: ManoColors.faint,
                ),
              ),
              Text(country, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: ManoSpacing.sm),
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          enabled: enabled,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          style: theme.textTheme.titleMedium,
          cursorColor: ManoColors.flame,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: theme.textTheme.titleMedium?.copyWith(
              color: ManoColors.faint,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ManoSpacing.lg,
              vertical: ManoSpacing.md,
            ),
            border: pill(scheme.outlineVariant, 1),
            enabledBorder: pill(
              errorText == null ? scheme.outlineVariant : scheme.error,
              1,
            ),
            focusedBorder: pill(
              errorText == null ? ManoColors.flame : scheme.error,
              2,
            ),
            disabledBorder: pill(scheme.outlineVariant, 1),
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: ManoSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ManoSpacing.md),
            child: Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: errorText == null ? ManoColors.faint : scheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
