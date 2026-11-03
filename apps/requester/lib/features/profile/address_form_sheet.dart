import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'profile_copy.dart';

/// Opens the address form; resolves to the filled-in address, or null.
Future<SavedAddress?> showAddressForm(
  BuildContext context, {
  SavedAddress? initial,
}) => showManoSheet<SavedAddress>(
  context: context,
  builder: (_) => AddressFormSheet(initial: initial),
);

/// New or edited address: name, line, neighborhood, city and directions.
class AddressFormSheet extends StatefulWidget {
  const AddressFormSheet({this.initial, super.key});

  final SavedAddress? initial;

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  late final SavedAddress _start =
      widget.initial ?? const SavedAddress(label: '', line: '');
  late final _label = TextEditingController(text: _start.label);
  late final _line = TextEditingController(text: _start.line);
  late final _neighborhood = TextEditingController(text: _start.neighborhood);
  late final _city = TextEditingController(text: _start.city);
  late final _notes = TextEditingController(text: _start.notes);
  Map<AddressField, FieldProblem> _problems = const {};

  @override
  void dispose() {
    for (final c in [_label, _line, _neighborhood, _city, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  SavedAddress get _draft => _start.copyWith(
    label: _label.text.trim(),
    line: _line.text.trim(),
    neighborhood: _neighborhood.text.trim(),
    city: _city.text.trim(),
    notes: _notes.text.trim(),
  );

  String? _error(AddressField field, String name) => switch (_problems[field]) {
    final FieldProblem p => problemCopy(p, field: name),
    _ => null,
  };

  void _save() {
    final draft = _draft;
    if (draft.problems.isEmpty) {
      Navigator.pop(context, draft);
    } else {
      setState(() => _problems = draft.problems);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gap = SizedBox(height: ManoSpacing.md);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ManoSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.initial == null ? 'Nueva dirección' : 'Editar dirección',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: ManoSpacing.lg),
              ManoTextField(
                label: 'Nombre',
                helperText: 'Casa, Trabajo, Donde mi mamá…',
                controller: _label,
                errorText: _error(AddressField.label, 'un nombre'),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
              ),
              gap,
              ManoTextField(
                label: 'Dirección',
                helperText: 'Calle 45 # 12-30',
                controller: _line,
                errorText: _error(AddressField.line, 'tu dirección'),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.streetAddressLine1],
              ),
              gap,
              ManoTextField(
                label: 'Barrio',
                controller: _neighborhood,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              gap,
              ManoTextField(
                label: 'Ciudad',
                controller: _city,
                errorText: _error(AddressField.city, 'tu ciudad'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              gap,
              ManoTextField(
                label: 'Indicaciones',
                helperText: 'Torre, apartamento, portería.',
                controller: _notes,
                errorText: _error(AddressField.notes, 'las indicaciones'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: ManoSpacing.xl),
              ManoPrimaryButton(label: 'Guardar', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
