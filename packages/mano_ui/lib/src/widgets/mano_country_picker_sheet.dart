import 'package:flutter/material.dart';

import '../theme/mano_theme.dart';
import 'mano_search_field.dart';

/// One country as the picker draws it.
@immutable
class ManoCountryOption {
  const ManoCountryOption({
    required this.code,
    required this.flag,
    required this.name,
    required this.dialCode,
  });

  final String code;
  final String flag;
  final String name;

  /// With the plus, e.g. `+57`.
  final String dialCode;
}

/// A searchable list of countries with flag, name and dial code; reports the tapped code.
class ManoCountryPickerSheet extends StatefulWidget {
  const ManoCountryPickerSheet({
    required this.countries,
    required this.selectedCode,
    required this.onSelected,
    this.title = 'País o región',
    this.searchHint = 'Busca un país o un código',
    this.emptyLabel = 'Sin resultados',
    this.onClose,
    super.key,
  });

  final List<ManoCountryOption> countries;
  final String selectedCode;
  final ValueChanged<String> onSelected;
  final String title;
  final String searchHint;
  final String emptyLabel;

  /// Shows a close button top-left.
  final VoidCallback? onClose;

  @override
  State<ManoCountryPickerSheet> createState() => _ManoCountryPickerSheetState();
}

class _ManoCountryPickerSheetState extends State<ManoCountryPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Case- and accent-blind, so "mexico" finds México.
  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[áà]'), 'a')
      .replaceAll(RegExp('[éè]'), 'e')
      .replaceAll(RegExp('[íì]'), 'i')
      .replaceAll(RegExp('[óò]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u')
      .replaceAll('ñ', 'n');

  List<ManoCountryOption> get _matches {
    final q = _fold(_query.trim()).replaceAll('+', '');
    if (q.isEmpty) return widget.countries;
    return [
      for (final c in widget.countries)
        if (_fold(c.name).contains(q) || c.dialCode.contains(q)) c,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = _matches;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ManoSpacing.lg,
            ManoSpacing.md,
            ManoSpacing.lg,
            0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.onClose case final onClose?)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton.filledTonal(
                    onPressed: onClose,
                    tooltip: 'Cerrar',
                    style: IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              const SizedBox(height: ManoSpacing.sm),
              Text(widget.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: ManoSpacing.md),
              ManoSearchField(
                controller: _search,
                hintText: widget.searchHint,
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: ManoSpacing.sm),
              Flexible(
                child: matches.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: ManoSpacing.lg,
                        ),
                        child: Text(
                          widget.emptyLabel,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: context.palette.faint,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: matches.length,
                        itemBuilder: (context, i) => _CountryRow(
                          option: matches[i],
                          selected: matches[i].code == widget.selectedCode,
                          onTap: () => widget.onSelected(matches[i].code),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ManoCountryOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ManoRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ManoSpacing.md),
        child: Row(
          children: [
            Text(option.flag, style: theme.textTheme.headlineSmall),
            const SizedBox(width: ManoSpacing.md),
            Expanded(
              child: Text(option.name, style: theme.textTheme.titleMedium),
            ),
            Text(
              option.dialCode,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.palette.muted,
              ),
            ),
            SizedBox(
              width: ManoSpacing.xl,
              child: selected
                  ? const Icon(Icons.check_rounded, color: ManoColors.flame)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
