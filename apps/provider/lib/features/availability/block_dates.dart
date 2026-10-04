import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Asks for a range of days and an optional reason, then blocks them.
Future<void> blockDates(BuildContext context, WidgetRef ref) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final range = await showDateRangePicker(
    context: context,
    firstDate: today,
    lastDate: DateTime(today.year + 1, today.month, today.day),
    helpText: 'Elige las fechas',
    saveText: 'Siguiente',
    cancelText: 'Cancelar',
    fieldStartLabelText: 'Desde',
    fieldEndLabelText: 'Hasta',
    errorInvalidRangeText: 'Revisa las fechas.',
  );
  if (range == null || !context.mounted) return;

  final reason = await showManoSheet<String>(
    context: context,
    builder: (_) => const _ReasonSheet(),
  );
  if (reason == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final end = range.end;
  // The picker returns the last day itself; the port wants the instant the block ends.
  final result = await ref
      .read(availabilityActionsProvider.notifier)
      .block(
        range.start,
        DateTime(end.year, end.month, end.day + 1),
        reason: reason.isEmpty ? null : reason,
      );
  if (result case Err(:final failure)) {
    messenger.showSnackBar(SnackBar(content: Text(failure.message)));
  }
}

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet();

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ManoPromptSheet(
        title: '¿Por qué no trabajarás?',
        message: 'Es opcional y solo lo ves tú.',
        primaryLabel: 'Bloquear',
        onPrimary: () => Navigator.of(context).pop(_reason.text.trim()),
        onClose: () => Navigator.of(context).pop(),
        child: ManoTextField(
          label: 'Motivo',
          controller: _reason,
          textCapitalization: TextCapitalization.sentences,
        ),
      ),
    );
  }
}
