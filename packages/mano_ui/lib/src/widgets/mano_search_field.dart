import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';

/// The real input behind [ManoSearchPill], drawn as the same sand pill.
class ManoSearchField extends StatelessWidget {
  const ManoSearchField({
    required this.controller,
    this.onChanged,
    this.autofocus = false,
    this.hintText = '¿Qué necesitas hoy?',
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const pill = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(ManoRadius.pill)),
      borderSide: BorderSide.none,
    );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        style: textTheme.bodyMedium?.copyWith(color: context.palette.ink),
        cursorColor: ManoColors.flame,
        decoration: InputDecoration(
          filled: true,
          fillColor: context.palette.sand,
          hintText: hintText,
          hintStyle: textTheme.bodyMedium?.copyWith(
            color: context.palette.faint,
          ),
          prefixIcon: Icon(Icons.search, color: context.palette.faint),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Borrar',
                  icon: Icon(Icons.close, color: context.palette.faint),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ManoSpacing.md,
            vertical: ManoSpacing.md,
          ),
          border: pill,
          enabledBorder: pill,
          focusedBorder: pill,
        ),
      ),
    );
  }
}
