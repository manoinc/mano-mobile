import 'package:flutter/material.dart';
import 'package:mano_session/mano_session.dart';
import 'package:mano_ui/mano_ui.dart';

/// Shows a request's details; resolves `true` when the user asks to cancel it.
Future<bool?> showRequestSheet(BuildContext context, ServiceRequest request) {
  final when = request.proposedStart;
  final lines = [
    '${request.provider.displayName}'
        '${when == null ? '' : ' · ${ManoFormat.dateTime(when)}'}',
    request.message,
    ?request.rejectionReason,
  ];
  return showManoSheet<bool>(
    context: context,
    builder: (sheetContext) => ManoPromptSheet(
      title: request.serviceTitle,
      message: lines.join('\n\n'),
      primaryLabel: request.canCancel ? 'Cancelar solicitud' : 'Entendido',
      onPrimary: () => Navigator.of(sheetContext).pop(request.canCancel),
      onClose: () => Navigator.of(sheetContext).pop(false),
    ),
  );
}
