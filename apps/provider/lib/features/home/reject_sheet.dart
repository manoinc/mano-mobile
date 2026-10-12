import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// Asks for an optional reason; resolves `null` if dismissed, else the reason (maybe empty).
Future<String?> showRejectSheet(BuildContext context) => showManoSheet<String>(
  context: context,
  builder: (_) => const _RejectSheet(),
);

class _RejectSheet extends StatefulWidget {
  const _RejectSheet();

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keeps the field above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ManoPromptSheet(
        title: '¿Rechazar esta solicitud?',
        message: 'Si quieres, cuéntale al cliente por qué.',
        primaryLabel: 'Rechazar solicitud',
        onPrimary: () => Navigator.of(context).pop(_reason.text.trim()),
        onClose: () => Navigator.of(context).pop(),
        child: ManoTextField(
          label: 'Motivo (opcional)',
          controller: _reason,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
        ),
      ),
    );
  }
}
