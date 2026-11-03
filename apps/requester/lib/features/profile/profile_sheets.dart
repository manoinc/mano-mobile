import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';

/// Asks before deleting; true only on "Sí, eliminar".
Future<bool> confirmRemove(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showManoSheet<bool>(
    context: context,
    builder: (sheet) => ManoPromptSheet(
      title: title,
      message: message,
      primaryLabel: 'Sí, eliminar',
      onPrimary: () => Navigator.pop(sheet, true),
      onClose: () => Navigator.pop(sheet, false),
    ),
  );
  return confirmed ?? false;
}

/// A row's choices in a sheet; resolves to the one picked, or null.
Future<T?> chooseAction<T>(
  BuildContext context, {
  required String title,
  required List<(T, String, IconData)> choices,
}) => showManoSheet<T>(
  context: context,
  builder: (sheet) => ManoActionSheet(
    title: title,
    onClose: () => Navigator.pop(sheet),
    actions: [
      for (final (value, label, icon) in choices)
        ManoSheetAction(
          label: label,
          icon: icon,
          onPressed: () => Navigator.pop(sheet, value),
        ),
    ],
  ),
);

/// Shows [message] in a fresh snackbar.
void showProfileMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
