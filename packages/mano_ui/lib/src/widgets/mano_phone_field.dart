import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_labelled_field.dart';

/// A labelled country select above a labelled phone box, Wise's layout.
class ManoPhoneField extends StatelessWidget {
  const ManoPhoneField({
    required this.controller,
    this.countryLabel = 'País o región',
    this.country = 'Colombia (+57)',
    this.countryFlag,
    this.onCountryTap,
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

  /// Name and dial code, e.g. `Colombia (+57)`.
  final String country;

  /// A flag emoji before the country.
  final String? countryFlag;

  /// Opens the country picker; `null` keeps the select still.
  final VoidCallback? onCountryTap;
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
    final flag = countryFlag;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ManoLabelledField.select(
          label: countryLabel,
          value: country,
          leading: flag == null
              ? null
              : Text(flag, style: Theme.of(context).textTheme.titleMedium),
          onTap: onCountryTap,
          enabled: enabled && onCountryTap != null,
        ),
        const SizedBox(height: ManoSpacing.md),
        ManoLabelledField(
          label: label,
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          enabled: enabled,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          helperText: helperText,
          errorText: errorText,
        ),
      ],
    );
  }
}
