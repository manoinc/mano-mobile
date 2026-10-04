import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

import 'availability_labels.dart';

const _step = 30;
const _day = 24 * 60;

/// Creates or edits one weekly rule; closes itself once the change is saved.
class RuleEditorSheet extends ConsumerStatefulWidget {
  const RuleEditorSheet({this.rule, super.key});

  /// Null for a new rule.
  final AvailabilityRule? rule;

  @override
  ConsumerState<RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends ConsumerState<RuleEditorSheet> {
  late final Set<int> _weekdays = {...?widget.rule?.weekdays};
  late int _start = widget.rule?.startMinutes ?? 8 * 60;
  late int _end = widget.rule == null
      ? 12 * 60
      : widget.rule!.startMinutes + widget.rule!.durationMinutes;
  String? _error;
  bool _busy = false;

  AvailabilityActions get _actions =>
      ref.read(availabilityActionsProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editing = widget.rule != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ManoSpacing.lg,
          ManoSpacing.lg,
          ManoSpacing.lg,
          ManoSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'Editar horario' : 'Nuevo horario',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: ManoSpacing.lg),
            Text('Días', style: theme.textTheme.titleSmall),
            const SizedBox(height: ManoSpacing.sm),
            ManoWeekdayPicker(
              selected: _weekdays,
              onToggle: (day) => setState(() {
                _error = null;
                _weekdays.contains(day)
                    ? _weekdays.remove(day)
                    : _weekdays.add(day);
              }),
            ),
            const SizedBox(height: ManoSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    key: const Key('rule-start'),
                    label: 'Desde',
                    value: _start,
                    options: [for (var m = 0; m < _day; m += _step) m],
                    onChanged: (m) => setState(() {
                      _error = null;
                      _start = m;
                    }),
                  ),
                ),
                const SizedBox(width: ManoSpacing.md),
                Expanded(
                  child: _TimeField(
                    key: const Key('rule-end'),
                    label: 'Hasta',
                    value: _end,
                    options: [for (var m = _step; m <= _day; m += _step) m],
                    onChanged: (m) => setState(() {
                      _error = null;
                      _end = m;
                    }),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: ManoSpacing.md),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: ManoSpacing.lg),
            ManoPrimaryButton(label: 'Guardar', busy: _busy, onPressed: _save),
            if (editing) ...[
              const SizedBox(height: ManoSpacing.sm),
              ManoQuietButton(
                label: 'Eliminar horario',
                busy: _busy,
                onPressed: _delete,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_weekdays.isEmpty) {
      return setState(() => _error = 'Elige al menos un día.');
    }
    if (_end <= _start) {
      return setState(
        () => _error = 'La hora de fin debe ser después del inicio.',
      );
    }
    final rule = AvailabilityRule(
      id: widget.rule?.id,
      weekdays: {..._weekdays},
      startMinutes: _start,
      durationMinutes: _end - _start,
    );
    if (!rule.isValid) {
      return setState(() => _error = 'Revisa los días y las horas.');
    }
    await _run(() => _actions.saveRule(rule));
  }

  Future<void> _delete() => _run(() => _actions.deleteRule(widget.rule!.id!));

  Future<void> _run(Future<Result<Object?, DataFailure>> Function() op) async {
    setState(() => _busy = true);
    final result = await op();
    if (!mounted) return;
    switch (result) {
      case Ok():
        Navigator.of(context).pop();
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure is DataRejected
              ? 'Revisa los días y las horas.'
              : failure.message;
        });
    }
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final String label;
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      borderRadius: BorderRadius.circular(ManoRadius.card),
      items: [
        for (final m in options)
          DropdownMenuItem(value: m, child: Text(minutesLabel(m))),
      ],
      onChanged: (m) {
        if (m != null) onChanged(m);
      },
    );
  }
}
